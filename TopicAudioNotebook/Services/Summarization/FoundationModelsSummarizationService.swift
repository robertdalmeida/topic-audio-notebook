import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, macOS 26.0, *)
actor FoundationModelsSummarizationService: SummarizationService {
    nonisolated let providerType: SummarizationProvider = .foundationModels
    
    #if canImport(FoundationModels)
    private var session: LanguageModelSession?
    
    private func getSession() throws -> LanguageModelSession {
        guard SystemLanguageModel.default.isAvailable else {
            throw SummarizationError.processingFailed("Apple Intelligence is not available on this device")
        }
        
        if let existingSession = session {
            return existingSession
        }
        
        let newSession = LanguageModelSession()
        session = newSession
        return newSession
    }
    #endif
    
    func summarizeRecording(_ transcript: String) async throws -> SummaryResult {
        guard transcript.count >= 20 else {
            throw SummarizationError.textTooShort
        }
        
        #if canImport(FoundationModels)
        let session = try getSession()
        
        let prompt = """
        Summarize the following audio recording transcript. Provide:
        1. A concise summary paragraph (2-3 sentences)
        2. 3-5 key points as bullet points
        
        Format your response as:
        SUMMARY:
        [Your summary here]
        
        KEY POINTS:
        • [Point 1]
        • [Point 2]
        • [Point 3]
        
        Transcript:
        \(transcript)
        """
        
        let response = try await session.respond(to: prompt)
        return parseResponse(response.content)
        #else
        throw SummarizationError.processingFailed("Foundation Models not available")
        #endif
    }
    
    func consolidateTranscripts(_ transcripts: [String]) async throws -> SummaryResult {
        let combinedText = transcripts.joined(separator: "\n\n---\n\n")
        
        guard combinedText.count >= 20 else {
            throw SummarizationError.textTooShort
        }
        
        #if canImport(FoundationModels)
        let session = try getSession()
        
        let prompt = """
        Consolidate and summarize the following \(transcripts.count) audio recording transcripts into a unified summary. Provide:
        1. A comprehensive summary that captures the main themes across all recordings
        2. 5-10 key points covering the most important information
        
        Format your response as:
        SUMMARY:
        [Your consolidated summary here]
        
        KEY POINTS:
        • [Point 1]
        • [Point 2]
        • [Point 3]
        (continue as needed)
        
        Transcripts:
        \(combinedText)
        """
        
        let response = try await session.respond(to: prompt)
        return parseResponse(response.content)
        #else
        throw SummarizationError.processingFailed("Foundation Models not available")
        #endif
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

enum FoundationModelsAvailability {
    static var isAvailable: Bool {
        let available: Bool = {
            if #available(iOS 26.0, macOS 26.0, *) {
#if canImport(FoundationModels)
            return SystemLanguageModel.default.isAvailable
#else
            return false
#endif
            }
            return false
        }()
        print("FoundationModelsAvailability: available:\(available)")

        return available
    }
}
