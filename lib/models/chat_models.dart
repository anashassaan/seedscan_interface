import 'package:fllama/fllama.dart';

// Re-export fllama's Message and Role for convenience
export 'package:fllama/fllama.dart' show Message, Role;

class ChatConversation {
  final List<Message> messages;
  final String? systemPrompt;
  
  ChatConversation({
    List<Message>? messages,
    this.systemPrompt,
  }) : messages = messages ?? [];
  
  /// Add a user message to the conversation
  void addUserMessage(String content) {
    messages.add(Message(Role.user, content));
  }
  
  /// Add an assistant message to the conversation
  void addAssistantMessage(String content) {
    messages.add(Message(Role.assistant, content));
  }
  
  /// Get messages with system prompt included
  List<Message> getMessagesWithSystem() {
    final List<Message> allMessages = [];
    
    // Add system prompt if provided
    if (systemPrompt != null && systemPrompt!.isNotEmpty) {
      allMessages.add(Message(Role.system, systemPrompt!));
    }
    
    // Add all conversation messages
    allMessages.addAll(messages);
    
    return allMessages;
  }
  
  /// Clear the conversation
  void clear() {
    messages.clear();
  }
  
  /// Get the last message
  Message? get lastMessage => messages.isNotEmpty ? messages.last : null;
  
  /// Get conversation as formatted string
  String toFormattedString() {
    final buffer = StringBuffer();
    
    if (systemPrompt != null) {
      buffer.writeln('System: $systemPrompt\n');
    }
    
    for (final message in messages) {
      final roleStr = message.role == Role.user ? 'User' : 
                     message.role == Role.assistant ? 'Assistant' : 'System';
      buffer.writeln('$roleStr: ${message.text}\n');
    }
    
    return buffer.toString();
  }
}

class ModelSettings {
  final int maxTokens;
  final double temperature;
  final double topP;
  final int contextSize;
  final String systemPrompt;
  final int numGpuLayers;
  final double frequencyPenalty;
  final double presencePenalty;
  
  const ModelSettings({
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.contextSize = 2048,
    this.systemPrompt = 'You are a helpful, friendly AI assistant running on-device. Keep your responses concise and helpful.',
    this.numGpuLayers = 99,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 1.1,
  });
  
  ModelSettings copyWith({
    int? maxTokens,
    double? temperature,
    double? topP,
    int? contextSize,
    String? systemPrompt,
    int? numGpuLayers,
    double? frequencyPenalty,
    double? presencePenalty,
  }) {
    return ModelSettings(
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      contextSize: contextSize ?? this.contextSize,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      numGpuLayers: numGpuLayers ?? this.numGpuLayers,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
    );
  }
}