#ifndef LLAMA_WRAPPER_H
#define LLAMA_WRAPPER_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

// Returns true if successful. compute_device: 0 = CPU, 1 = GPU/Metal/Vulkan
EXPORT bool init_model(const char* model_path, int compute_device);

// Returns generated text. Must be freed by free_text!
EXPORT const char* generate_text(const char* prompt);

// Prevents memory leaks by freeing the allocated string from C++ side
EXPORT void free_text(const char* text);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_WRAPPER_H
