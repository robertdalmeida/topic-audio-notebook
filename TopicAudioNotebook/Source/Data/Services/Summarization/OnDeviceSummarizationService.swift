import Foundation
import NaturalLanguage

actor OnDeviceSummarizationService: SummarizationService {
    nonisolated let providerType: SummarizationProvider = .onDevice
    
    func generateKeyPoints(_ transcripts: [String]) async throws -> [String] {
        let combinedText = transcripts.joined(separator: " ")
        
        guard combinedText.count >= 20 else {
            throw SummarizationError.textTooShort
        }
        
        let sentences = extractSentences(from: combinedText)
        return extractKeyPoints(from: sentences, maxPoints: 10)
    }
    
    func generateFullSummary(_ transcripts: [String]) async throws -> String {
        let combinedText = transcripts.joined(separator: " ")
        
        guard combinedText.count >= 20 else {
            throw SummarizationError.textTooShort
        }
        
        let sentences = extractSentences(from: combinedText)
        return generateConsolidatedSummary(from: transcripts, sentences: sentences)
    }
    
    // MARK: - NLP Processing
    
    private func extractSentences(from text: String) -> [String] {
        var sentences: [String] = []
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty && sentence.count > 5 {
                sentences.append(sentence)
            }
            return true
        }
        
        if sentences.isEmpty && !text.isEmpty {
            sentences = [text.trimmingCharacters(in: .whitespacesAndNewlines)]
        }
        
        return sentences
    }
    
    private func extractKeyPoints(from sentences: [String], maxPoints: Int = 7) -> [String] {
        guard !sentences.isEmpty else { return [] }
        
        var scoredSentences: [(sentence: String, score: Double)] = []
        
        let wordFrequency = calculateWordFrequency(from: sentences)
        
        for sentence in sentences {
            let score = scoreSentence(sentence, wordFrequency: wordFrequency)
            scoredSentences.append((sentence, score))
        }
        
        scoredSentences.sort { $0.score > $1.score }
        
        let topSentences = scoredSentences.prefix(maxPoints)
        
        return topSentences.map { cleanSentence($0.sentence) }
    }
    
    private func calculateWordFrequency(from sentences: [String]) -> [String: Int] {
        var frequency: [String: Int] = [:]
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        
        for sentence in sentences {
            tagger.string = sentence.lowercased()
            
            tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
                guard let tag = tag else { return true }
                
                if tag == .noun || tag == .verb || tag == .adjective {
                    let word = String(sentence[range]).lowercased()
                    if word.count > 3 && !isStopWord(word) {
                        frequency[word, default: 0] += 1
                    }
                }
                return true
            }
        }
        
        return frequency
    }
    
    private func scoreSentence(_ sentence: String, wordFrequency: [String: Int]) -> Double {
        let words = sentence.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var score: Double = 0
        var wordCount = 0
        
        for word in words {
            if let freq = wordFrequency[word] {
                score += Double(freq)
                wordCount += 1
            }
        }
        
        guard wordCount > 0 else { return 0 }
        
        let avgScore = score / Double(wordCount)
        
        let lengthBonus = min(Double(sentence.count) / 100.0, 1.5)
        
        return avgScore * lengthBonus
    }
    
    private func generateSummary(from sentences: [String]) -> String {
        guard !sentences.isEmpty else {
            return "No content available to summarize."
        }
        
        let wordFrequency = calculateWordFrequency(from: sentences)
        var scoredSentences: [(sentence: String, score: Double, index: Int)] = []
        
        for (index, sentence) in sentences.enumerated() {
            let score = scoreSentence(sentence, wordFrequency: wordFrequency)
            scoredSentences.append((sentence, score, index))
        }
        
        scoredSentences.sort { $0.score > $1.score }
        
        let summaryCount = min(3, sentences.count)
        let topSentences = Array(scoredSentences.prefix(summaryCount))
        
        let orderedSentences = topSentences.sorted { $0.index < $1.index }
        
        return orderedSentences.map { cleanSentence($0.sentence) }.joined(separator: " ")
    }
    
    private func generateConsolidatedSummary(from transcripts: [String], sentences: [String]) -> String {
        let totalWords = transcripts.joined(separator: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        
        var summary = "This consolidated summary covers \(transcripts.count) recording(s) "
        summary += "containing approximately \(totalWords) words. "
        
        let mainTopics = extractMainTopics(from: sentences)
        if !mainTopics.isEmpty {
            summary += "The main topics discussed include: \(mainTopics.joined(separator: ", ")). "
        }
        
        let coreSummary = generateSummary(from: sentences)
        if !coreSummary.isEmpty {
            summary += coreSummary
        }
        
        return summary
    }
    
    private func extractMainTopics(from sentences: [String]) -> [String] {
        var nounFrequency: [String: Int] = [:]
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        
        for sentence in sentences {
            tagger.string = sentence
            
            tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
                if tag == .noun {
                    let noun = String(sentence[range]).lowercased()
                    if noun.count > 3 && !isStopWord(noun) {
                        nounFrequency[noun, default: 0] += 1
                    }
                }
                return true
            }
        }
        
        let sortedNouns = nounFrequency.sorted { $0.value > $1.value }
        return Array(sortedNouns.prefix(5).map { $0.key.capitalized })
    }
    
    private func cleanSentence(_ sentence: String) -> String {
        var cleaned = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !cleaned.isEmpty && !".!?".contains(cleaned.last!) {
            cleaned += "."
        }
        
        return cleaned
    }
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords: Set<String> = [
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
            "of", "with", "by", "from", "as", "is", "was", "are", "were", "been",
            "be", "have", "has", "had", "do", "does", "did", "will", "would", "could",
            "should", "may", "might", "must", "shall", "can", "need", "dare", "ought",
            "used", "this", "that", "these", "those", "i", "you", "he", "she", "it",
            "we", "they", "what", "which", "who", "whom", "whose", "where", "when",
            "why", "how", "all", "each", "every", "both", "few", "more", "most",
            "other", "some", "such", "no", "nor", "not", "only", "own", "same",
            "so", "than", "too", "very", "just", "also", "now", "here", "there",
            "then", "once", "again", "always", "never", "sometimes", "often",
            "about", "after", "before", "above", "below", "between", "into",
            "through", "during", "under", "over", "out", "up", "down", "off",
            "well", "back", "still", "even", "really", "actually", "basically",
            "like", "know", "think", "going", "want", "thing", "things", "yeah",
            "okay", "right", "mean", "kind", "sort", "something", "anything"
        ]
        return stopWords.contains(word.lowercased())
    }
}
