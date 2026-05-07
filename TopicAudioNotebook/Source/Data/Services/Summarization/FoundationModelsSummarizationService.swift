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
    
    func generateKeyPoints(_ transcripts: [String]) async throws -> [String] {
        let combinedText = transcripts.joined(separator: "\n\n---\n\n")
        
        guard combinedText.count >= 20 else {
            throw SummarizationError.textTooShort
        }
        
        #if canImport(FoundationModels)
        let session = try getSession()
        
        let prompt = SummarizationPrompts.keyPointsUserPrompt(transcript: combinedText)
        
        let response = try await session.respond(to: prompt)
        return parseKeyPoints(response.content)
        #else
        throw SummarizationError.processingFailed("Foundation Models not available")
        #endif
    }
    
    func generateFullSummary(_ transcripts: [String]) async throws -> String {
        let combinedText = transcripts.joined(separator: "\n\n---\n\n")
        
        guard combinedText.count >= 20 else {
            throw SummarizationError.textTooShort
        }
        
        #if canImport(FoundationModels)
        let session = try getSession()
        
        let prompt = SummarizationPrompts.summaryUserPrompt(transcript: combinedText)
        
        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        #else
        throw SummarizationError.processingFailed("Foundation Models not available")
        #endif
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
