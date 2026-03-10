import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'dart:convert';
import 'package:ffi/ffi.dart';

// -----------------------------------------------------------------------------
// FFI Typedefs
// -----------------------------------------------------------------------------

// bool init_model(const char* model_path, int compute_device);
typedef NativeInitModel =
    Bool Function(Pointer<Utf8> modelPath, Int32 computeDevice);
typedef DartInitModel =
    bool Function(Pointer<Utf8> modelPath, int computeDevice);

// void generate_text_stream(const char* prompt, token_callback callback);
typedef NativeGenerateTextStream =
    Void Function(
      Pointer<Utf8> prompt,
      Pointer<NativeFunction<Void Function(Pointer<Utf8>)>> callback,
    );
typedef DartGenerateTextStream =
    void Function(
      Pointer<Utf8> prompt,
      Pointer<NativeFunction<Void Function(Pointer<Utf8>)>> callback,
    );

// -----------------------------------------------------------------------------
// LlamaService
// -----------------------------------------------------------------------------

class LlamaService {
  LlamaService();

  Future<bool> initModel({
    required int computeDevice,
    required String modelPath,
  }) async {
    final modelPathStr = modelPath;
    return await Isolate.run(() {
      final modelPathPtr = modelPathStr.toNativeUtf8();
      try {
        if (Platform.isAndroid) {
          // On Android, the OS linker doesn't automatically load interdependent local libraries
          // if they aren't standard system libraries. Since llama.cpp builds ggml as separate .so files,
          // we must load them into the process memory first before libllama.so can link to them.
          try {
            DynamicLibrary.open('libomp.so');
          } catch (_) {}
          try {
            DynamicLibrary.open('libggml-base.so');
          } catch (_) {}
          try {
            DynamicLibrary.open('libggml-cpu.so');
          } catch (_) {}
          try {
            DynamicLibrary.open('libggml.so');
          } catch (_) {}
        }

        String libDir = Platform.isAndroid
            ? 'libllama_wrapper.so'
            : (Platform.isWindows ? 'llama_wrapper.dll' : 'libllama.dylib');

        if (Platform.isMacOS) {
          final devBin = File(
            '/Users/jericodejesus/projects/marites/macos/Runner/llama/build/bin',
          ).absolute;
          if (devBin.existsSync()) {
            try {
              DynamicLibrary.open('${devBin.path}/libggml-base.dylib');
            } catch (_) {}
            try {
              DynamicLibrary.open('${devBin.path}/libggml-metal.dylib');
            } catch (_) {}
            try {
              DynamicLibrary.open('${devBin.path}/libggml-cpu.dylib');
            } catch (_) {}
            try {
              DynamicLibrary.open('${devBin.path}/libggml.dylib');
            } catch (_) {}
            try {
              DynamicLibrary.open('${devBin.path}/libllama.dylib');
            } catch (_) {}
            final wrapperPath = File(
              '/Users/jericodejesus/projects/marites/macos/Runner/llama/build/libllama.dylib',
            ).absolute;
            if (wrapperPath.existsSync()) {
              libDir = wrapperPath.path;
            }
          }
        }

        final lib = DynamicLibrary.open(libDir);
        final initModelFunc = lib
            .lookupFunction<NativeInitModel, DartInitModel>('init_model');
        return initModelFunc(modelPathPtr, computeDevice);
      } finally {
        calloc.free(modelPathPtr);
      }
    });
  }

  Stream<String> generateTextStream(String prompt) async* {
    final controller = StreamController<String>();

    // Create the listener in the MAIN isolate so it can receive messages while background is blocked
    final nativeCallback =
        NativeCallable<Void Function(Pointer<Utf8>)>.listener((
          Pointer<Utf8> tokenPtr,
        ) {
          if (!controller.isClosed) {
            controller.add(tokenPtr.toDartString());
          }
        });

    final exitPort = ReceivePort();

    // Spawn the worker isolate
    await Isolate.spawn(_inferenceIsolate, {
      'prompt': prompt,
      'callbackPtr': nativeCallback.nativeFunction.address,
      'exitPort': exitPort.sendPort,
    });

    // Handle background completion
    final completer = Completer<void>();
    exitPort.listen((_) {
      nativeCallback.close();
      if (!controller.isClosed) controller.close();
      exitPort.close();
      completer.complete();
    });

    yield* controller.stream;
    await completer
        .future; // Ensure we keep the steam alive until background finishes
  }

  static void _inferenceIsolate(Map<String, dynamic> args) {
    final String prompt = args['prompt'];
    final int callbackAddr = args['callbackPtr'];
    final SendPort exitPort = args['exitPort'];

    try {
      String libDir = Platform.isAndroid
          ? 'libllama_wrapper.so'
          : (Platform.isWindows ? 'llama_wrapper.dll' : 'libllama.dylib');

      if (Platform.isMacOS) {
        final devBin = File(
          '/Users/jericodejesus/projects/marites/macos/Runner/llama/build/bin',
        ).absolute;
        if (devBin.existsSync()) {
          try {
            DynamicLibrary.open('${devBin.path}/libggml-base.dylib');
          } catch (_) {}
          try {
            DynamicLibrary.open('${devBin.path}/libggml-metal.dylib');
          } catch (_) {}
          try {
            DynamicLibrary.open('${devBin.path}/libggml-cpu.dylib');
          } catch (_) {}
          try {
            DynamicLibrary.open('${devBin.path}/libggml.dylib');
          } catch (_) {}
          try {
            DynamicLibrary.open('${devBin.path}/libllama.dylib');
          } catch (_) {}
          final wrapperPath = File(
            '/Users/jericodejesus/projects/marites/macos/Runner/llama/build/libllama.dylib',
          ).absolute;
          if (wrapperPath.existsSync()) {
            libDir = wrapperPath.path;
          }
        }
      }

      final lib = DynamicLibrary.open(libDir);

      final streamFunc = lib
          .lookupFunction<NativeGenerateTextStream, DartGenerateTextStream>(
            'generate_text_stream',
          );

      final promptPtr = prompt.toNativeUtf8();

      final callbackPtr =
          Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>.fromAddress(
            callbackAddr,
          );

      streamFunc(promptPtr, callbackPtr);
      calloc.free(promptPtr);
    } catch (e) {
      print("ERROR in inference isolate: $e");
    } finally {
      exitPort.send(null); // Signal main isolate that we are done
    }
  }

