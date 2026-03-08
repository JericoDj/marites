#include "llama_wrapper.h"
#include "llama.h"
#include "ggml-backend.h"

#include <string>
#include <vector>
#include <mutex>
#include <iostream>
#include <cstring>

static llama_model* g_model = nullptr;
static llama_context* g_ctx = nullptr;
static std::mutex g_mutex;

static int g_n_ctx = 2048;

EXPORT bool init_model(const char* model_path, int compute_device) {
    std::lock_guard<std::mutex> lock(g_mutex);
    
    if (g_model != nullptr) {
        llama_free(g_ctx);
        llama_model_free(g_model);
        g_ctx = nullptr;
        g_model = nullptr;
    }

    // Load backends explicitly for modern llama.cpp/ggml-backend
    ggml_backend_load_all();
    llama_backend_init();

    llama_model_params model_params = llama_model_default_params();
    // 0 = CPU, 1 = GPU
    if (compute_device == 0) {
        model_params.n_gpu_layers = 0; // CPU only
    } else {
        model_params.n_gpu_layers = 99; // Offload as much as possible to GPU
    }

    g_model = llama_model_load_from_file(model_path, model_params);
    if (!g_model) {
        return false;
    }

    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = g_n_ctx;
    ctx_params.n_threads = 8;
    ctx_params.n_threads_batch = 8;

    g_ctx = llama_init_from_model(g_model, ctx_params);
    if (!g_ctx) {
        llama_model_free(g_model);
        g_model = nullptr;
        return false;
    }

    return true;
}

EXPORT const char* generate_text(const char* prompt) {
    std::string response = "";
    generate_text_stream(prompt, [](const char* token) {
        // We'll collect it here for the legacy non-streaming version if needed,
        // but it's better to just implement it directly to avoid double-allocation.
    });
    // Actually, for simplicity and to avoid complexity in generate_text_stream, 
    // let's just implement the stream version and have generate_text use it.
    // However, since we need to return the full string, I'll copy the logic.
    
    std::lock_guard<std::mutex> lock(g_mutex);
    
    if (!g_model || !g_ctx) {
#ifdef _WIN32
        return _strdup("Error: Model not initialized.");
#else
        return strdup("Error: Model not initialized.");
#endif
    }

    const int n_predict = 128;
    std::string prompt_str(prompt);
    const llama_vocab * vocab = llama_model_get_vocab(g_model);

    std::vector<llama_token> tokens_list;
    tokens_list.resize(prompt_str.size() + 4);
    int n_tokens = llama_tokenize(vocab, prompt_str.c_str(), (int32_t)prompt_str.length(), tokens_list.data(), (int32_t)tokens_list.size(), true, true);
    if (n_tokens < 0) {
        tokens_list.resize(-n_tokens);
        n_tokens = llama_tokenize(vocab, prompt_str.c_str(), (int32_t)prompt_str.length(), tokens_list.data(), (int32_t)tokens_list.size(), true, true);
    }
    tokens_list.resize(n_tokens);

    llama_batch batch = llama_batch_get_one(tokens_list.data(), n_tokens);
    if (llama_decode(g_ctx, batch) != 0) {
#ifdef _WIN32
        return _strdup("Error: Failed to decode prompt.");
#else
        return strdup("Error: Failed to decode prompt.");
#endif
    }

    response = "";
    int n_cur = batch.n_tokens;
    int n_decode = 0;
    llama_sampler* smpl = llama_sampler_chain_init(llama_sampler_chain_default_params());
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(0.7f));
    llama_sampler_chain_add(smpl, llama_sampler_init_greedy());

    while (n_cur <= g_n_ctx && n_decode < n_predict) {
        llama_token id = llama_sampler_sample(smpl, g_ctx, -1);
        llama_sampler_accept(smpl, id);
        if (llama_vocab_is_eog(vocab, id)) break;

        char buf[128];
        int n = llama_token_to_piece(vocab, id, buf, sizeof(buf), 0, true);
        if (n < 0) break;
        response.append(buf, n);
        
        batch = llama_batch_get_one(&id, 1);
        if (llama_decode(g_ctx, batch)) break;
        n_cur += 1; n_decode += 1;
    }
    llama_sampler_free(smpl);

#ifdef _WIN32
    return _strdup(response.c_str());
#else
    return strdup(response.c_str());
#endif
}

EXPORT void generate_text_stream(const char* prompt, token_callback callback) {
    printf("DEBUG: generate_text_stream called with prompt: %s\n", prompt);
    std::lock_guard<std::mutex> lock(g_mutex);
    if (!g_model || !g_ctx) {
        printf("DEBUG: Model or context not initialized!\n");
        return;
    }
    if (!callback) {
        printf("DEBUG: Callback is null!\n");
        return;
    }

    const int n_predict = 512;
    std::string prompt_str(prompt);
    const llama_vocab * vocab = llama_model_get_vocab(g_model);

    std::vector<llama_token> tokens_list;
    tokens_list.resize(prompt_str.size() + 4);
    int n_tokens = llama_tokenize(vocab, prompt_str.c_str(), (int32_t)prompt_str.length(), tokens_list.data(), (int32_t)tokens_list.size(), true, true);
    if (n_tokens < 0) {
        tokens_list.resize(-n_tokens);
        n_tokens = llama_tokenize(vocab, prompt_str.c_str(), (int32_t)prompt_str.length(), tokens_list.data(), (int32_t)tokens_list.size(), true, true);
    }
    tokens_list.resize(n_tokens);

    printf("DEBUG: Prompt tokenized into %d tokens\n", (int)tokens_list.size());

    llama_batch batch = llama_batch_get_one(tokens_list.data(), n_tokens);
    if (llama_decode(g_ctx, batch) != 0) {
        printf("DEBUG: llama_decode failed on prompt\n");
        return;
    }

    printf("DEBUG: Starting generation loop...\n");

    int n_cur = batch.n_tokens;
    int n_decode = 0;
    llama_sampler* smpl = llama_sampler_chain_init(llama_sampler_chain_default_params());
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(0.7f));
    llama_sampler_chain_add(smpl, llama_sampler_init_greedy());

    while (n_cur <= g_n_ctx && n_decode < n_predict) {
        llama_token id = llama_sampler_sample(smpl, g_ctx, -1);
        llama_sampler_accept(smpl, id);
        if (llama_vocab_is_eog(vocab, id)) {
            printf("DEBUG: EOG reached\n");
            break;
        }

        char buf[256];
        int n = llama_token_to_piece(vocab, id, buf, sizeof(buf), 0, true);
        if (n >= 0) {
            std::string piece(buf, n);
            callback(piece.c_str());
        }
        
        batch = llama_batch_get_one(&id, 1);
        if (llama_decode(g_ctx, batch)) {
            printf("DEBUG: llama_decode failed during loop\n");
            break;
        }
        n_cur += 1; n_decode += 1;
    }
    llama_sampler_free(smpl);
    printf("DEBUG: generate_text_stream finished\n");
}

EXPORT void free_text(const char* text) {
    if (text) {
        free((void*)text);
    }
}
