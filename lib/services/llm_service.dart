import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fllama/fllama.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../config/appwrite_constants.dart';

/// Singleton LLM service that manages the on-device GGUF model lifecycle.
///
/// ## Model acquisition strategy (Strategy 1 — Appwrite download)
/// The GGUF binary is NOT bundled as a Flutter asset any more (saves ~270 MB
/// from the APK).  On first launch the service streams the file from the
/// project's Appwrite Storage bucket directly to the device's private
/// documents directory.  On every subsequent launch it detects the locally
/// cached file and skips the download entirely.
///
/// Download URL pattern:
///   {endpoint}/storage/buckets/{bucketId}/files/{fileId}/download?project={projectId}
/// Auth: `X-Appwrite-Key` header (server API key — never exposed in the UI).
class LLMService {
  static final LLMService _instance = LLMService._internal();
  factory LLMService() => _instance;
  LLMService._internal();

  String? _modelPath;
  bool _isInitialized = false;
  bool _isLoading = false;

  // ── Model constants ────────────────────────────────────────────────────────
  static const String modelFileName = 'seedscan_v7_q4km.gguf';

  /// Appwrite server API key — used only for storage downloads.
  /// Keep this in a secrets manager / obfuscated build config for production.
  static const String _appwriteApiKey =
      'standard_7ffbfebccfdcb17c57bdb32701528602dd2d7b167986610ef50c22afd8739ff09931d521c073c9da0ced2e3417021537f7560340d1ef1e9d505f3c4b16897081ce80dffd3e8f311118d64e68dc4e2e9e2b95b4ae6741e20d324b8d5af1beebec0e1fcdea4c2e5c5a0c2fadad6364530038ab3603e93d63c52270f23d3f7a1c47';

  // ── Inference parameters (optimised for mobile) ───────────────────────────
  static const int contextSize = 2048;
  static const int maxTokens = 512;
  static const double temperature = 0.7;
  static const double topP = 0.9;

  /// CRITICAL: Set to 0 to force CPU execution.
  /// Using high GPU layers on mobile often causes the native engine to crash.
  static const int numGpuLayers = 0;

  static const double frequencyPenalty = 0.0;
  static const double presencePenalty = 1.1;

  // ── Global State Notifiers ────────────────────────────────────────────────
  final ValueNotifier<bool> isDownloading = ValueNotifier(false);
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  final ValueNotifier<String?> downloadError = ValueNotifier(null);

  bool get isInitialized => _isInitialized;

