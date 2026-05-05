import Foundation

actor AIService {
    static let shared = AIService()
    
    private var apiKey: String? {
        UserDefaults.standard.string(forKey: "OpenAI_API_Key")
    }
    
    private init() {}
    
    func consolidateTranscripts(_ transcripts: [String]) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return generateLocalSummary(transcripts)
        }
        
        return try await callOpenAI(transcripts: transcripts, apiKey: apiKey)
    }
    
    private func callOpenAI(transcripts: [String], apiKey: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let combinedTranscripts = transcripts.enumerated().map { index, transcript in
            "Recording \(index + 1):\n\(transcript)"
        }.joined(separator: "\n\n---\n\n")
        
        let systemPrompt = """
        You are an expert at synthesizing multiple audio transcripts into a cohesive summary.
        Your task is to:
        1. Identify the main themes and key points across all recordings
        2. Remove redundancies and repetitive information
        3. Organize the content into a clear, structured overview
        4. Preserve important details and nuances
        5. Use clear headings and bullet points for readability
        
        Format the output with:
        - A brief executive summary (2-3 sentences)
        - Key themes/topics identified
        - Main points organized by theme
        - Any action items or conclusions mentioned
        """
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Please consolidate these transcripts into a unified summary:\n\n\(combinedTranscripts)"]
            ],
            "temperature": 0.7,
            "max_tokens": 2000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.requestFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }
        
        return content
    }
    
    private func generateLocalSummary(_ transcripts: [String]) -> String {
        let combinedText = transcripts.joined(separator: " ")
        let words = combinedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        var summary = """
        # Consolidated Summary
        
        ## Overview
        This summary combines \(transcripts.count) recording(s) with approximately \(words.count) words total.
        
        ## Transcripts
        
        """
        
        for (index, transcript) in transcripts.enumerated() {
            let preview = String(transcript.prefix(500))
            summary += """
            ### Recording \(index + 1)
            \(preview)\(transcript.count > 500 ? "..." : "")
            
            """
        }
        
        summary += """
        
        ---
        *Note: For AI-powered intelligent summarization, please configure your OpenAI API key in Settings.*
        """
        
        return summary
    }
    
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "OpenAI_API_Key")
    }
    
    func hasAPIKey() -> Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty
    }
}

enum AIServiceError: LocalizedError {
    case noAPIKey
    case requestFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured"
        case .requestFailed:
            return "API request failed"
        case .invalidResponse:
            return "Invalid response from API"
        }
    }
}
