import SwiftUI

struct CategoryPickerView: View {
    let onCategorySelected: (SpendingCategory) -> Void

    private let categories: [(SpendingCategory, String)] = [
        (.groceries, "Groceries"),
        (.dining, "Dining"),
        (.gas, "Gas"),
        (.travel, "Travel"),
        (.online, "Online"),
        (.streaming, "Streaming"),
        (.coffee, "Coffee"),
        (.transit, "Transit"),
        (.entertainment, "Fun"),
        (.rent, "Rent"),
        (.drugstores, "Pharmacy"),
        (.general, "Other"),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories, id: \.0) { category, label in
                Button {
                    onCategorySelected(category)
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "00D09C").opacity(0.12))
                                .frame(width: 48, height: 48)
                            Image(systemName: category.icon)
                                .font(.title3)
                                .foregroundColor(Color(hex: "00D09C"))
                        }
                        Text(label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    CategoryPickerView { category in
        print("Selected: \(category.displayName)")
    }
    .padding()
}