  static const int _kExpectedModelSize = 270590432; // Exact GGUF file bytes

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Prepares the model for inference. Call this freely from anywhere.
  Future<void> initialize() async {
    if (_isInitialized || isDownloading.value) return;

    try {
      isDownloading.value = true;
      downloadError.value = null;

      _modelPath = await _getModelCachePath();
      final modelFile = File(_modelPath!);

      bool needsDownload = true;

      // Validate existing file strictly to prevent partial-download crashes
      if (await modelFile.exists()) {
        final stat = await modelFile.stat();
        if (stat.size == _kExpectedModelSize) {
          debugPrint(
              '[LLMService] Valid model found in cache (${stat.size} bytes).');
          needsDownload = false;
          downloadProgress.value = 1.0;
        } else {
          debugPrint(
              '[LLMService] Discarding corrupt/partial model (${stat.size} bytes).');
          await modelFile.delete();
        }
      }

      if (needsDownload) {
        debugPrint('[LLMService] Starting Appwrite download…');
        await _downloadFromAppwrite();
      }

      // Final strict guard
      if (!await modelFile.exists() ||
          (await modelFile.stat()).size != _kExpectedModelSize) {
        throw Exception('Model download failed or file is corrupted.');
      }

      _isInitialized = true;
      debugPrint('[LLMService] Ready.');
    } catch (e) {
      final isOffline = e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup');
      final msg = isOffline
          ? 'You are offline. Connect to download the AI model.'
          : 'Failed to init LLM: $e';

      debugPrint('[LLMService] ERROR: $msg');
      downloadError.value = msg;
      rethrow;
    } finally {
      isDownloading.value = false;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Returns the absolute path to the locally cached model file.
  /// Creates the parent directory if it does not exist yet.
  Future<String> _getModelCachePath() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory modelsDir = Directory('${appDocDir.path}/ai_models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return '${modelsDir.path}/$modelFileName';
  }

  /// Streams the GGUF file from Appwrite Storage to [_modelPath].
  Future<void> _downloadFromAppwrite() async {
    const String downloadUrl = '${AppwriteConstants.endpoint}/storage/buckets'
        '/${AppwriteConstants.modelsBucket}'
        '/files/${AppwriteConstants.seedscanV7GgufFileId}'
        '/download'
        '?project=${AppwriteConstants.projectId}';

    debugPrint('[LLMService] Downloading from: $downloadUrl');

    final client = http.Client();
    IOSink? sink;

    try {
      final request = http.Request('GET', Uri.parse(downloadUrl));
      request.headers['X-Appwrite-Key'] = _appwriteApiKey;
      request.headers['X-Appwrite-Project'] = AppwriteConstants.projectId;

      final http.StreamedResponse response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Appwrite returned HTTP ${response.statusCode}.');
      }

      // Ignore HTTP contentLength which is null for chunked Appwrite streams.
      // Use our strict predefined model size limit for accurate progress.
      final double totalBytesLimit = _kExpectedModelSize.toDouble();
      int receivedBytes = 0;

      final File destFile = File(_modelPath!);
      sink = destFile.openWrite();

      await for (final List<int> chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        // Ensure we don't accidentally divide by zero or exceed 100% physically
        downloadProgress.value =
            (receivedBytes / totalBytesLimit).clamp(0.0, 1.0);
      }

      await sink.flush();
      debugPrint(
          '[LLMService] Download complete — $receivedBytes bytes written.');
    } catch (e) {
      try {
        final partial = File(_modelPath!);
        if (await partial.exists()) await partial.delete();
      } catch (_) {}
      rethrow;
    } finally {
      await sink?.close();
      client.close();
    }
  }

  // ── Inference ──────────────────────────────────────────────────────────────

  /// Streams response tokens for the given OpenAI-style message list.
  Stream<String> generateResponse({
    required List<Message> messages,
    int? maxTokens,
    double? temperature,
    double? topP,
  }) async* {
    if (!_isInitialized || _modelPath == null) {
      throw Exception('LLM Service not initialised');
    }

    final modelFile = File(_modelPath!);
    if (!await modelFile.exists()) {
      throw Exception('Model file not found at: $_modelPath');
    }

    final request = OpenAiRequest(
      modelPath: _modelPath!,
      messages: messages,
      maxTokens: maxTokens ?? LLMService.maxTokens,
      temperature: temperature ?? LLMService.temperature,
      topP: topP ?? LLMService.topP,
      contextSize: contextSize,
      numGpuLayers: numGpuLayers,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
    );

    final StreamController<String> controller = StreamController<String>();
    String fullResponse = '';
    bool hasError = false;

    try {
      fllamaChat(
        request,
        (String response, String responseJson, bool done) {
          if (!done && !hasError) {
            if (response.length > fullResponse.length) {
              final newToken = response.substring(fullResponse.length);
              fullResponse = response;
              if (!controller.isClosed) controller.add(newToken);
            }
          } else if (done && !hasError) {
            if (!controller.isClosed) controller.close();
          }
        },
      );

      yield* controller.stream;
    } catch (e) {
      hasError = true;
      debugPrint('[LLMService] Inference error: $e');
      if (!controller.isClosed) {
        controller.addError(e);
        controller.close();
      }
      rethrow;
    }
  }

  /// Convenience single-turn completion (no history).
  Future<String> complete(String prompt) async {
    final messages = [
      Message(Role.system,
          'You are SmolLM2-360M, a helpful AI assistant running on-device.'),
      Message(Role.user, prompt),
    ];
    return generateResponse(messages: messages).join();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  void dispose() {
    _isInitialized = false;
    _modelPath = null;
  }

  Map<String, dynamic> getModelInfo() => {
        'name': 'SmolLM2-360M (SeedScan v7)',
        'parameters': '360M',
        'quantization': 'Q4_K_M',
        'contextSize': contextSize,
        'fileSize': '~271 MB',
        'isInitialized': _isInitialized,
        'modelPath': _modelPath,
        'source': 'Appwrite Storage',
      };
}
