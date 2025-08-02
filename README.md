# Credit Card Recommendation App - Backend Implementation

## Overview

This is the backend implementation for the **Credit Card Chat Recommendation & Limit Reminder App** - an iOS MVP that helps users choose the best credit card for their purchases through conversational AI.

## 🏗️ Architecture

The app follows the **MVVM (Model-View-ViewModel)** architecture pattern with the following key components:

### Core Architecture
- **Models**: Data structures and business logic
- **ViewModels**: Business logic and state management
- **Services**: Core functionality and external integrations
- **Views**: User interface (handled by frontend team)
- **Core Data**: Local data persistence

## 📁 Project Structure

```
CreditCardApp/
├── Models/
│   ├── Core/
│   │   ├── CreditCard.swift          # Core credit card model
│   │   └── SpendingCategory.swift    # Spending categories and enums
│   └── CoreData/
│       ├── CoreDataStack.swift       # Core Data stack management
│       └── CreditCardApp.xcdatamodeld/ # Core Data model
├── Services/
│   ├── DataManager.swift             # Core Data operations
│   ├── RecommendationEngine.swift    # Card recommendation logic
│   ├── NLPProcessor.swift            # Natural language processing
│   ├── NotificationService.swift     # Push notifications
│   └── AnalyticsService.swift        # Analytics and tracking
├── ViewModels/
│   ├── BaseViewModel.swift           # Base ViewModel with common functionality
│   ├── ChatViewModel.swift           # Chat interface logic
│   ├── CardListViewModel.swift       # Card management logic
│   ├── AddCardViewModel.swift        # Add/edit card logic
│   └── SettingsViewModel.swift       # Settings and preferences
├── Utils/
│   └── Extensions/
│       ├── String+Extensions.swift   # String utilities
│       └── Double+Extensions.swift   # Number formatting
└── Views/
    └── ContentView.swift             # Main app interface
```

## 🚀 Key Features Implemented

### 1. Core Data Management
- **CreditCard**: Complete credit card model with reward categories
- **SpendingLimit**: Track spending progress and limits
- **QuarterlyBonus**: Handle rotating category bonuses
- **UserPreferences**: Store user settings and preferences
- **ChatMessage**: Persist chat history

### 2. Recommendation Engine
- **Card Scoring Algorithm**: Multi-factor scoring system
- **Category Recognition**: Automatic spending category detection
- **Merchant Mapping**: Recognize common merchants
- **Limit Management**: Consider spending limits in recommendations
- **Preference Weighting**: Prioritize user's preferred point systems

### 3. Natural Language Processing
- **Query Parsing**: Extract spending categories, merchants, and amounts
- **Intent Detection**: Understand user intent (recommendation, update, etc.)
- **Confidence Scoring**: Measure query understanding accuracy
- **Query Validation**: Validate and sanitize user inputs

### 4. Notification System
- **Limit Alerts**: Warn when approaching spending limits
- **Quarterly Bonus Reminders**: Alert for expiring bonuses
- **Spending Reminders**: Help users track their spending
- **Daily Summaries**: Regular app engagement

### 5. Analytics & Tracking
- **Event Tracking**: Monitor user interactions
- **Performance Monitoring**: Track response times
- **Error Tracking**: Capture and analyze errors
- **Usage Analytics**: Understand user behavior patterns

## 🔧 Technical Implementation

### Core Data Stack
```swift
class CoreDataStack {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CreditCardApp")
        // Configuration and setup
        return container
    }()
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T
}
```

### Recommendation Engine
```swift
class RecommendationEngine {
    func getRecommendation(for query: String, userCards: [CreditCard], userPreferences: UserPreferences) async throws -> RecommendationResponse {
        // 1. Parse user query
        // 2. Determine spending category
        // 3. Score all cards
        // 4. Filter and rank recommendations
        // 5. Generate response
    }
}
```

### Card Scoring Algorithm
The recommendation engine uses a weighted scoring system:

1. **Base Score** (10%): Default 1x points
2. **Category Score** (60%): Multiplier for specific spending category
3. **Preference Score** (20%): Bonus for preferred point system
4. **Limit Score** (10%): Penalty for approaching/reached limits

