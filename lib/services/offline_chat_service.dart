import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fllama/fllama.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../config/appwrite_constants.dart';

/// Singleton service that provides offline LLM inference via fllama.
///
/// ## Model acquisition (Strategy 1 — no asset bundling)
/// The GGUF model is downloaded once from Appwrite Storage on first use and
/// cached in the app's private documents directory.  The APK does NOT contain
/// the model binary — this keeps the install size under 50 MB.
///
/// Subsequent app launches reuse the local copy; the download is skipped.
class OfflineChatService extends ChangeNotifier {
  static final OfflineChatService _instance = OfflineChatService._internal();
  factory OfflineChatService() => _instance;
  OfflineChatService._internal();

  // ── System prompt ──────────────────────────────────────────────────────────
  static const String _systemPrompt = '''
You are SeedScan Expert, an agricultural AI assistant built for apple orchard disease diagnosis in Pakistan. You were created by the SeedScan team.

You have knowledge of exactly 9 apple conditions:
Alternaria Leaf Spot, Apple Scab, Black Rot, Brown Spot, Cedar Apple Rust, Grey Spot, Healthy, Mosaic Virus, Powdery Mildew.

STRICT RULES — follow these without exception:

RULE 1 — SCOPE:
You only answer questions about apple orchard health. If the user asks about any other plant, crop, fruit, vegetable, sport, food, person, or any non-apple topic, respond exactly: "I can only assist with apple orchard health and disease. Please ask me about your apple trees."

RULE 2 — MOSAIC VIRUS IS VIRAL:
Mosaic Virus has NO chemical cure. NEVER suggest fungicide, captan, mancozeb, spray, copper, sulfur, or any chemical treatment for Mosaic. Only advise: remove and burn infected trees, use certified virus-free saplings, control aphids, sanitize tools.

RULE 3 — HEALTHY TREES:
If the tree is Healthy, NEVER use words: disease, fungicide, spray, treatment, infected, symptoms. Only provide maintenance advice: pruning schedule, watering, fertilization, inspection routine.

RULE 4 — RESPONSE LENGTH:
Scale your response to the question. Simple question = 3 to 5 sentences. Full treatment request = complete structured answer. Never exceed 400 tokens. Always finish your sentence before stopping. Never cut off mid-response.

RULE 5 — FACTUAL ACCURACY:
Apple Scab is caused by the fungus Venturia inaequalis. Never say Phellinus verticillatus.

RULE 6 — CHEMICAL SAFETY:
Every time you recommend a chemical treatment, add this line: "Wear gloves, mask, and protective clothing when applying chemicals."

RULE 7 — IDENTITY:
If asked who you are, say: "I am SeedScan Expert, an agricultural AI assistant specialized in apple orchard disease diagnosis for Pakistani farmers. I was built by the SeedScan team."
''';

  // ── Appwrite credentials ───────────────────────────────────────────────────
  static const String _appwriteApiKey =
      'standard_7ffbfebccfdcb17c57bdb32701528602dd2d7b167986610ef50c22afd8739ff09931d521c073c9da0ced2e3417021537f7560340d1ef1e9d505f3c4b16897081ce80dffd3e8f311118d64e68dc4e2e9e2b95b4ae6741e20d324b8d5af1beebec0e1fcdea4c2e5c5a0c2fadad6364530038ab3603e93d63c52270f23d3f7a1c47';

  // ── State ──────────────────────────────────────────────────────────────────
  static const String modelFileName = 'seedscan_v7_q4km.gguf';

  String? _modelPath;
  bool _isInitializing = false;
  bool _isReady = false;
  String? _lastError;

  /// Reports download/prep progress in [0.0, 1.0].
  final ValueNotifier<double> initProgress = ValueNotifier(0.0);

