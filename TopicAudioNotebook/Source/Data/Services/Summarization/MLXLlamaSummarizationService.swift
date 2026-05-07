import Foundation
#if canImport(MLXLLM)
import MLXLLM
import MLXLMCommon
import MLX
#endif

actor MLXLlamaSummarizationService: LoadableSummarizationService {
    nonisolated let providerType: SummarizationProvider = .mlxLlama
    
    #if canImport(MLXLLM)
    private var modelContainer: ModelContainer?
    private var _isLoading = false
    private var _loadingProgress: Double = 0.0
    private static let gpuCacheLimit: Int = 1_500_000_000
    
    var isLoaded: Bool {
        modelContainer != nil
    }
    
    var isLoading: Bool {
        _isLoading
    }
    
    var loadingProgress: Double {
        _loadingProgress
    }
    
    func preloadModel(progressHandler: (@Sendable (Double) -> Void)? = nil) async throws {
        try await loadModelIfNeeded(progressHandler: progressHandler)
    }
    
    func unloadModel() {
        modelContainer = nil
        MLX.GPU.clearCache()
    }
    
    private func loadModelIfNeeded(progressHandler: (@Sendable (Double) -> Void)? = nil) async throws {
        guard modelContainer == nil, !_isLoading else { return }
        
        _isLoading = true
        _loadingProgress = 0.0
        defer { _isLoading = false }
        
        MLX.GPU.set(cacheLimit: Self.gpuCacheLimit)
        
        let modelConfig = ModelConfiguration(id: "mlx-community/Llama-3.2-1B-Instruct-4bit")
        
        modelContainer = try await LLMModelFactory.shared.loadContainer(configuration: modelConfig) { [self] progress in
            let fraction = progress.fractionCompleted
            Task { @MainActor in
                await self.updateProgress(fraction)
            }
            progressHandler?(fraction)
            print("Loading Llama-3.2-1B model: \(Int(fraction * 100))%")
        }
        _loadingProgress = 1.0
    }
    
    private func updateProgress(_ progress: Double) {
        _loadingProgress = progress
    }
    #else
    var isLoaded: Bool { false }
    var isLoading: Bool { false }
    var loadingProgress: Double { 0.0 }
    func preloadModel(progressHandler: (@Sendable (Double) -> Void)? = nil) async throws {
        throw SummarizationError.processingFailed("MLX framework not available")
    }
    func unloadModel() {}
    #endif
    
    func generateKeyPoints(_ transcripts: [String]) async throws -> [String] {
        let combinedText = transcripts.joined(separator: "\n\n---\n\n")
        
        guard combinedText.count >= 20 else {
            throw SummarizationError.textTooShort
        }
        
        #if canImport(MLXLLM)
        try await loadModelIfNeeded()
        
        guard let container = modelContainer else {
            throw SummarizationError.processingFailed("Failed to load MLX Llama model")
        }
        
        let prompt = buildKeyPointsPrompt(combinedText: combinedText, count: transcripts.count)
        let response = try await generate(prompt: prompt, container: container)
        return parseKeyPoints(response)
        #else
        throw SummarizationError.processingFailed("MLX framework not available")
        #endif
    }
    
    func generateFullSummary(_ transcripts: [String]) async throws -> String {
        let combinedText = transcripts.joined(separator: "\n\n---\n\n")
        
        guard combinedText.count >= 20 else {
            throw SummarizationError.textTooShort
        }
        
        #if canImport(MLXLLM)
        try await loadModelIfNeeded()
        
        guard let container = modelContainer else {
            throw SummarizationError.processingFailed("Failed to load MLX Llama model")
        }
        
        let prompt = buildFullSummaryPrompt(combinedText: combinedText, count: transcripts.count)
        let response = try await generate(prompt: prompt, container: container)
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
        #else
        throw SummarizationError.processingFailed("MLX framework not available")
        #endif
    }
    
    #if canImport(MLXLLM)
    private func generate(prompt: String, container: ModelContainer) async throws -> String {
        let input = UserInput(prompt: prompt)
        let parameters = GenerateParameters(temperature: 0.7)
        
        let result = try await container.perform { context in
            let lmInput = try await context.processor.prepare(input: input)
            return try MLXLMCommon.generate(
                input: lmInput,
                parameters: parameters,
                context: context
            ) { tokens in
                return tokens.count < 1024 ? .more : .stop
            }
        }
        
        return result.output
    }
    #endif
    
    private func buildKeyPointsPrompt(combinedText: String, count: Int) -> String {
        SummarizationPrompts.llamaKeyPointsPrompt(transcript: combinedText, maxLength: 4000)
    }
    
    private func buildFullSummaryPrompt(combinedText: String, count: Int) -> String {
        SummarizationPrompts.llamaSummaryPrompt(transcript: combinedText, maxLength: 5000)
    }
    
    private func parseKeyPoints(_ response: String) -> [String] {
        var points: [String] = []
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            var pointText = line.trimmingCharacters(in: .whitespaces)
            
            if pointText.hasPrefix("•") || pointText.hasPrefix("-") || pointText.hasPrefix("*") {
                pointText = String(pointText.dropFirst()).trimmingCharacters(in: .whitespaces)
            }
            if pointText.first?.isNumber == true, let dotIndex = pointText.firstIndex(of: ".") {
                pointText = String(pointText[pointText.index(after: dotIndex)...]).trimmingCharacters(in: .whitespaces)
            }
            if !pointText.isEmpty {
                points.append(pointText)
            }
        }
        
        return points
    }
}
