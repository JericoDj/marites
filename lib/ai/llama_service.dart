import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

// -----------------------------------------------------------------------------
// FFI Typedefs
// -----------------------------------------------------------------------------

// bool init_model(const char* model_path, int compute_device);
typedef NativeInitModel = Bool Function(Pointer<Utf8> modelPath, Int32 computeDevice);
typedef DartInitModel = bool Function(Pointer<Utf8> modelPath, int computeDevice);

// const char* generate_text(const char* prompt);
typedef NativeGenerateText = Pointer<Utf8> Function(Pointer<Utf8> prompt);
typedef DartGenerateText = Pointer<Utf8> Function(Pointer<Utf8> prompt);

// void free_text(const char* text);
typedef NativeFreeText = Void Function(Pointer<Utf8> text);
typedef DartFreeText = void Function(Pointer<Utf8> text);

// -----------------------------------------------------------------------------
// LlamaService
// -----------------------------------------------------------------------------

class LlamaService {
  LlamaService();

  Future<String> _getModelPath() async {
    // In a real app, you might copy the model from assets to a temporary directory
    // or request file system access to a downloaded file.
    // For this demonstration, we'll try to find it in the expected OS locations.
    
    String expectedPath = '';
    if (Platform.isAndroid) {
      // NOTE: For Android, retrieving gigabyte files from assets directly via path
      // isn't viable natively without extracting. A real app would download to
      // getApplicationDocumentsDirectory().
      // For this spec, we'll assume it's manually placed in an accessible directory
      // or we return a placeholder error if missing.
      expectedPath = '/sdcard/Download/gemma-3-4b-it-Q3_K_M.gguf';
    } else if (Platform.isIOS || Platform.isMacOS) {
      expectedPath = 'models/gemma-3-4b-it-Q3_K_M.gguf';
    } else if (Platform.isWindows) {
      // Hardcoded for the user's specific Windows location
      expectedPath = r'C:\Users\dejes\StudioProjects\ ADA-AI-ASSISTANT\gemma-3-4b-it-Q3_K_M.gguf';
    }

    return expectedPath;
  }

  Future<bool> initModel({required int computeDevice}) async {
    // 0 = CPU, 1 = GPU
    final modelPathStr = await _getModelPath();

    // Use Isolate if loading blocking IO for a long time
    return await Isolate.run(() {
      final modelPathPtr = modelPathStr.toNativeUtf8();
      try {
        // Warning: This requires the library functions to be accessible in the isolate.
        // It's safest to look up the function within the isolate.
        final libDir = Platform.isAndroid ? 'libllama.so' : 
                       (Platform.isWindows ? 'llama.dll' : 'libllama.dylib');
                       
        final lib = DynamicLibrary.open(libDir);
        final initModelFunc = lib.lookupFunction<NativeInitModel, DartInitModel>('init_model');
        
        return initModelFunc(modelPathPtr, computeDevice);
      } finally {
        calloc.free(modelPathPtr);
      }
    });
  }

  Future<String> generateText(String prompt) async {
    return await Isolate.run(() {
      final libDir = Platform.isAndroid ? 'libllama.so' : 
                     (Platform.isWindows ? 'llama.dll' : 'libllama.dylib');
                     
      final lib = DynamicLibrary.open(libDir);
      final generateTextFunc = lib.lookupFunction<NativeGenerateText, DartGenerateText>('generate_text');
      final freeTextFunc = lib.lookupFunction<NativeFreeText, DartFreeText>('free_text');

      final promptPtr = prompt.toNativeUtf8();
      try {
        final resultPtr = generateTextFunc(promptPtr);
        if (resultPtr == nullptr) {
          throw Exception('Failed to generate text (native returned null).');
        }

        final resultStr = resultPtr.toDartString();
        
        // Free the C string to avoid memory leak
        freeTextFunc(resultPtr);
        
        return resultStr;
      } finally {
        calloc.free(promptPtr);
      }
    });
  }
}