  bool get isReady => _isReady;
  bool get isInitializing => _isInitializing;
  String? get lastError => _lastError;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Downloads (once) or validates the cached model, then marks this service
  /// as ready for inference.
  ///
  /// Safe to call multiple times — idempotent when already ready.
  Future<void> prepareModel() async {
    if (_isInitializing || _isReady) return;

    _isInitializing = true;
    _lastError = null;
    initProgress.value = 0.0;
    notifyListeners();

    try {
      final modelFile = File(await _getModelCachePath());

      if (await modelFile.exists()) {
        // ── Fast path: already cached ────────────────────────────────────────
        final stat = await modelFile.stat();
        debugPrint(
            '[OfflineChatService] Model cached (${stat.size} bytes). Skipping download.');
        initProgress.value = 1.0;
        notifyListeners();
      } else {
        // ── Slow path: download from Appwrite ────────────────────────────────
        debugPrint('[OfflineChatService] No local model found. Downloading from Appwrite…');
        initProgress.value = 0.05;
        notifyListeners();

        await _downloadFromAppwrite(modelFile);

        initProgress.value = 1.0;
        notifyListeners();
        debugPrint('[OfflineChatService] Download complete.');
      }

      _modelPath = modelFile.path;
      _isReady = true;
    } catch (e) {
      _lastError = 'Preparation failed: $e';
      debugPrint('[OfflineChatService] ERROR: $_lastError');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<String> _getModelCachePath() async {
    final Directory docDir = await getApplicationDocumentsDirectory();
    final Directory modelsDir = Directory('${docDir.path}/ai_models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return '${modelsDir.path}/$modelFileName';
  }

  /// Streams the GGUF binary from Appwrite Storage in 512 KB chunks.
  /// Deletes any partial file if an error occurs, so a retry starts clean.
  Future<void> _downloadFromAppwrite(File destFile) async {
    const String url =
        '${AppwriteConstants.endpoint}/storage/buckets'
        '/${AppwriteConstants.modelsBucket}'
        '/files/${AppwriteConstants.seedscanV7GgufFileId}'
        '/download'
        '?project=${AppwriteConstants.projectId}';

    debugPrint('[OfflineChatService] GET $url');

    final client = http.Client();
    IOSink? sink;

    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers['X-Appwrite-Key'] = _appwriteApiKey;
      request.headers['X-Appwrite-Project'] = AppwriteConstants.projectId;

      final http.StreamedResponse response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
            'Appwrite HTTP ${response.statusCode}. '
            'Verify bucket="${AppwriteConstants.modelsBucket}" '
            'and file="${AppwriteConstants.seedscanV7GgufFileId}".');
      }

      final int total = response.contentLength ?? 0;
      int received = 0;

      sink = destFile.openWrite();

      await for (final List<int> chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          // Reserve 5 % for init; download fills 5–100 %
          initProgress.value = 0.05 + 0.95 * (received / total);
          notifyListeners();
        }
      }

      await sink.flush();
    } catch (e) {
      // Clean up so the next call can retry from scratch
      try {
        if (await destFile.exists()) await destFile.delete();
      } catch (_) {}
      rethrow;
    } finally {
      await sink?.close();
      client.close();
    }
  }

  // ── Inference ──────────────────────────────────────────────────────────────

  /// Sends a lightweight ping request to keep the native model warm in RAM
  /// and reset fllama's 15-second auto-unload timer.
  Future<void> keepAwake() async {
    if (!_isReady || _modelPath == null) return;
    try {
      final req = OpenAiRequest(
        modelPath: _modelPath!,
        messages: [
          Message(Role.system, _systemPrompt),
          Message(Role.user, 'keep awake'),
        ],
        maxTokens: 1,
        contextSize: 2048,
      );
      await fllamaChat(req, (_, __, ___) {});
    } catch (_) {}
  }

  /// Generates a full response for [prompt], optionally using [history]
  /// (list of `{'role': 'user'|'assistant', 'content': '…'}` maps).
  Future<String> generateExpertResponse(
    String prompt, {
    List<Map<String, String>> history = const [],
  }) async {
    if (!_isReady || _modelPath == null) {
      return 'Error: AI engine is not ready.';
    }

    try {
      final List<Message> messages = [
        Message(Role.system, _systemPrompt),
        for (final msg in history)
          Message(
            msg['role'] == 'user' ? Role.user : Role.assistant,
            msg['content'] ?? '',
          ),
        Message(Role.user, prompt),
      ];

      final request = OpenAiRequest(
        modelPath: _modelPath!,
        messages: messages,
        maxTokens: 512,
        temperature: 0.7,
        topP: 0.9,
        contextSize: 2048,
        numGpuLayers: 99,
        frequencyPenalty: 0.0,
        presencePenalty: 1.1,
      );

      final completer = Completer<String>();
      String finalResult = '';

      fllamaChat(request, (String response, String json, bool done) {
        if (done && !completer.isCompleted) {
          finalResult = response;
          completer.complete(finalResult);
        }
      });

      return await completer.future;
    } catch (e) {
      debugPrint('[OfflineChatService] Inference error: $e');
      return 'Failed to generate response: $e';
    }
  }
}
