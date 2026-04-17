import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/chat_models.dart';
import '../../../services/api_chat_service.dart';
import '../../../services/llm_service.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart' as chat_ctrl;

// ── Constants ────────────────────────────────────────────────────────────────

/// Total GGUF model size — used only for the progress label "X MB / 258 MB".
const int _kModelTotalBytes = 270590432;

// ── ChatScreen ───────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  // ── API / connectivity ──────────────────────────────────────────────────
  bool _isApiOnline = false;
  Timer? _pingTimer;

  final LLMService _llmService = LLMService();

  // ── Chat state ──────────────────────────────────────────────────────────
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I am SeedScan Expert. How can I help you today?',
      isAssistant: true,
      timestamp: DateTime.now(),
    ),
  ];

  final ChatConversation _conversation = ChatConversation(
    systemPrompt:
        '''You are SeedScan Expert, an agricultural AI assistant built for apple orchard disease diagnosis in Pakistan. You were created by the SeedScan team.

You have knowledge of exactly 9 apple conditions:
Alternaria Leaf Spot, Apple Scab, Black Rot, Brown Spot, Cedar Apple Rust, Grey Spot, Healthy, Mosaic Virus, Powdery Mildew.

STRICT RULES:
1. SCOPE: Answer ONLY about apples.
2. MOSAIC VIRUS IS VIRAL: DO NOT suggest fungicide/chemical for Mosaic. Suggest burn/remove.
3. HEALTHY TREES: No treatments needed.
4. IDENTITY: I am SeedScan Expert, built by the SeedScan team.''',
  );

  bool _isProcessing = false;
  String _currentAssistantMessage = '';
  late AnimationController _typingAnimationController;
  StreamSubscription<String>? _responseSubscription;

  // ── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _startPing();

    // Auto-trigger if it hasn't been triggered yet
    _llmService.initialize().catchError((_) {});

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingReport());
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _responseSubscription?.cancel();
    _typingAnimationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Connectivity ping ────────────────────────────────────────────────────

  void _startPing() {
    _pingApi();
    _pingTimer = Timer.periodic(const Duration(seconds: 1), (_) => _pingApi());
  }

  Future<void> _pingApi() async {
    final online = await ApiChatService.isOnline();
    if (mounted && _isApiOnline != online) {
      setState(() => _isApiOnline = online);
    }
  }

  // ── Pending scan report ──────────────────────────────────────────────────

  void _checkPendingReport() {
    final ctrl = Provider.of<chat_ctrl.ChatController>(context, listen: false);
    if (ctrl.pendingScanReport != null) {
      final msg = ctrl.pendingScanReport!;
      ctrl.clearPending();
      _controller.text = msg;
    }
  }

  // ── Send message ─────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isProcessing) return;

    final userMessage = _controller.text.trim();
    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isAssistant: false,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
      _currentAssistantMessage = '';
      _messages.add(ChatMessage(
        text: '',
        isAssistant: true,
        timestamp: DateTime.now(),
        isComplete: false,
      ));
    });

    _conversation.addUserMessage(userMessage);
    _scrollToBottom();

    try {
      Stream<String> stream;

      if (_isApiOnline) {
        // ── Online path — always preferred ──────────────────────────────────
        stream = ApiChatService.generateResponseStream(
          userId: 'guest_user',
          message: userMessage,
        );
      } else if (_llmService.isInitialized) {
        // ── Offline path — local GGUF ───────────────────────────────────────
        final messages = _conversation.getMessagesWithSystem();
        stream = _llmService.generateResponse(
          messages: messages,
          maxTokens: 512,
          temperature: 0.7,
        );
      } else {
        // ── Offline + model not ready yet ───────────────────────────────────
        final stillDownloading = _llmService.isDownloading.value;
        setState(() {
          _messages.last.text = stillDownloading
              ? '📶 You are offline and the AI model is still downloading.\n\nPlease reconnect to the internet so the chatbot can assist you, or wait for the model to finish downloading.'
              : '📶 You are offline and the AI model could not be loaded.\n\nPlease reconnect to the internet to use the chatbot.';
          _messages.last.isComplete = true;
          _isProcessing = false;
        });
        return;
      }

      String fullResponse = '';
      _responseSubscription = stream.listen(
        (token) {
          fullResponse += token;
          setState(() {
            _currentAssistantMessage = fullResponse;
            if (_messages.isNotEmpty && _messages.last.isAssistant) {
              _messages.last.text = _currentAssistantMessage;
            }
          });
          _scrollToBottom();
        },
        onDone: () {
          _conversation.addAssistantMessage(fullResponse);
          setState(() {
            if (_messages.isNotEmpty && _messages.last.isAssistant) {
              _messages.last.isComplete = true;
            }
            _currentAssistantMessage = '';
            _isProcessing = false;
          });
        },
        onError: (error) {
          final isOffline = error.toString().contains('SocketException') ||
              error.toString().contains('Failed host lookup') ||
              error.toString().contains('TimeoutException');

          setState(() {
            if (_messages.isNotEmpty && _messages.last.isAssistant) {
              if (isOffline) {
                _isApiOnline = false; // Instantly mark as offline
                _messages.last.text = _llmService.isInitialized
                    ? '📶 Network connection lost. Please tap send again to use the local Offline AI.'
                    : '📶 Network connection lost. Please reconnect to use the chatbot, or wait for the offline model to finish downloading.';
              } else {
                _messages.last.text =
                    'Error: Unable to generate response. Please try again.';
              }
              _messages.last.isComplete = true;
            }
            _currentAssistantMessage = '';
            _isProcessing = false;
          });

          if (mounted && !isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        if (_messages.isNotEmpty && _messages.last.isAssistant) {
          _messages.last.text = 'Error: Model not ready. Please try again.';
          _messages.last.isComplete = true;
        }
        _currentAssistantMessage = '';
        _isProcessing = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Banner listeners
          ValueListenableBuilder<bool>(
            valueListenable: _llmService.isDownloading,
            builder: (context, downloading, child) {
              if (!downloading) return const SizedBox.shrink();
              return ValueListenableBuilder<double>(
                valueListenable: _llmService.downloadProgress,
                builder: (context, progress, child) {
                  return _buildDownloadBanner(progress);
                },
              );
            },
          ),

          ValueListenableBuilder<String?>(
            valueListenable: _llmService.downloadError,
            builder: (context, errorMsg, child) {
              if (errorMsg != null && !_llmService.isInitialized) {
                return _buildErrorBanner();
              }
              return const SizedBox.shrink();
            },
          ),

          // Chat messages
          Expanded(child: _buildMessageList()),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
          Theme.of(context).primaryColor,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.psychology,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SeedScan AI',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _isApiOnline
                    ? 'Online'
                    : _llmService.isInitialized
                        ? 'Offline (Local AI)'
                        : 'Offline',
                style: TextStyle(
                  color: _isApiOnline
                      ? Colors.greenAccent
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Online/offline dot
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isApiOnline ? Colors.greenAccent : Colors.redAccent,
          ),
        ),
        // Clear conversation
        IconButton(
          icon: Icon(Icons.refresh,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7)),
          onPressed: _isProcessing
              ? null
              : () => setState(() {
                    _messages
                      ..clear()
                      ..add(ChatMessage(
                        text:
                            'Hello! I am SeedScan Expert. How can I help you today?',
                        isAssistant: true,
                        timestamp: DateTime.now(),
                      ));
                    _currentAssistantMessage = '';
                    _conversation.clear();
                  }),
        ),
      ],
    );
  }

  // ── Download banner ──────────────────────────────────────────────────────

  Widget _buildDownloadBanner(double progress) {
    final downloadedMB =
        (progress * _kModelTotalBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMB = (_kModelTotalBytes / (1024 * 1024)).toStringAsFixed(1);
    final pct = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF10A37F).withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF10A37F),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Downloading offline AI model in background…',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.75),
                  ),
                ),
              ),
              Text(
                '$pct%  •  $downloadedMB / $totalMB MB',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF10A37F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              minHeight: 4,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF10A37F)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error banner ─────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline model download failed. Online chatbot still works.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _llmService.downloadError.value = null;
              _llmService.initialize().catchError((_) {});
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry',
                style: TextStyle(color: Color(0xFF10A37F), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Message list ─────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) => MessageBubble(
        message: _messages[index],
        showTyping:
            !_messages[index].isComplete && _messages[index].isAssistant,
        typingAnimation: _typingAnimationController,
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).primaryColor,
        border: Border(
          top: BorderSide(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
          bottom: BorderSide(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: _isApiOnline
                      ? 'Ask about your apple trees…'
                      : _llmService.isInitialized
                          ? 'Ask about your apple trees (offline)…'
                          : 'Ask about your apple trees…',
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isProcessing,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: _isProcessing || _controller.text.isEmpty
                    ? Theme.of(context).disabledColor
                    : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _isProcessing || _controller.text.isEmpty
                    ? null
                    : _sendMessage,
                icon: Icon(
                  Icons.send,
                  color: _isProcessing || _controller.text.isEmpty
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────

class ChatMessage {
  String text;
  final bool isAssistant;
  final DateTime timestamp;
  bool isComplete;

  ChatMessage({
    required this.text,
    required this.isAssistant,
    required this.timestamp,
    this.isComplete = true,
  });
}

// ── MessageBubble ─────────────────────────────────────────────────────────────

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTyping;
  final AnimationController? typingAnimation;

  const MessageBubble({
    super.key,
    required this.message,
    this.showTyping = false,
    this.typingAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context, listen: false);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isAssistant
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (message.isAssistant) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: message.isAssistant
                      ? Colors.transparent
                      : const Color(0xFF565869),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showTyping && message.text.isEmpty)
                    AnimatedBuilder(
                      animation: typingAnimation!,
                      builder: (context, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final anim = Tween(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: typingAnimation!,
                              curve: Interval(
                                i * 0.2,
                                0.6 + i * 0.2,
                                curve: Curves.easeInOut,
                              ),
                            ),
                          );
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: Transform.translate(
                              offset: Offset(0, -4 * anim.value),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    )
                  else
                    Text(
                      message.text.isEmpty && !message.isComplete
                          ? '...'
                          : message.text,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!message.isAssistant) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6E6E80),
                borderRadius: BorderRadius.circular(8),
                image: auth.profileImage != null
                    ? DecorationImage(
                        image: FileImage(File(auth.profileImage!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: auth.profileImage == null
                  ? Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
