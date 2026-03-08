import 'package:flutter/material.dart';
import '../ai/llama_service.dart';

import 'package:file_picker/file_picker.dart';

class LlamaProvider extends ChangeNotifier {
  final LlamaService _llamaService = LlamaService();

  // State variables
  int _computeDevice = 0;
  bool _isInitializing = false;
  bool _isGenerating = false;
  bool _isModelLoaded = false;
  bool _useSubprocess = true;
  String? _modelPath;
  final List<Map<String, String>> _messages = [];

  // Getters
  int get computeDevice => _computeDevice;
  bool get isInitializing => _isInitializing;
  bool get isGenerating => _isGenerating;
  bool get isModelLoaded => _isModelLoaded;
  bool get useSubprocess => _useSubprocess;
  String? get modelPath => _modelPath;
  List<Map<String, String>> get messages => _messages;

  // Setters/Toggles
  void setComputeDevice(int device) {
    if (_isModelLoaded || _isInitializing) return;
    _computeDevice = device;
    notifyListeners();
  }

  void setUseSubprocess(bool value) {
    _useSubprocess = value;
    notifyListeners();
  }

  // Actions
  Future<void> pickAndInitModel() async {
    if (_isInitializing || _isModelLoaded) return;
    _isInitializing = true;
    notifyListeners();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Gemma GGUF Model',
        type: FileType.any, // .gguf might not be natively supported on all platforms for filtering
      );

      if (result != null && result.files.single.path != null) {
        _modelPath = result.files.single.path;
        await _performInit();
      } else {
        _messages.add({'role': 'system', 'content': 'Model selection cancelled.'});
        _isInitializing = false;
        notifyListeners();
      }
    } catch (e) {
      _messages.add({'role': 'system', 'content': 'Error picking model: $e'});
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _performInit() async {
    if (_modelPath == null) return;
    
    try {
      if (_useSubprocess) {
        // Persistent subprocess load
        final success = await _llamaService.initSubprocessModel(modelPath: _modelPath!);
        if (success) {
          _isModelLoaded = true;
          _messages.add({'role': 'system', 'content': 'Model ready (Subprocess interactive mode)'});
        } else {
          _messages.add({'role': 'system', 'content': 'Failed to load model via subprocess.'});
        }
      } else {
        final success = await _llamaService.initModel(computeDevice: _computeDevice, modelPath: _modelPath!);
        if (success) {
          _isModelLoaded = true;
          _messages.add({'role': 'system', 'content': 'Model loaded successfully!'});
        } else {
          _messages.add({'role': 'system', 'content': 'Failed to load model. Please ensure the model file is valid.'});
        }
      }
    } catch (e) {
      _messages.add({'role': 'system', 'content': 'Error initializing model: $e'});
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> generateResponse(String prompt, {VoidCallback? onScrollRequested}) async {
    if (prompt.isEmpty || (!_isModelLoaded && !_useSubprocess)) return;

    _messages.add({'role': 'user', 'content': prompt});
    _isGenerating = true;
    _messages.add({'role': 'assistant', 'content': ''});
    notifyListeners();
    onScrollRequested?.call();

    final assistantIndex = _messages.length - 1;
    String fullResponse = '';

    try {
      final stream = _useSubprocess
          ? _llamaService.generateTextSubprocessStream(prompt)
          : _llamaService.generateTextStream(prompt);

      await for (final token in stream) {
        fullResponse += token;
        _messages[assistantIndex]['content'] = fullResponse;
        notifyListeners();
        onScrollRequested?.call();
      }
    } catch (e) {
      _messages.add({'role': 'system', 'content': 'Error generating text: $e'});
      notifyListeners();
      onScrollRequested?.call();
    } finally {
      _isGenerating = false;
      notifyListeners();
      onScrollRequested?.call();
    }
  }
}
