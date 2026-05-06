import Foundation

actor AIService {
    static let shared = AIService()
    
    private var apiKey: String? {
        UserDefaults.standard.string(forKey: "OpenAI_API_Key")
    }
    
    private init() {}
    
    struct RecordingSummaryResult {
        let summary: String
        let points: [String]
    }
    
    func summarizeRecording(_ transcript: String) async throws -> RecordingSummaryResult {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIServiceError.noAPIKey
        }
        
        return try await callOpenAIForRecordingSummary(transcript: transcript, apiKey: apiKey)
    }
    
    func consolidateTranscripts(_ transcripts: [String]) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return generateLocalSummary(transcripts)
        }
        
        return try await callOpenAIForConsolidation(transcripts: transcripts, apiKey: apiKey)
    }
    
    func consolidateTranscriptsWithPoints(_ transcripts: [String]) async throws -> (summary: String, points: [String]) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            let summary = generateLocalSummary(transcripts)
            return (summary, [])
        }
        
        return try await callOpenAIForConsolidationWithPoints(transcripts: transcripts, apiKey: apiKey)
    }
    
    private func callOpenAIForRecordingSummary(transcript: String, apiKey: String) async throws -> RecordingSummaryResult {
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
        
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let summary = json["summary"] as? String,
              let points = json["points"] as? [String] else {
            let lines = response.components(separatedBy: "\n").filter { !$0.isEmpty }
            return RecordingSummaryResult(summary: response, points: lines.prefix(5).map { String($0) })
        }
        
        return RecordingSummaryResult(summary: summary, points: points)
    }
    
    private func callOpenAIForConsolidation(transcripts: [String], apiKey: String) async throws -> String {
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
    
    private func callOpenAIForConsolidationWithPoints(transcripts: [String], apiKey: String) async throws -> (summary: String, points: [String]) {
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
        
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let summary = json["summary"] as? String,
              let points = json["points"] as? [String] else {
            return (response, [])
        }
        
        return (summary, points)
    }
    
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
