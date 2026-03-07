import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../ai/llama_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _llamaService = LlamaService();
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();
  
  // 0 = CPU, 1 = GPU/Metal/Vulkan
  int _computeDevice = 0; 
  bool _isInitializing = false;
  bool _isGenerating = false;
  bool _isModelLoaded = false;
  
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _startListening() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _promptController.text = result.recognizedWords;
          });
        },
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initModel() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final success = await _llamaService.initModel(computeDevice: _computeDevice);
      if (success) {
        setState(() {
          _isModelLoaded = true;
          _messages.add({'role': 'system', 'content': 'Model loaded successfully!'});
        });
      } else {
        setState(() {
          _messages.add({'role': 'system', 'content': 'Failed to load model. Please ensure the model file is placed correctly.'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'system', 'content': 'Error initializing model: $e'});
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _generateResponse() async {
    if (_isListening) {
      await _stopListening();
    }
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || !_isModelLoaded) return;

    setState(() {
      _messages.add({'role': 'user', 'content': prompt});
      _isGenerating = true;
    });
    
    _promptController.clear();
    _scrollToBottom();

    try {
      final response = await _llamaService.generateText(prompt);
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'system', 'content': 'Error generating text: $e'});
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
      _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemma Local AI'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Device: '),
                DropdownButton<int>(
                  value: _computeDevice,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('CPU')),
                    DropdownMenuItem(value: 1, child: Text('GPU/Hardware')),
                  ],
                  onChanged: _isModelLoaded || _isInitializing
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _computeDevice = value;
                            });
                          }
                        },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isModelLoaded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isInitializing ? null : _initModel,
                child: _isInitializing
                    ? const CircularProgressIndicator()
                    : const Text('Initialize Model'),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                final isSystem = message['role'] == 'system';
                
                return Align(
                  alignment: isSystem 
                      ? Alignment.center 
                      : (isUser ? Alignment.centerRight : Alignment.centerLeft),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isSystem 
                          ? Colors.grey.withOpacity(0.2) 
                          : (isUser ? Colors.blue : Colors.deepPurple),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      message['content'] ?? '',
                      style: TextStyle(
                        fontStyle: isSystem ? FontStyle.italic : FontStyle.normal,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your prompt...',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isModelLoaded && !_isGenerating,
                    onSubmitted: (_) => _generateResponse(),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: () {
                    if (_isListening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                  },
                  tooltip: 'Voice Type',
                  style: IconButton.styleFrom(
                    foregroundColor: _isListening ? Colors.red : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: (_isModelLoaded && !_isGenerating) ? _generateResponse : null,
                  style: IconButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
