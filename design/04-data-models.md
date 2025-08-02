# Data Models & Database Schema

## Core Data Models

### 1. CreditCard Model
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

enum CardType: String, Codable, CaseIterable {
    case amexGold = "Amex Gold"
    case amexPlatinum = "Amex Platinum"
    case chaseFreedom = "Chase Freedom"
    case chaseSapphirePreferred = "Chase Sapphire Preferred"
    case chaseSapphireReserve = "Chase Sapphire Reserve"
    case citiDoubleCash = "Citi Double Cash"
    case custom = "Custom"
}

struct RewardCategory: Codable, Identifiable {
    let id: UUID
    var category: SpendingCategory
    var multiplier: Double
    var pointType: PointType
    var isActive: Bool
}

struct QuarterlyBonus: Codable {
    var category: SpendingCategory
    var multiplier: Double
    var pointType: PointType
    var limit: Double
    var currentSpending: Double
    var quarter: Int // 1-4
    var year: Int
}

struct SpendingLimit: Codable, Identifiable {
    let id: UUID
    var category: SpendingCategory
    var limit: Double
    var currentSpending: Double
    var resetDate: Date
    var resetType: ResetType
}
```

### 2. SpendingCategory Model
```swift
enum SpendingCategory: String, Codable, CaseIterable {
    // Basic categories
    case groceries = "Groceries"
    case dining = "Dining"
    case travel = "Travel"
    case gas = "Gas"
    case online = "Online Shopping"
    case drugstores = "Drugstores"
    case streaming = "Streaming"
    case transit = "Transit"
    case office = "Office Supply"
    case phone = "Phone Services"
    case general = "General Purchases"
    
    // Merchant-specific categories
    case costco = "Costco"
    case amazon = "Amazon"
    case wholeFoods = "Whole Foods"
    case target = "Target"
    case walmart = "Walmart"
    
    // Subcategories
    case airfare = "Airfare"
    case hotels = "Hotels"
    case restaurants = "Restaurants"
    case fastFood = "Fast Food"
    case coffee = "Coffee Shops"
}

enum PointType: String, Codable, CaseIterable {
    case membershipRewards = "MR"
    case ultimateRewards = "UR"
    case thankYouPoints = "TYP"
    case cashback = "Cash Back"
    case capitalOneMiles = "Capital One Miles"
    case discoverCashback = "Discover Cash Back"
}

enum ResetType: String, Codable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
    case never = "Never"
}
```

### 3. UserPreferences Model
```swift
struct UserPreferences: Codable {
    var preferredPointSystem: PointType
    var alertThreshold: Double // Percentage (0.85 = 85%)
    var language: Language
    var notificationsEnabled: Bool
    var autoUpdateSpending: Bool
}

enum Language: String, Codable, CaseIterable {
    case english = "English"
    case chinese = "Chinese"
    case bilingual = "Bilingual"
}
```

### 4. ChatMessage Model
```swift
struct ChatMessage: Codable, Identifiable {
    let id: UUID
    var content: String
    var sender: MessageSender
    var timestamp: Date
    var cardRecommendations: [CardRecommendation]?
    var spendingUpdate: SpendingUpdate?
}

enum MessageSender: String, Codable {
    case user = "User"
    case assistant = "Assistant"
}

struct CardRecommendation: Codable, Identifiable {
    let id: UUID
    var cardId: UUID
    var cardName: String
    var category: SpendingCategory
    var multiplier: Double
    var pointType: PointType
    var reasoning: String
    var currentSpending: Double
    var limit: Double
    var isLimitReached: Bool
    var rank: Int // 1 for primary, 2 for secondary
}

struct SpendingUpdate: Codable {
    var cardId: UUID
    var category: SpendingCategory
    var amount: Double
    var previousAmount: Double
}
```

### 5. Merchant Model
```swift
struct Merchant: Codable, Identifiable {
    let id: UUID
    var name: String
    var category: SpendingCategory
    var aliases: [String] // Alternative names
    var isActive: Bool
}