### NLP Processing
```swift
class NLPProcessor {
    func parseUserQuery(_ query: String) -> ParsedQuery {
        // Extract spending category, merchant, amount, and intent
    }
    
    func validateQuery(_ query: String) -> QueryValidationResult {
        // Validate query format and content
    }
}
```

## 📊 Data Models

### CreditCard
```swift
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
```

### SpendingLimit
```swift
struct SpendingLimit: Codable, Identifiable {
    let id: UUID
    var category: SpendingCategory
    var limit: Double
    var currentSpending: Double
    var resetDate: Date
    var resetType: ResetType
    
    var usagePercentage: Double
    var remainingAmount: Double
    var isLimitReached: Bool
    var isWarningThreshold: Bool
}
```

### UserPreferences
```swift
struct UserPreferences: Codable {
    var preferredPointSystem: PointType
    var alertThreshold: Double
    var language: Language
    var notificationsEnabled: Bool
    var autoUpdateSpending: Bool
}
```

## 🎯 Key Algorithms

### 1. Card Scoring
```swift
func scoreCard(_ card: CreditCard, category: SpendingCategory, preferences: UserPreferences) -> CardScore {
    let baseScore = 1.0
    let categoryScore = calculateCategoryScore(card, category)
    let preferenceScore = calculatePreferenceScore(card, preferences)
    let limitScore = calculateLimitScore(card, category)
    
    let totalScore = (baseScore * 0.1) + 
                    (categoryScore * 0.6) + 
                    (preferenceScore * 0.2) + 
                    (limitScore * 0.1)
    
    return CardScore(/* ... */)
}
```

### 2. Category Recognition
```swift
func extractSpendingCategory(_ query: String) -> SpendingCategory? {
    let categoryKeywords: [SpendingCategory: [String]] = [
        .groceries: ["grocery", "groceries", "food", "supermarket"],
        .dining: ["dining", "restaurant", "dinner", "lunch"],
        .travel: ["travel", "flight", "hotel", "vacation"],
        // ... more categories
    ]
    
    for (category, keywords) in categoryKeywords {
        if keywords.contains(where: { query.contains($0) }) {
            return category
        }
    }
    return nil
}
```

### 3. Limit Management
```swift
func calculateLimitScore(_ card: CreditCard, _ category: SpendingCategory) -> Double {
    guard let spendingLimit = card.spendingLimits.first(where: { $0.category == category }) else {
        return 1.0 // No limit = no penalty
    }
    
    let usagePercentage = spendingLimit.currentSpending / spendingLimit.limit
    
    if usagePercentage >= 1.0 {
        return 0.0 // Limit reached
    } else if usagePercentage >= 0.85 {
        return 0.5 // Warning threshold
    } else {
        return 1.0 // Plenty of capacity
    }
}
```

## 🔄 Data Flow

### Chat Recommendation Flow
1. **User Input** → ChatViewModel
2. **Query Parsing** → NLPProcessor
3. **Data Retrieval** → DataManager (cards, preferences)
4. **Recommendation** → RecommendationEngine
5. **Response Generation** → ChatViewModel
6. **UI Update** → SwiftUI Views

### Card Management Flow
1. **User Action** → ViewModel
2. **Validation** → ViewModel
3. **Data Operation** → DataManager
4. **Core Data Update** → CoreDataStack
5. **UI Update** → SwiftUI Views

## 🧪 Testing Strategy

### Unit Tests
- **Recommendation Engine**: Test scoring algorithms
- **NLP Processor**: Test query parsing accuracy
- **Data Manager**: Test CRUD operations
- **ViewModels**: Test business logic

### Integration Tests
- **End-to-End Workflows**: Complete user journeys
- **Data Persistence**: Core Data operations
- **Performance**: Response time benchmarks

### Test Data
```swift
// Sample cards for testing
let sampleCards = [
    CreditCard(name: "Amex Gold", cardType: .amexGold, /* ... */),
    CreditCard(name: "Chase Freedom", cardType: .chaseFreedom, /* ... */),
    CreditCard(name: "Chase Sapphire Reserve", cardType: .chaseSapphireReserve, /* ... */)
]
```

