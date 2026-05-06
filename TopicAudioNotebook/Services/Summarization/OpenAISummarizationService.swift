import Foundation

actor OpenAISummarizationService: SummarizationService {
    nonisolated let providerType: SummarizationProvider = .openAI
    
    private var apiKey: String? {
        UserDefaults.standard.string(forKey: "OpenAI_API_Key")
    }
    
    func summarizeRecording(_ transcript: String) async throws -> SummaryResult {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw SummarizationError.noAPIKey
        }
        
        let systemPrompt = """
        You are an expert at summarizing audio transcripts. Analyze the transcript and provide:
        1. A concise summary paragraph (2-4 sentences)
        2. A list of 3-7 key points as bullet points
        
        Format your response as JSON with this structure:
        {
            "summary": "Your summary paragraph here",
            "points": ["Point 1", "Point 2", "Point 3"]
        }
        
        Only output valid JSON, no other text.
        """
        
        let response = try await callOpenAIChat(
            systemPrompt: systemPrompt,
            userMessage: "Summarize this transcript:\n\n\(transcript)",
            apiKey: apiKey
        )
        
        return parseJSONResponse(response)
    }
    
    func consolidateTranscripts(_ transcripts: [String]) async throws -> SummaryResult {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw SummarizationError.noAPIKey
        }
        
        let combinedTranscripts = transcripts.enumerated().map { index, transcript in
            "Recording \(index + 1):\n\(transcript)"
        }.joined(separator: "\n\n---\n\n")
        
        let systemPrompt = """
        You are an expert at synthesizing multiple audio transcripts into a cohesive summary.
        Analyze all transcripts and provide:
        1. A comprehensive summary paragraph combining all key information
        2. A list of 5-10 key points extracted from all recordings, removing redundancies
        
        Format your response as JSON with this structure:
        {
            "summary": "Your comprehensive summary here",
            "points": ["Key point 1", "Key point 2", "Key point 3"]
        }
        
        Only output valid JSON, no other text.
        """
        
        let response = try await callOpenAIChat(
            systemPrompt: systemPrompt,
            userMessage: "Consolidate these transcripts:\n\n\(combinedTranscripts)",
            apiKey: apiKey
        )
        
        return parseJSONResponse(response)
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
    
    private func parseJSONResponse(_ response: String) -> SummaryResult {
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let summary = json["summary"] as? String,
              let points = json["points"] as? [String] else {
            let lines = response.components(separatedBy: "\n").filter { !$0.isEmpty }
            return SummaryResult(summary: response, points: Array(lines.prefix(5)))
        }
        
        return SummaryResult(summary: summary, points: points)
    }
}
