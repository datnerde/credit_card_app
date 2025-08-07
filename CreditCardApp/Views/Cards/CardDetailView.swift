import SwiftUI

struct CardDetailView: View {
    let card: CreditCard
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditCard = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Card Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(card.cardType.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if !card.isActive {
                                Text("Inactive")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Divider()
                    }
                    .padding(.horizontal)
                    
                    // Reward Categories
                    if !card.rewardCategories.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reward Categories")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(card.rewardCategories) { category in
                                    RewardCategoryCard(category: category)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Quarterly Bonus
                    if let quarterlyBonus = card.quarterlyBonus {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quarterly Bonus (Q\(quarterlyBonus.quarter) \(quarterlyBonus.year))")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: quarterlyBonus.category.icon)
                                        .foregroundColor(.orange)
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(quarterlyBonus.category.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text("\(quarterlyBonus.multiplier, specifier: "%.1f")x \(quarterlyBonus.pointType.displayName)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("\(quarterlyBonus.currentSpending.asCurrency) / \(quarterlyBonus.limit.asCurrency)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        
                                        Text("\(Int((quarterlyBonus.currentSpending / quarterlyBonus.limit) * 100))% used")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                ProgressView(value: quarterlyBonus.currentSpending, total: quarterlyBonus.limit)
                                    .progressViewStyle(LinearProgressViewStyle(tint: quarterlyBonus.currentSpending >= quarterlyBonus.limit ? .red : .orange))
                                
                                if quarterlyBonus.currentSpending >= quarterlyBonus.limit {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text("Quarterly limit reached")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                } else if (quarterlyBonus.currentSpending / quarterlyBonus.limit) >= 0.85 {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text("Approaching quarterly limit")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Spending Limits
                    if !card.spendingLimits.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Spending Progress")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(card.spendingLimits) { limit in
                                    SpendingLimitCard(limit: limit)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Card Statistics
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Card Information")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            InfoRow(label: "Added", value: DateFormatter.shortDate.string(from: card.createdAt))
                            InfoRow(label: "Last Updated", value: DateFormatter.shortDate.string(from: card.updatedAt))
                            InfoRow(label: "Status", value: card.isActive ? "Active" : "Inactive")
                            InfoRow(label: "Reward Categories", value: "\(card.rewardCategories.count)")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditCard = true
                    }
                }
            }
            .sheet(isPresented: $showingEditCard) {
                // TODO: Pass card to AddCardView for editing
                AddCardView()
            }
        }
    }
}

struct RewardCategoryCard: View {
    let category: RewardCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.category.icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Spacer()
                
                Text("\(category.multiplier, specifier: "%.1f")x")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Text(category.category.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            Text(category.pointType.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SpendingLimitCard: View {
    let limit: SpendingLimit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: limit.category.icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(limit.category.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Resets \(limit.resetType.displayName.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(limit.currentSpending.asCurrency) / \(limit.limit.asCurrency)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("\(Int(limit.usagePercentage * 100))% used")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: limit.currentSpending, total: limit.limit)
                .progressViewStyle(LinearProgressViewStyle(tint: limit.isLimitReached ? .red : (limit.isWarningThreshold ? .orange : .blue)))
            
            if limit.isLimitReached {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Spending limit reached")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else if limit.isWarningThreshold {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Approaching spending limit")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

#Preview {
    CardDetailView(card: CreditCard(
        name: "Sample Card",
        cardType: .amexGold,
        rewardCategories: [
            RewardCategory(category: .groceries, multiplier: 4.0, pointType: .membershipRewards)
        ]
    ))
}