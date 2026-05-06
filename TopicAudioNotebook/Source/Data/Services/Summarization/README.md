# MLX Local Model Summarization

This document explains how local LLM models work with MLX in this app.

## How MLX Model Loading Works

### Model Configuration IDs

The `ModelConfiguration(id:)` parameter specifies a **Hugging Face model repository**:

```swift
// Phi-3.5 Mini (larger, ~2.5GB)
ModelConfiguration(id: "mlx-community/Phi-3.5-mini-instruct-4bit")

// Llama 3.2 1B (smaller, ~700MB)
ModelConfiguration(id: "mlx-community/Llama-3.2-1B-Instruct-4bit")
```

These IDs point to pre-converted MLX-format models hosted on Hugging Face under the `mlx-community` organization.

### Model Download & Storage

**Models are NOT bundled with the app binary.** Instead:

1. **First Use Download**: When `LLMModelFactory.shared.loadContainer()` is called, the MLX framework:
   - Checks if the model exists in the local cache
   - If not, downloads it from Hugging Face to the device
   - Stores it in the app's cache directory (typically `~/Library/Caches/huggingface/`)

2. **Subsequent Uses**: The model is loaded directly from the local cache—no network required.

3. **Cache Location**: Models are stored in:
   - **macOS**: `~/Library/Caches/huggingface/hub/models--mlx-community--<model-name>/`
   - **iOS**: App's sandboxed cache directory

### Model Sizes (4-bit Quantized)

| Model | Size on Disk | RAM Usage |
|-------|-------------|-----------|
| Phi-3.5-mini-instruct-4bit | ~2.5 GB | ~3-4 GB |
| Llama-3.2-1B-Instruct-4bit | ~700 MB | ~1-1.5 GB |

## Lazy Loading Strategy

Both MLX services implement lazy loading to prevent memory pressure:

```swift
private func loadModelIfNeeded() async throws {
    guard modelContainer == nil, !_isLoading else { return }
    // Only loads when actually needed
}
```

**Key behaviors:**
- Model is NOT loaded at app startup
- Model loads only when `summarizeRecording()` or `consolidateTranscripts()` is called
- Once loaded, the model stays in memory for subsequent calls
- The `unloadModel()` method can explicitly release memory

## GPU Memory Management

To prevent iOS/macOS from killing the app due to excessive memory usage:

```swift
// Set BEFORE loading the model
MLX.GPU.set(cacheLimit: 1_500_000_000)  // 1.5 GB limit
```

This tells MLX to limit GPU memory cache to ~1.5GB. The Llama 3.2 1B model fits comfortably within this limit.

### Why This Matters

- **iOS Memory Limits**: iOS aggressively terminates apps using too much memory
- **Jetsam**: The system daemon that kills memory-hungry apps
- **Cache Limit**: Prevents runaway GPU memory allocation

## Model Selection Guide

| Use Case | Recommended Model |
|----------|-------------------|
| Quick summaries, limited RAM | Llama-3.2-1B (mlxLlama) |
| Higher quality, more RAM available | Phi-3.5-mini (mlxPhi) |
| Offline-only, no download | On-Device (NaturalLanguage) |
| Best quality, online | OpenAI |

## Adding New Models

To add a new MLX model:

1. Find a 4-bit quantized model on `mlx-community` Hugging Face
2. Create a new service file (e.g., `MLXNewModelService.swift`)
3. Add the provider case to `SummarizationProvider` enum
4. Register in `SummarizationServiceFactory`
5. Use appropriate chat template for the model's expected format

### Chat Templates

Different models expect different prompt formats:

**Phi-3.5** (simple):
```
You are a helpful assistant...
Transcript: ...
```

**Llama 3.2** (structured):
```
<|begin_of_text|><|start_header_id|>system<|end_header_id|>
You are a helpful assistant...<|eot_id|><|start_header_id|>user<|end_header_id|>
Transcript: ...<|eot_id|><|start_header_id|>assistant<|end_header_id|>
```

## Troubleshooting

### Model Download Fails
- Check network connectivity
- Verify Hugging Face is accessible
- Check available disk space

### App Killed by System
- Reduce `cacheLimit` value
- Use smaller model (Llama 3.2 1B)
- Call `unloadModel()` when not in use

### Slow First Load
- First load downloads the model (~700MB-2.5GB)
- Subsequent loads are from cache (much faster)
- Show progress indicator during download
