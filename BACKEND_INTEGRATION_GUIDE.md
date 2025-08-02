# Backend Integration Guide

## Overview

This document provides comprehensive guidance for backend engineers on how to integrate with the iOS frontend. The frontend is designed with clean architecture principles and is ready for backend integration.

## 🏗 Architecture Overview

### Current Frontend Architecture
```
Frontend (iOS)
├── Views (SwiftUI)           # UI Layer
├── ViewModels (MVVM)         # Business Logic Layer
├── Services                  # Data Access Layer
│   ├── DataManager          # Core Data operations
│   ├── RecommendationEngine # Business logic
│   └── NLPProcessor         # Natural language processing
└── Models                    # Data Models
```

### Target Architecture with Backend
```
Frontend (iOS) ←→ Backend (API)
├── Views (SwiftUI)           # UI Layer
├── ViewModels (MVVM)         # Business Logic Layer
├── Services                  # Data Access Layer
│   ├── APIService           # HTTP client
│   ├── DataManager          # Local cache + API sync
│   ├── RecommendationEngine # Business logic
│   └── NLPProcessor         # Natural language processing
└── Models                    # Data Models
```

## 🔌 Integration Points

### 1. API Service Layer

#### Current Implementation
The frontend currently uses local Core Data storage. To integrate with a backend:

```swift
// Current: Local DataManager
class DataManager {
    func fetchCards() async throws -> [CreditCard] {
        // Currently fetches from Core Data
    }
}

// Target: API-enabled DataManager
class DataManager {
    private let apiService: APIService
    
    func fetchCards() async throws -> [CreditCard] {
        // 1. Try to fetch from API
        let cards = try await apiService.fetchCards()
        
        // 2. Update local cache
        try await updateLocalCache(cards)
        
        // 3. Return data
        return cards
    }
}
```

#### Required API Endpoints

```swift
// Card Management
GET    /api/cards                    // Fetch user's cards
POST   /api/cards                    // Create new card
PUT    /api/cards/{id}              // Update card
DELETE /api/cards/{id}              // Delete card

// Chat & Recommendations
POST   /api/recommendations          // Get card recommendations
POST   /api/chat/messages            // Send chat message
GET    /api/chat/messages            // Fetch chat history

// User Preferences
GET    /api/preferences              // Fetch user preferences
PUT    /api/preferences              // Update preferences

// Spending Updates
PUT    /api/cards/{id}/spending      // Update spending amounts
```

### 2. Data Models

#### Current Models (Ready for API)
The frontend models are already designed for API integration:

```swift
// CreditCard model (ready for JSON serialization)
struct CreditCard: Codable, Identifiable {
    let id: UUID
    var name: String
    var cardType: CardType
    var rewardCategories: [RewardCategory]
    var quarterlyBonus: QuarterlyBonus?
    var spendingLimits: [SpendingLimit]
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
}

// API Request/Response models
struct RecommendationRequest: Codable {
    let userQuery: String
    let spendingCategory: SpendingCategory?
    let merchant: String?
    let amount: Double?
    let userPreferences: UserPreferences
    let userCards: [CreditCard]
}

struct RecommendationResponse: Codable {
    let primaryRecommendation: CardRecommendation
    let secondaryRecommendation: CardRecommendation?
    let reasoning: String
    let warnings: [String]
    let suggestions: [String]
}
```

### 3. Service Integration

#### API Service Implementation
```swift
class APIService {
    private let baseURL = "https://api.creditcardapp.com"
    private let session = URLSession.shared
    
    // MARK: - Card Management
    func fetchCards() async throws -> [CreditCard] {
        let url = URL(string: "\(baseURL)/api/cards")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode([CreditCard].self, from: data)
    }
    
    func createCard(_ card: CreditCard) async throws -> CreditCard {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/cards")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(card)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(CreditCard.self, from: data)
    }
    
    // MARK: - Recommendations
    func getRecommendation(for request: RecommendationRequest) async throws -> RecommendationResponse {
        var urlRequest = URLRequest(url: URL(string: "\(baseURL)/api/recommendations")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(RecommendationResponse.self, from: data)
    }
}

enum APIError: Error {
    case invalidResponse
    case networkError
    case decodingError
    case serverError(String)
}
```

## 🔄 Data Synchronization Strategy

### 1. Offline-First Approach
The frontend maintains local data for offline functionality:

```swift
class DataManager {
    private let apiService: APIService
    private let coreDataStack: CoreDataStack
    
    func fetchCards() async throws -> [CreditCard] {
        do {
            // Try API first
            let cards = try await apiService.fetchCards()
            try await updateLocalCache(cards)
            return cards
        } catch {
            // Fallback to local data
            return try await fetchLocalCards()
        }
    }
    
    func syncWithServer() async {
        // Background sync when online
        Task {
            do {
                let localCards = try await fetchLocalCards()
                let serverCards = try await apiService.fetchCards()
                
                // Merge and resolve conflicts
                let mergedCards = mergeCards(local: localCards, server: serverCards)
                try await updateLocalCache(mergedCards)
            } catch {
                // Handle sync errors
                print("Sync failed: \(error)")
            }
        }
    }
}
```

### 2. Conflict Resolution
```swift
func mergeCards(local: [CreditCard], server: [CreditCard]) -> [CreditCard] {
    var merged: [CreditCard] = []
    
    // Use server data as source of truth
    for serverCard in server {
        if let localCard = local.first(where: { $0.id == serverCard.id }) {
            // Merge with local changes
            let mergedCard = mergeCard(local: localCard, server: serverCard)
            merged.append(mergedCard)
        } else {
            // New server card
            merged.append(serverCard)
        }
    }
    
    // Add local-only cards
    for localCard in local {
        if !server.contains(where: { $0.id == localCard.id }) {
            merged.append(localCard)
        }
    }
    
    return merged
}
```

