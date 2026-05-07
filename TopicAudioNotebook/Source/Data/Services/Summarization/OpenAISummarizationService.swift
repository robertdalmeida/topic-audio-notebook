import Foundation

actor OpenAISummarizationService: SummarizationService {
    nonisolated let providerType: SummarizationProvider = .openAI
    
    private var apiKey: String? {
        UserDefaults.standard.string(forKey: "OpenAI_API_Key")
    }
    
    func generateKeyPoints(_ transcripts: [String]) async throws -> [String] {
        log.info("🌐 [OpenAI] Generating key points from \(transcripts.count) transcript(s)", category: .summarization)
        
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            log.error("🌐 [OpenAI] No API key configured", category: .summarization)
            throw SummarizationError.noAPIKey
        }
        
        let combinedTranscripts = transcripts.enumerated().map { index, transcript in
            "Recording \(index + 1):\n\(transcript)"
        }.joined(separator: "\n\n---\n\n")
        
        let response = try await callOpenAIChat(
            systemPrompt: SummarizationPrompts.keyPointsJSONSystemPrompt(),
            userMessage: "Extract key points from this transcript:\n\n\(combinedTranscripts)",
            apiKey: apiKey
        )
        
        let keyPoints = parseKeyPointsResponse(response)
        log.info("🌐 [OpenAI] Generated \(keyPoints.count) key points", category: .summarization)
        return keyPoints
    }
    
    func generateFullSummary(_ transcripts: [String]) async throws -> String {
        log.info("🌐 [OpenAI] Generating full summary from \(transcripts.count) transcript(s)", category: .summarization)
        
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            log.error("🌐 [OpenAI] No API key configured", category: .summarization)
            throw SummarizationError.noAPIKey
        }
        
        let combinedTranscripts = transcripts.enumerated().map { index, transcript in
            "Recording \(index + 1):\n\(transcript)"
        }.joined(separator: "\n\n---\n\n")
        
        let response = try await callOpenAIChat(
            systemPrompt: SummarizationPrompts.summaryJSONSystemPrompt(),
            userMessage: "Summarize this transcript:\n\n\(combinedTranscripts)",
            apiKey: apiKey
        )
        
        let summary = parseSummaryResponse(response)
        log.info("🌐 [OpenAI] Summary generated, length: \(summary.count) chars", category: .summarization)
        return summary
    }
    
    // MARK: - Private Methods
    
    private func callOpenAIChat(systemPrompt: String, userMessage: String, apiKey: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ],
            "temperature": 0.7,
            "max_tokens": 2000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SummarizationError.requestFailed("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw SummarizationError.requestFailed(message)
            }
            throw SummarizationError.requestFailed("HTTP \(httpResponse.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw SummarizationError.invalidResponse
        }
        
        return content
    }
    
    private func parseKeyPointsResponse(_ response: String) -> [String] {
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let points = json["points"] as? [String] else {
            let lines = response.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            return Array(lines.prefix(10))
        }
        return points
    }
    
    private func parseSummaryResponse(_ response: String) -> String {
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let summary = json["summary"] as? String else {
            return response.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return summary
    }
}
