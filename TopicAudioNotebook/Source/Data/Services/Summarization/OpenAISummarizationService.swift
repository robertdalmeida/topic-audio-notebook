import Foundation

actor OpenAISummarizationService: SummarizationService {
    nonisolated let providerType: SummarizationProvider = .openAI
    
    private var apiKey: String? {
        UserDefaults.standard.string(forKey: "OpenAI_API_Key")
    }
    
    func generateKeyPoints(_ transcripts: [String]) async throws -> [String] {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw SummarizationError.noAPIKey
        }
        
        let combinedTranscripts = transcripts.enumerated().map { index, transcript in
            "Recording \(index + 1):\n\(transcript)"
        }.joined(separator: "\n\n---\n\n")
        
        let systemPrompt = """
        Analyze all transcripts and extract the key points, removing redundancies.
        
        Format your response as JSON with this structure:
        {
            "points": ["Key point 1", "Key point 2", "Key point 3"]
        }
        
        Only output valid JSON, no other text.
        """
        
        let response = try await callOpenAIChat(
            systemPrompt: systemPrompt,
            userMessage: "Extract key points from these transcripts:\n\n\(combinedTranscripts)",
            apiKey: apiKey
        )
        
        return parseKeyPointsResponse(response)
    }
    
    func generateFullSummary(_ transcripts: [String]) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw SummarizationError.noAPIKey
        }
        
        let combinedTranscripts = transcripts.enumerated().map { index, transcript in
            "Recording \(index + 1):\n\(transcript)"
        }.joined(separator: "\n\n---\n\n")
        
        let systemPrompt = """
        Create a well-structured, detailed summary that captures the main themes, important details, and conclusions.
        Write in clear paragraphs.
        
        Format your response as JSON with this structure:
        {
            "summary": "Your comprehensive summary here"
        }
        
        Only output valid JSON, no other text.
        """
        
        let response = try await callOpenAIChat(
            systemPrompt: systemPrompt,
            userMessage: "Create a comprehensive summary of these transcripts:\n\n\(combinedTranscripts)",
            apiKey: apiKey
        )
        
        return parseSummaryResponse(response)
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
