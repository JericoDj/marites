import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/llama_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // macOS has TCC sandbox quirks with SpeechToText that crash the app on startup
    // Initialize on startup for other platforms, but delay for macOS
    if (!Platform.isMacOS) {
      _initSpeech();
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize();
      setState(() {});
    } catch (e) {
      print('Speech init error: $e');
    }
  }

  Future<void> _startListening() async {
    if (Platform.isMacOS && !_speechEnabled) {
      await _initSpeech();
    }

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

  Future<void> _handleGenerateResponse() async {
    if (_isListening) {
      await _stopListening();
    }
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    _promptController.clear();

    // Call the provider to handle the prompt processing
    await context.read<LlamaProvider>().generateResponse(
      prompt,
      onScrollRequested: _scrollToBottom,
    );
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
    // Watch the provider for changes to UI state
    final llamaProvider = context.watch<LlamaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemma Local AI'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('CLI Subprocess: '),
                Switch(
                  value: llamaProvider.useSubprocess,
                  onChanged: (value) {
                    llamaProvider.setUseSubprocess(value);
                  },
                ),
                const SizedBox(width: 16.0),
                const Text('Device: '),
                DropdownButton<int>(
                  value: llamaProvider.computeDevice,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('CPU')),
                    DropdownMenuItem(value: 1, child: Text('GPU/Hardware')),
                  ],
                  onChanged:
                      llamaProvider.isModelLoaded ||
                          llamaProvider.isInitializing
                      ? null
                      : (value) {
                          if (value != null) {
                            llamaProvider.setComputeDevice(value);
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
          if (!llamaProvider.isModelLoaded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: llamaProvider.isInitializing
                    ? null
                    : () {
                        llamaProvider.pickAndInitModel().then(
                          (_) => _scrollToBottom(),
                        );
                      },
                child: llamaProvider.isInitializing
                    ? const CircularProgressIndicator()
                    : const Text('Select & Initialize Model'),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: llamaProvider.messages.length,
              itemBuilder: (context, index) {
                final message = llamaProvider.messages[index];
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
                    child: SelectableText(
                      message['content'] ?? '',
                      style: TextStyle(
                        fontStyle: isSystem
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (llamaProvider.isGenerating)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: RawKeyboardListener(
                    focusNode: FocusNode(),
                    onKey: (event) {
                      if (event is RawKeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !event.isShiftPressed) {
                        // Enter without Shift sends the message
                        _handleGenerateResponse();
                      }
                    },
                    child: TextField(
                      controller: _promptController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your prompt...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      enabled:
                          (llamaProvider.isModelLoaded ||
                              llamaProvider.useSubprocess) &&
                          !llamaProvider.isGenerating,
                    ),
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
                  onPressed:
                      ((llamaProvider.isModelLoaded ||
                              llamaProvider.useSubprocess) &&
                          !llamaProvider.isGenerating)
                      ? _handleGenerateResponse
                      : null,
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
