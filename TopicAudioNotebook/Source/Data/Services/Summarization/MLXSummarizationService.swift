import Foundation
#if canImport(MLXLLM)
import MLXLLM
import MLXLMCommon
#endif

actor MLXSummarizationService: LoadableSummarizationService {
    nonisolated let providerType: SummarizationProvider = .mlxPhi
    
    #if canImport(MLXLLM)
    private var modelContainer: ModelContainer?
    private var _isLoading = false
    private var _loadingProgress: Double = 0.0
    
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
    
    private func loadModelIfNeeded(progressHandler: (@Sendable (Double) -> Void)? = nil) async throws {
        guard modelContainer == nil, !_isLoading else { return }
        
        _isLoading = true
        _loadingProgress = 0.0
        defer { _isLoading = false }
        
        let modelConfig = ModelConfiguration(id: "mlx-community/Phi-3.5-mini-instruct-4bit")
        
        modelContainer = try await LLMModelFactory.shared.loadContainer(configuration: modelConfig) { [self] progress in
            let fraction = progress.fractionCompleted
            Task { @MainActor in
                await self.updateProgress(fraction)
            }
            progressHandler?(fraction)
            print("Loading Phi-3.5 model: \(Int(fraction * 100))%")
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
    #endif
    
    func summarizeRecording(_ transcript: String) async throws -> SummaryResult {
        guard transcript.count >= 20 else {
            throw SummarizationError.textTooShort
        }
        
        #if canImport(MLXLLM)
        try await loadModelIfNeeded()
        
        guard let container = modelContainer else {
            throw SummarizationError.processingFailed("Failed to load MLX model")
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
            throw SummarizationError.processingFailed("Failed to load MLX model")
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
        
        var outputText = ""
        
        let result = try await container.perform { context in
            let lmInput = try await context.processor.prepare(input: input)
            return try MLXLMCommon.generate(
                input: lmInput,
                parameters: parameters,
                context: context
            ) { tokens in
                let outputText = context.tokenizer.decode(tokens: tokens)
                return tokens.count < 1024 ? .more : .stop
            }
        }
        
        return result.output
    }
    #endif
    
    private func buildRecordingPrompt(transcript: String) -> String {
        """
        You are a helpful assistant that summarizes audio recording transcripts.
        
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
        \(transcript.prefix(4000))
        """
    }
    
    private func buildConsolidationPrompt(transcripts: [String], combinedText: String) -> String {
        """
        You are a helpful assistant that consolidates multiple audio recording transcripts.
        
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
        \(combinedText.prefix(6000))
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

enum MLXAvailability {
    static var isAvailable: Bool {
        #if canImport(MLXLLM)
        return true
        #else
        return false
        #endif
    }
}