// Pre-defined merchant mappings
let merchantMappings: [String: SpendingCategory] = [
    "costco": .costco,
    "whole foods": .wholeFoods,
    "amazon": .amazon,
    "target": .target,
    "walmart": .walmart,
    "starbucks": .coffee,
    "mcdonalds": .fastFood,
    "uber": .transit,
    "lyft": .transit,
    "netflix": .streaming,
    "spotify": .streaming,
    "cvs": .drugstores,
    "walgreens": .drugstores,
    "shell": .gas,
    "exxon": .gas,
    "chevron": .gas
]
```

## Database Schema (Core Data)

### 1. CreditCard Entity
```xml
<entity name="CreditCard" representedClassName="CreditCard" syncable="YES">
    <attribute name="id" optional="NO" attributeType="UUID" usesScalarValueType="NO"/>
    <attribute name="name" optional="NO" attributeType="String"/>
    <attribute name="cardType" optional="NO" attributeType="String"/>
    <attribute name="isActive" optional="NO" attributeType="Boolean" defaultValueString="YES" usesScalarValueType="YES"/>
    <attribute name="createdAt" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
    <attribute name="updatedAt" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
    
    <relationship name="rewardCategories" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="RewardCategory" inverseName="creditCard" inverseEntity="RewardCategory"/>
    <relationship name="spendingLimits" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="SpendingLimit" inverseName="creditCard" inverseEntity="SpendingLimit"/>
    <relationship name="quarterlyBonus" optional="YES" maxCount="1" deletionRule="Cascade" destinationEntity="QuarterlyBonus" inverseName="creditCard" inverseEntity="QuarterlyBonus"/>
</entity>
```

### 2. RewardCategory Entity
```xml
<entity name="RewardCategory" representedClassName="RewardCategory" syncable="YES">
    <attribute name="id" optional="NO" attributeType="UUID" usesScalarValueType="NO"/>
    <attribute name="category" optional="NO" attributeType="String"/>
    <attribute name="multiplier" optional="NO" attributeType="Double" defaultValueString="1.0" usesScalarValueType="YES"/>
    <attribute name="pointType" optional="NO" attributeType="String"/>
    <attribute name="isActive" optional="NO" attributeType="Boolean" defaultValueString="YES" usesScalarValueType="YES"/>
    
    <relationship name="creditCard" optional="NO" maxCount="1" deletionRule="Nullify" destinationEntity="CreditCard" inverseName="rewardCategories" inverseEntity="CreditCard"/>
</entity>
```

### 3. SpendingLimit Entity
```xml
<entity name="SpendingLimit" representedClassName="SpendingLimit" syncable="YES">
    <attribute name="id" optional="NO" attributeType="UUID" usesScalarValueType="NO"/>
    <attribute name="category" optional="NO" attributeType="String"/>
    <attribute name="limit" optional="NO" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
    <attribute name="currentSpending" optional="NO" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
    <attribute name="resetDate" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
    <attribute name="resetType" optional="NO" attributeType="String"/>
    
    <relationship name="creditCard" optional="NO" maxCount="1" deletionRule="Nullify" destinationEntity="CreditCard" inverseName="spendingLimits" inverseEntity="CreditCard"/>
</entity>
```

### 4. ChatMessage Entity
```xml
<entity name="ChatMessage" representedClassName="ChatMessage" syncable="YES">
    <attribute name="id" optional="NO" attributeType="UUID" usesScalarValueType="NO"/>
    <attribute name="content" optional="NO" attributeType="String"/>
    <attribute name="sender" optional="NO" attributeType="String"/>
    <attribute name="timestamp" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
    
    <relationship name="cardRecommendations" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="CardRecommendation" inverseName="chatMessage" inverseEntity="CardRecommendation"/>
    <relationship name="spendingUpdate" optional="YES" maxCount="1" deletionRule="Cascade" destinationEntity="SpendingUpdate" inverseName="chatMessage" inverseEntity="SpendingUpdate"/>
</entity>
```

## Data Validation Rules

### 1. CreditCard Validation
- Name must not be empty
- Card type must be valid
- At least one reward category required
- Spending limits must be positive numbers

### 2. SpendingLimit Validation
- Current spending cannot exceed limit
- Reset date must be in the future
- Category must be valid

### 3. ChatMessage Validation
- Content must not be empty
- Sender must be valid
- Timestamp must be valid

## Data Migration Strategy

### Version 1.0 to 1.1
- Add quarterly bonus support
- Add merchant mappings
- Add language preferences

### Version 1.1 to 1.2
- Add spending history tracking
- Add notification preferences
- Add data export functionality

## Sample Data

### Pre-built Credit Cards
```json
{
  "name": "Amex Gold",
  "cardType": "amexGold",
  "rewardCategories": [
    {
      "category": "groceries",
      "multiplier": 4.0,
      "pointType": "membershipRewards",
      "isActive": true
    },
    {
      "category": "dining",
      "multiplier": 4.0,
      "pointType": "membershipRewards",
      "isActive": true
    }
  ],
  "spendingLimits": [
    {
      "category": "groceries",
      "limit": 25000.0,
      "currentSpending": 0.0,
      "resetType": "annually"
    },
    {
      "category": "dining",
      "limit": 25000.0,
      "currentSpending": 0.0,
      "resetType": "annually"
    }
  ]
}
```

### User Preferences Default
```json
{
  "preferredPointSystem": "membershipRewards",
  "alertThreshold": 0.85,
  "language": "english",
  "notificationsEnabled": true,
  "autoUpdateSpending": false
}
``` 