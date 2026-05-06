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
    
    func summarizeRecording(_ transcript: String) async throws -> SummaryResult {
        guard transcript.count >= 20 else {
            throw SummarizationError.textTooShort
        }
        
        #if canImport(MLXLLM)
        try await loadModelIfNeeded()
        
        guard let container = modelContainer else {
            throw SummarizationError.processingFailed("Failed to load MLX Llama model")
        }
        
        let prompt = buildRecordingPrompt(transcript: transcript)
        let response = try await generate(prompt: prompt, container: container)
        return parseResponse(response)
        #else
        throw SummarizationError.processingFailed("MLX framework not available")
        #endif
    }
    
    func consolidateTranscripts(_ transcripts: [String]) async throws -> SummaryResult {
        let combinedText = transcripts.joined(separator: "\n\n---\n\n")
        
        guard combinedText.count >= 20 else {
            throw SummarizationError.textTooShort
        }
        
        #if canImport(MLXLLM)
        try await loadModelIfNeeded()
        
        guard let container = modelContainer else {
            throw SummarizationError.processingFailed("Failed to load MLX Llama model")
        }
        
        let prompt = buildConsolidationPrompt(transcripts: transcripts, combinedText: combinedText)
        let response = try await generate(prompt: prompt, container: container)
        return parseResponse(response)
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
    
    private func buildRecordingPrompt(transcript: String) -> String {
        """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>
        You are a helpful assistant that summarizes audio recording transcripts concisely.<|eot_id|><|start_header_id|>user<|end_header_id|>
        Summarize the following transcript. Provide:
        1. A concise summary paragraph (2-3 sentences)
        2. 3-5 key points as bullet points
        
        Format your response exactly as:
        SUMMARY:
        [Your summary here]
        
        KEY POINTS:
        • [Point 1]
        • [Point 2]
        • [Point 3]
        
        Transcript:
        \(transcript.prefix(3000))<|eot_id|><|start_header_id|>assistant<|end_header_id|>
        """
    }
    
    private func buildConsolidationPrompt(transcripts: [String], combinedText: String) -> String {
        """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>
        You are a helpful assistant that consolidates multiple audio recording transcripts.<|eot_id|><|start_header_id|>user<|end_header_id|>
        Consolidate and summarize the following \(transcripts.count) transcripts into a unified summary. Provide:
        1. A comprehensive summary that captures the main themes
        2. 5-10 key points covering the most important information
        
        Format your response exactly as:
        SUMMARY:
        [Your consolidated summary here]
        
        KEY POINTS:
        • [Point 1]
        • [Point 2]
        • [Point 3]
        (continue as needed)
        
        Transcripts:
        \(combinedText.prefix(4000))<|eot_id|><|start_header_id|>assistant<|end_header_id|>
        """
    }
    
    private func parseResponse(_ response: String) -> SummaryResult {
        var summary = ""
        var points: [String] = []
        
        let lines = response.components(separatedBy: .newlines)
        var inSummarySection = false
        var inPointsSection = false
        var summaryLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.uppercased().hasPrefix("SUMMARY:") {
                inSummarySection = true
                inPointsSection = false
                let afterPrefix = trimmed.dropFirst("SUMMARY:".count).trimmingCharacters(in: .whitespaces)
                if !afterPrefix.isEmpty {
                    summaryLines.append(afterPrefix)
                }
                continue
            }
            
            if trimmed.uppercased().hasPrefix("KEY POINTS:") || trimmed.uppercased().hasPrefix("KEYPOINTS:") {
                inSummarySection = false
                inPointsSection = true
                continue
            }
            
            if inSummarySection && !trimmed.isEmpty {
                summaryLines.append(trimmed)
            }
            
            if inPointsSection {
                var pointText = trimmed
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
        }
        
        summary = summaryLines.joined(separator: " ")
        
        if summary.isEmpty {
            summary = response.prefix(500).trimmingCharacters(in: .whitespacesAndNewlines)
            if response.count > 500 {
                summary += "..."
            }
        }
        
        return SummaryResult(summary: summary, points: points)
    }
}
