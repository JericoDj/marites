# Build Instructions for Gemma Local AI

This project uses `llama.cpp` to run AI inference fully offline on your device, powered by Dart FFI.
Because the inference engine involves native C++ code, each platform needs to compile `libllama.so` (Android), `libllama.dylib` (iOS/macOS), or `llama.dll` (Windows) before the application can run properly.

## Common Requirements
1. **Flutter SDK** (stable channel).
2. The model file: **`gemma-3-4b-it-Q4_K_M.gguf`** (Size: ~2.5 GB). You can download it from an official GGUF repository like HuggingFace.

---

## 1. Android

**Prerequisites:** Android NDK (Install via Android Studio SDK Manager)

The Android configuration handles the compilation automatically via Gradle when you build or run the Flutter app.

1. **Place the model:** Copy the model file to a location accessible to the emulator or device. We've hardcoded the example path to `/sdcard/Download/gemma-3-4b-it-Q4_K_M.gguf`. You can adb push it:
   ```bash
   adb push path/to/gemma-3-4b-it-Q4_K_M.gguf /sdcard/Download/gemma-3-4b-it-Q4_K_M.gguf
   ```
2. **Run the app:**
   ```bash
   flutter run -d android
   ```
   *Gradle will automatically invoke CMake, download `llama.cpp`, compile it into `libllama.so` for `arm64-v8a`, and inject it into the app.*

---

## 2. iOS

**Prerequisites:** Xcode, CocoaPods, CMake (`brew install cmake`)

By default, Flutter doesn't compile raw CMake projects inside the iOS runner magically unless explicitly hooked. For iOS, we compile it and copy it as a Framework/Library.

1. **Compile Native Engine:**
   ```bash
   cd ios/Runner/llama
   cmake -B build -G Xcode -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES=arm64
   cmake --build build --config Release
   ```
2. **Embed Dylib:**
   - Open `ios/Runner.xcworkspace` in Xcode.
   - Go to the `Runner` target -> **General** -> **Frameworks, Libraries, and Embedded Content**.
   - Drag and drop `ios/Runner/llama/build/Release-iphoneos/libllama.dylib` into this section.
   - Set it to **"Embed & Sign"**.
3. **Place the Model:**
   - In Xcode, drag `gemma-3-4b-it-Q4_K_M.gguf` into the `Runner` folder inside Xcode. Create a group if needed and make sure it is checked for Target Membership `Runner`.
   - Update `llama_service.dart` paths if needed to load from `NSBundle.mainBundle`.
4. **Run the app:**
   ```bash
   flutter run -d ios
   ```

---

## 3. macOS

**Prerequisites:** Xcode, CMake (`brew install cmake`)

1. **Compile Native Engine:**
   ```bash
   cd macos/Runner/llama
   cmake -B build
   cmake --build build --config Release
   ```
2. **Embed Dylib:**
   - Open `macos/Runner.xcworkspace` in Xcode.
   - Go to the `Runner` target -> **General** -> **Frameworks, Libraries, and Embedded Content**.
   - Drag and drop `macos/Runner/llama/build/libllama.dylib` into this section.
   - Set it to **"Embed & Sign"**.
3. **Place the Model:**
   - Create a `models` folder where you run the binary (or drag into Xcode as bundled resources). The app expects `models/gemma-3-4b-it-Q4_K_M.gguf` relative to the current working directory or bundle path.
4. **Run the app:**
   ```bash
   flutter run -d macos
   ```

---

## 4. Windows

**Prerequisites:** Visual Studio 2022 (with Desktop development with C++), CMake.

1. **Compile Native Engine:**
   ```bash
   cd windows/runner/llama
   cmake -B build
   cmake --build build --config Release
   ```
2. **Embed DLL:**
   - Copy the resulting `llama.dll` from `windows/runner/llama/build/Release/llama.dll` to your output folder or `windows/runner/` so that it sits right next to `gemma_local_ai.exe`.
   *(Alternatively, copy it directly into `build/windows/x64/runner/Debug/` during development).*
3. **Place the Model:**
   - Create a `models` directory right next to the compiled `.exe` (or in root directory for `flutter run`) and place `gemma-3-4b-it-Q4_K_M.gguf` inside. 
   - Ensure the path is exactly `models/gemma-3-4b-it-Q4_K_M.gguf`.
4. **Run the app:**
   ```bash
   flutter run -d windows
   ```

---

## Troubleshooting FFI Errors
If you get `DynamicLibrary.open` errors (`Invalid argument(s): Failed to load dynamic library`), it means the OS launcher cannot find `libllama.so`, `libllama.dylib`, or `llama.dll`. 
- **Windows:** Put `llama.dll` exactly next to the `.exe`.
- **macOS/iOS:** Ensure the library is listed under "Frameworks, Libraries, and Embedded Content" and set to "Embed & Sign" in Xcode.
- **Android:** Ensure `build.gradle` is resolving CMake paths properly. Check Logcat.