  // Keep legacy for compatibility
  Future<String> generateText(String prompt) async {
    final buffer = StringBuffer();
    await for (final token in generateTextStream(prompt)) {
      buffer.write(token);
    }
    return buffer.toString();
  }

  // --- SUBPROCESS TEST IMPLEMENTATION ---
  Process? _subprocess;
  StreamController<String>? _subprocessController;
  Completer<bool>? _initCompleter;
  final StringBuffer _responseBuffer = StringBuffer();

  Future<bool> initSubprocessModel({required String modelPath}) async {
    if (_subprocess != null) return true;
    _initCompleter = Completer<bool>();

    try {
      String cliPath = '';
      if (Platform.isWindows) {
        cliPath =
            r'C:\Users\dejes\StudioProjects\ ADA-AI-ASSISTANT\gemma_local_ai\llama_prebuilt\llama-cli.exe';
      } else if (Platform.isAndroid) {
        // This assumes the cli is placed alongside the lib in the app directory, or we ship a compiled binary.
        // Realistically Android requires JNI/FFI, but we will put a placeholder.
        cliPath = '/data/local/tmp/llama-cli';
      } else if (Platform.isIOS || Platform.isMacOS) {
        cliPath = 'llama-cli';
        if (Platform.isMacOS) {
          final devCli = File(
            '/Users/jericodejesus/projects/marites/macos/Runner/llama/build/bin/llama-cli',
          ).absolute;
          if (devCli.existsSync()) {
            cliPath = devCli.path;
          }
        }
      }

      _subprocess = await Process.start(cliPath, [
        '-m', modelPath,
        '-cnv', // Use conversational mode for persistent keeping alive
        '-t', '8',
        '-c', '2048',
        '-n', '10000', // Optional max tokens per turn
        '--no-display-prompt',
        '--log-disable',
      ]);

      _subprocess!.stdout.transform(utf8.decoder).listen((text) {
        // Initial setup wait for the prompt "> " marker
        if (_initCompleter != null && !_initCompleter!.isCompleted) {
          if (text.contains('> ')) {
            _initCompleter!.complete(true);
          }
          return;
        }

        // Active generation
        if (_subprocessController != null && !_subprocessController!.isClosed) {
          String chunk = text;
          bool isDone = false;

          // Strip ANSI escape codes and terminal control characters
          chunk = chunk.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
          chunk = chunk.replaceAll(RegExp(r'\x1B\].*?\x07'), '');
          chunk = chunk.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

          // Strip the echoed prompt from the beginning of the response
          if (_currentPrompt != null && chunk.contains(_currentPrompt!)) {
            chunk = chunk.substring(
              chunk.indexOf(_currentPrompt!) + _currentPrompt!.length,
            );
            _currentPrompt = null; // Only strip once
          }

          // Process termination chunk
          if (chunk.contains('> ')) {
            isDone = true;
            chunk = chunk.replaceAll(RegExp(r'\[\s*Prompt:.*?\]'), '');
            chunk = chunk.replaceAll('> ', '');
          }

          // Trim leading newlines from the cleaned chunk
          if (_currentPrompt == null) {
            chunk = chunk.replaceFirst(RegExp(r'^\n+'), '');
          }

          if (chunk.isNotEmpty) {
            _responseBuffer.write(chunk);
            _subprocessController!.add(chunk);
          }

          if (isDone) {
            // Detect and print JSON from the complete response
            final fullResponse = _responseBuffer.toString();
            final jsonPattern = RegExp(r'[\{\[][\s\S]*[\}\]]');
            final jsonMatch = jsonPattern.firstMatch(fullResponse);
            if (jsonMatch != null) {
              try {
                final parsed = json.decode(jsonMatch.group(0)!);
                print(
                  '[JSON DETECTED] ${const JsonEncoder.withIndent('  ').convert(parsed)}',
                );
              } catch (_) {
                // Not valid JSON
              }
            }
            _responseBuffer.clear();
            _subprocessController!.close();
            _subprocessController = null;
          }
        }
      });

      _subprocess!.stderr.transform(utf8.decoder).listen((text) {
        // Log stderr (often model load progress goes here too)
        print("[LLAMA STDERR] $text");
      });

      return await _initCompleter!.future;
    } catch (e) {
      print("Error starting subprocess: $e");
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete(false);
      }
      return false;
    }
  }

  String? _currentPrompt;

  Stream<String> generateTextSubprocessStream(String prompt) {
    if (_subprocess == null) {
      throw Exception(
        'Subprocess not initialized. Call initSubprocessModel first.',
      );
    }

    _subprocessController = StreamController<String>();
    _currentPrompt = prompt;

    // In -cnv mode, sending the prompt followed by newline triggers generation
    _subprocess!.stdin.writeln(prompt);

    return _subprocessController!.stream;
  }
}