## 🔐 Authentication & Security

### 1. Authentication Flow
```swift
class AuthenticationService {
    private let keychain = KeychainService()
    
    func authenticate() async throws -> String {
        // Check for existing token
        if let token = keychain.getToken() {
            return token
        }
        
        // Perform authentication
        let credentials = try await getCredentials()
        let token = try await apiService.authenticate(credentials)
        
        // Store token securely
        keychain.storeToken(token)
        return token
    }
}

class APIService {
    private var authToken: String?
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    private func addAuthHeaders(to request: inout URLRequest) {
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}
```

### 2. Secure Data Storage
```swift
class KeychainService {
    func storeToken(_ token: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "auth_token",
            kSecValueData as String: token.data(using: .utf8)!
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "auth_token",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
}
```

## 📊 API Specifications

### 1. Card Management Endpoints

#### GET /api/cards
```json
Response:
{
  "cards": [
    {
      "id": "uuid",
      "name": "Amex Gold",
      "cardType": "amexGold",
      "rewardCategories": [...],
      "spendingLimits": [...],
      "isActive": true,
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### POST /api/cards
```json
Request:
{
  "name": "Amex Gold",
  "cardType": "amexGold",
  "rewardCategories": [...],
  "spendingLimits": [...],
  "isActive": true
}

Response:
{
  "id": "uuid",
  "name": "Amex Gold",
  "cardType": "amexGold",
  "rewardCategories": [...],
  "spendingLimits": [...],
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### 2. Recommendation Endpoints

#### POST /api/recommendations
```json
Request:
{
  "userQuery": "I'm buying groceries at Whole Foods",
  "spendingCategory": "groceries",
  "merchant": "whole foods",
  "amount": 150.0,
  "userPreferences": {
    "preferredPointSystem": "membershipRewards",
    "alertThreshold": 0.85,
    "language": "english"
  },
  "userCards": [...]
}

Response:
{
  "primaryRecommendation": {
    "cardId": "uuid",
    "cardName": "Amex Gold",
    "category": "groceries",
    "multiplier": 4.0,
    "pointType": "MR",
    "reasoning": "Amex Gold offers 4x MR points on groceries...",
    "currentSpending": 800.0,
    "limit": 1000.0,
    "isLimitReached": false,
    "rank": 1
  },
  "secondaryRecommendation": {...},
  "reasoning": "Based on your spending pattern...",
  "warnings": ["Limit almost reached"],
  "suggestions": ["Consider using CSR as backup"]
}
```

## 🧪 Testing Integration

### 1. Mock API Service
```swift
class MockAPIService: APIServiceProtocol {
    var shouldFail = false
    var mockCards: [CreditCard] = []
    
    func fetchCards() async throws -> [CreditCard] {
        if shouldFail {
            throw APIError.networkError
        }
        return mockCards
    }
    
    func getRecommendation(for request: RecommendationRequest) async throws -> RecommendationResponse {
        if shouldFail {
            throw APIError.networkError
        }
        
        return RecommendationResponse(
            primaryRecommendation: CardRecommendation(...),
            secondaryRecommendation: nil,
            reasoning: "Mock recommendation",
            warnings: [],
            suggestions: []
        )
    }
}
```

### 2. Integration Tests
```swift
class APIIntegrationTests: XCTestCase {
    var apiService: APIService!
    
    override func setUp() {
        apiService = APIService()
    }
    
    func testFetchCards() async throws {
        let cards = try await apiService.fetchCards()
        XCTAssertFalse(cards.isEmpty)
    }
    
    func testGetRecommendation() async throws {
        let request = RecommendationRequest(...)
        let response = try await apiService.getRecommendation(for: request)
        XCTAssertNotNil(response.primaryRecommendation)
    }
}
```

## 🚀 Deployment Considerations

### 1. Environment Configuration
```swift
enum Environment {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:3000"
        case .staging:
            return "https://staging-api.creditcardapp.com"
        case .production:
            return "https://api.creditcardapp.com"
        }
    }
}
```

### 2. Error Handling
```swift
enum APIError: LocalizedError {
    case networkError
    case serverError(String)
    case authenticationError
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection failed"
        case .serverError(let message):
            return "Server error: \(message)"
        case .authenticationError:
            return "Authentication failed"
        case .rateLimitExceeded:
            return "Too many requests"
        }
    }
}
```

## 📋 Integration Checklist

### Phase 1: Basic API Integration
- [ ] Set up API service layer
- [ ] Implement authentication
- [ ] Create data synchronization
- [ ] Add error handling
- [ ] Test basic CRUD operations

### Phase 2: Advanced Features
- [ ] Implement recommendation API
- [ ] Add chat message sync
- [ ] Create conflict resolution
- [ ] Add offline support
- [ ] Performance optimization

### Phase 3: Production Ready
- [ ] Security audit
- [ ] Performance testing
- [ ] Error monitoring
- [ ] Analytics integration
- [ ] Documentation completion

## 🤝 Collaboration Guidelines

### Code Review Process
1. **API Contracts**: Review all API endpoint specifications
2. **Error Handling**: Ensure comprehensive error scenarios
3. **Security**: Validate authentication and data protection
4. **Performance**: Check for efficient data transfer
5. **Testing**: Verify integration test coverage

### Communication Channels
- **API Documentation**: Keep endpoint docs updated
- **Error Codes**: Maintain consistent error response format
- **Versioning**: Use semantic versioning for API changes
- **Breaking Changes**: Communicate changes well in advance

---

This guide provides a comprehensive roadmap for backend integration. The frontend is designed to be flexible and maintainable, making it easy to add backend services without major architectural changes. 