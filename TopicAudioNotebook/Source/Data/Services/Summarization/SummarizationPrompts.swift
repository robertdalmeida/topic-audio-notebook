import Foundation

// MARK: - Prompt Builder Protocol

protocol PromptBuilder {
    func buildKeyPointsPrompt(transcript: String) -> String
    func buildSummaryPrompt(transcript: String) -> String
}

// MARK: - Core Prompt Templates

enum PromptTemplates {
    
    // MARK: - System Instructions
    
    static let keyPointsSystemInstruction = "Extract key points ONLY from what is explicitly stated. Do not add interpretations or assumptions."
    
    static let summarySystemInstruction = "Rewrite this transcript as a clear summary using complete sentences."

    // MARK: - Rules
    
    static let keyPointsRules = """
        - Only extract what was actually said
        - Keep each point brief and factual
        - Do not add context or interpretation
        - Use the speaker's own words when possible
        - Format as bullet points: • [Point]
        """
    
    static let summaryRules = """
        - Only include information that was explicitly stated
        - Convert fragmented speech into proper sentences
        - Do not add context, interpretations, or assumptions
        - Keep the original meaning and intent
        - Be concise and to the point
        """
    
}

// MARK: - MLX Llama Prompt Builder
/// Used by: MLXLlamaSummarizationService
/// Format: Llama chat template with system/user/assistant tags

struct LlamaPromptBuilder: PromptBuilder {
    let maxKeyPointsLength: Int
    let maxSummaryLength: Int
    
    init(maxKeyPointsLength: Int = 4000, maxSummaryLength: Int = 5000) {
        self.maxKeyPointsLength = maxKeyPointsLength
        self.maxSummaryLength = maxSummaryLength
    }
    
    func buildKeyPointsPrompt(transcript: String) -> String {
        """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>
        \(PromptTemplates.keyPointsSystemInstruction)<|eot_id|><|start_header_id|>user<|end_header_id|>
        
        Rules:
        \(PromptTemplates.keyPointsRules)
                
        Transcript:
        \(String(transcript.prefix(maxKeyPointsLength)))<|eot_id|><|start_header_id|>assistant<|end_header_id|>
        """
    }
    
    func buildSummaryPrompt(transcript: String) -> String {
        """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>
        \(PromptTemplates.summarySystemInstruction)<|eot_id|><|start_header_id|>user<|end_header_id|>
        \(PromptTemplates.summarySystemInstruction)
        
        Rules:
        \(PromptTemplates.summaryRules)
        
        Transcript:
        \(String(transcript.prefix(maxSummaryLength)))<|eot_id|><|start_header_id|>assistant<|end_header_id|>
        """
    }
}

// MARK: - Plain Text Prompt Builder
/// Used by: MLXSummarizationService, FoundationModelsSummarizationService
/// Format: Simple plain text prompts

struct PlainTextPromptBuilder: PromptBuilder {
    let maxLength: Int
    
    init(maxLength: Int = 6000) {
        self.maxLength = maxLength
    }
    
    func buildKeyPointsPrompt(transcript: String) -> String {
        """
        \(PromptTemplates.keyPointsSystemInstruction)
        
        Rules:
        \(PromptTemplates.keyPointsRules)
        
        Transcript:
        \(String(transcript.prefix(maxLength)))
        """
    }
    
    func buildSummaryPrompt(transcript: String) -> String {
        """
        \(PromptTemplates.summarySystemInstruction)
        
        Rules:
        \(PromptTemplates.summaryRules)
        
        Transcript:
        \(String(transcript.prefix(maxLength)))
        """
    }
}

// MARK: - OpenAI JSON Prompt Builder
/// Used by: OpenAISummarizationService
/// Format: System prompts that request JSON output

struct OpenAIPromptBuilder: PromptBuilder {
    
    func buildKeyPointsPrompt(transcript: String) -> String {
        """
        \(PromptTemplates.keyPointsSystemInstruction)
        
        Rules:
        \(PromptTemplates.keyPointsRules)
        
        Format your response as JSON:
        {
            "points": ["Point 1", "Point 2"]
        }
        
        Only output valid JSON.
        """
    }
    
    func buildSummaryPrompt(transcript: String) -> String {
        """
        \(PromptTemplates.summarySystemInstruction)
        
        Rules:
        \(PromptTemplates.summaryRules)
        
        Format your response as JSON:
        {
            "summary": "Your summary here"
        }
        
        Only output valid JSON.
        """
    }
}

// MARK: - Convenience Accessors

enum SummarizationPrompts {
    
    /// For MLXLlamaSummarizationService
    static let llama = LlamaPromptBuilder()
    
    /// For MLXSummarizationService and FoundationModelsSummarizationService
    static let plainText = PlainTextPromptBuilder()
    
    /// For OpenAISummarizationService
    static let openAI = OpenAIPromptBuilder()
    
    // MARK: - Legacy Compatibility
    
    static func llamaKeyPointsPrompt(transcript: String, maxLength: Int = 4000) -> String {
        LlamaPromptBuilder(maxKeyPointsLength: maxLength).buildKeyPointsPrompt(transcript: transcript)
    }
    
    static func llamaSummaryPrompt(transcript: String, maxLength: Int = 5000) -> String {
        LlamaPromptBuilder(maxSummaryLength: maxLength).buildSummaryPrompt(transcript: transcript)
    }
    
    static func keyPointsUserPrompt(transcript: String, maxLength: Int = 6000) -> String {
        PlainTextPromptBuilder(maxLength: maxLength).buildKeyPointsPrompt(transcript: transcript)
    }
    
    static func summaryUserPrompt(transcript: String, maxLength: Int = 6000) -> String {
        PlainTextPromptBuilder(maxLength: maxLength).buildSummaryPrompt(transcript: transcript)
    }
    
    static func keyPointsJSONSystemPrompt() -> String {
        OpenAIPromptBuilder().buildKeyPointsPrompt(transcript: "")
    }
    
    static func summaryJSONSystemPrompt() -> String {
        OpenAIPromptBuilder().buildSummaryPrompt(transcript: "")
    }
}
