import Foundation
import NaturalLanguage
import CoreML

@available(iOS 17.0, *)
class AppleIntelligenceService: ObservableObject {
    static let shared = AppleIntelligenceService()
    
    private let nlModel: NLModel?
    private let embedding: NLEmbedding?
    
    private init() {
        // Initialize Apple's on-device language model
        self.nlModel = try? NLModel(mlModel: MLModel())
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
        
        print("🧠 Apple Intelligence Service initialized")
    }
    
    // MARK: - Text Generation
    
    func generateResponse(for prompt: String, context: String = "") async throws -> String {
        let fullPrompt = buildPrompt(userQuery: prompt, context: context)
        
        // Use Apple's on-device text generation
        if #available(iOS 17.0, *) {
            return try await generateWithAppleIntelligence(prompt: fullPrompt)
        } else {
            // Fallback for older iOS versions
            return try await generateWithNaturalLanguage(prompt: fullPrompt)
        }
    }
    
    @available(iOS 17.0, *)
    private func generateWithAppleIntelligence(prompt: String) async throws -> String {
        // This would use Apple's on-device LLM when available
        // For now, we'll simulate with intelligent text processing
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Simulate on-device LLM processing
                    let processedResponse = self.processWithIntelligentLogic(prompt: prompt)
                    continuation.resume(returning: processedResponse)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func generateWithNaturalLanguage(prompt: String) async throws -> String {
        // Fallback using NaturalLanguage framework
        let tagger = NLTagger(tagSchemes: [.sentimentScore, .language])
        tagger.string = prompt
        
        // Analyze sentiment and language
        let sentiment = tagger.tag(at: prompt.startIndex, unit: .paragraph, scheme: .sentimentScore).0?.rawValue
        
        return processWithIntelligentLogic(prompt: prompt, sentiment: sentiment)
    }
    
    // MARK: - Context-Aware Processing
    
    private func processWithIntelligentLogic(prompt: String, sentiment: String? = nil) -> String {
        let lowercasedPrompt = prompt.lowercased()
        
        // Extract intent and entities using pattern matching
        if lowercasedPrompt.contains("recommend") || lowercasedPrompt.contains("best card") {
            return generateRecommendationResponse(from: prompt)
        } else if lowercasedPrompt.contains("spending") || lowercasedPrompt.contains("limit") {
            return generateSpendingResponse(from: prompt)
        } else if lowercasedPrompt.contains("points") || lowercasedPrompt.contains("rewards") {
            return generateRewardsResponse(from: prompt)
        } else {
            return generateGeneralResponse(from: prompt)
        }
    }
    
    // MARK: - Response Generators
    
    private func generateRecommendationResponse(from prompt: String) -> String {
        let templates = [
            "Based on your spending pattern, I'd recommend {recommendation}. This card offers {benefits} for your purchase type.",
            "For this purchase, your best option is {recommendation}. You'll earn {points} points and have {remaining} remaining in your limit.",
            "I suggest using {recommendation} because {reasoning}. This maximizes your rewards while staying within limits."
        ]
        
        return templates.randomElement() ?? "I'd be happy to recommend the best card for your purchase."
    }
    
    private func generateSpendingResponse(from prompt: String) -> String {
        let templates = [
            "Your current spending shows {status}. You have {remaining} left in your {category} limit.",
            "Based on your spending pattern, you're {percentage}% through your limit. {advice}",
            "Your spending is on track. Consider {suggestion} to maximize your rewards."
        ]
        
        return templates.randomElement() ?? "Let me check your current spending status."
    }
    
    private func generateRewardsResponse(from prompt: String) -> String {
        let templates = [
            "You can earn {points} points with {card} for this purchase. That's worth approximately {value}.",
            "Your rewards breakdown: {breakdown}. Consider {optimization} to maximize value.",
            "Based on your preferences for {point_type}, I recommend {strategy}."
        ]
        
        return templates.randomElement() ?? "Let me help you optimize your rewards."
    }
    
    private func generateGeneralResponse(from prompt: String) -> String {
        let templates = [
            "I understand you're asking about {topic}. Based on your credit card portfolio, {analysis}.",
            "Great question! For your situation, {insight}. Would you like me to elaborate on any specific aspect?",
            "Let me help you with that. Given your cards and preferences, {recommendation}."
        ]
        
        return templates.randomElement() ?? "I'm here to help with your credit card questions. Could you provide more details?"
    }
    
    // MARK: - Prompt Engineering
    
    private func buildPrompt(userQuery: String, context: String) -> String {
        var prompt = """
        You are a helpful credit card recommendation assistant. You have access to the user's credit card portfolio and preferences.
        
        Context:
        \(context)
        
        User Query: \(userQuery)
        
        Instructions:
        - Provide specific, actionable recommendations
        - Consider spending limits and current usage
        - Factor in reward multipliers and point types
        - Be concise but informative
        - Include warnings if limits are nearly reached
        
        Response:
        """
        
        return prompt
    }
    
    // MARK: - Embeddings for RAG
    
    func generateEmbedding(for text: String) async throws -> [Double] {
        guard let embedding = self.embedding else {
            throw AppleIntelligenceError.embeddingNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Generate sentence embedding
                    let vector = try embedding.vector(for: text)
                    let doubleVector = vector.map { Double($0) }
                    continuation.resume(returning: doubleVector)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func findSimilarContext(query: String, contexts: [String]) async throws -> [String] {
        let queryEmbedding = try await generateEmbedding(for: query)
        var similarities: [(context: String, similarity: Double)] = []
        
        for context in contexts {
            let contextEmbedding = try await generateEmbedding(for: context)
            let similarity = cosineSimilarity(queryEmbedding, contextEmbedding)
            similarities.append((context: context, similarity: similarity))
        }
        
        // Return top 3 most similar contexts
        return similarities
            .sorted { $0.similarity > $1.similarity }
            .prefix(3)
            .map { $0.context }
    }
    
    // MARK: - Utility Functions
    
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0.0 }
        
        let dotProduct = zip(a, b).reduce(0.0) { $0 + $1.0 * $1.1 }
        let magnitudeA = sqrt(a.reduce(0.0) { $0 + $1 * $1 })
        let magnitudeB = sqrt(b.reduce(0.0) { $0 + $1 * $1 })
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
}

// MARK: - Error Types

enum AppleIntelligenceError: Error, LocalizedError {
    case modelNotAvailable
    case embeddingNotAvailable
    case processingFailed
    case contextTooLarge
    
    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "Apple Intelligence model is not available on this device"
        case .embeddingNotAvailable:
            return "Text embedding service is not available"
        case .processingFailed:
            return "Failed to process the request"
        case .contextTooLarge:
            return "Context is too large for processing"
        }
    }
}