## 📈 Performance Considerations

### 1. Core Data Optimization
- Background context for heavy operations
- Batch operations for multiple updates
- Proper fetch request optimization
- Memory management with weak references

### 2. Recommendation Engine
- Caching for repeated queries
- Pre-computed scores for common scenarios
- Async processing for non-blocking UI
- Efficient scoring algorithms

### 3. Memory Management
- Proper cleanup in ViewModels
- Weak references in closures
- Lazy loading for large datasets
- Background processing for heavy computations

## 🔒 Security & Privacy

### Data Protection
- Core Data encryption
- Secure data deletion
- Input validation and sanitization
- No sensitive data logging

### Privacy Compliance
- Local data storage only
- User consent for notifications
- Transparent data usage
- Easy data export/deletion

## 🚀 Deployment

### Build Configuration
- **Debug**: Development with logging
- **Release**: Production optimized
- **TestFlight**: Beta testing

### App Store Preparation
- App icons and screenshots
- App description and keywords
- Privacy policy and terms
- Version management

## 📚 API Documentation

### RecommendationEngine
```swift
// Get card recommendation for a query
func getRecommendation(for query: String, userCards: [CreditCard], userPreferences: UserPreferences) async throws -> RecommendationResponse

// Check seasonal bonuses
func checkSeasonalBonuses(_ card: CreditCard, _ category: SpendingCategory) -> Double

// Optimize multi-card strategy
func optimizeMultiCardStrategy(_ cards: [CreditCard], _ amount: Double, _ category: SpendingCategory, _ preferences: UserPreferences) -> [CardRecommendation]
```

### DataManager
```swift
// Card operations
func fetchCards() async throws -> [CreditCard]
func saveCard(_ card: CreditCard) async throws
func updateCard(_ card: CreditCard) async throws
func deleteCard(_ card: CreditCard) async throws

// Spending operations
func updateSpendingLimit(cardId: UUID, category: SpendingCategory, amount: Double) async throws

// Preferences operations
func loadUserPreferences() async throws -> UserPreferences
func saveUserPreferences(_ preferences: UserPreferences) async throws
```

### NLPProcessor
```swift
// Query processing
func parseUserQuery(_ query: String) -> ParsedQuery
func validateQuery(_ query: String) -> QueryValidationResult
func enhanceQuery(_ query: String) -> String

// Category mapping
func mapCategoryToSpendingCategory(_ category: String) -> SpendingCategory?
```

## 🤝 Frontend Integration

The backend is designed to work seamlessly with the frontend team's SwiftUI implementation:

### ViewModels
- **@Published** properties for reactive UI updates
- **async/await** for non-blocking operations
- **Error handling** with user-friendly messages
- **Loading states** for better UX

### Data Binding
- **ObservableObject** protocol for SwiftUI integration
- **Combine** framework for reactive programming
- **EnvironmentObject** for dependency injection

### UI Components
- **ChatBubbleView**: Display chat messages
- **CardRowView**: Show card information
- **ProgressBarView**: Visualize spending progress
- **AlertView**: Show warnings and errors

## 🔮 Future Enhancements

### Phase 2 Features
1. **Real Transaction Integration**: Plaid API for automatic spending tracking
2. **Advanced Analytics**: Spending insights and optimization suggestions
3. **Push Notifications**: Limit alerts and spending reminders
4. **Multi-language Support**: Full internationalization

### Advanced AI Features
1. **Machine Learning**: Personalized recommendations based on spending patterns
2. **Predictive Analytics**: Spending forecasts and optimization suggestions
3. **Natural Language Understanding**: More sophisticated query processing
4. **Voice Integration**: Voice-based recommendations

## 📞 Support

For questions about the backend implementation:
- Review the design documentation in `/design/`
- Check the inline code comments
- Run the unit tests for examples
- Contact the backend development team

---

**Backend Implementation Status**: ✅ Complete for MVP
**Frontend Integration**: 🔄 In Progress
**Testing**: 🧪 Unit tests implemented
**Documentation**: 📚 Complete 