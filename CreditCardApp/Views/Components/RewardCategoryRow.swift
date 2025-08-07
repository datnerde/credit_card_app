import SwiftUI

struct RewardCategoryRow: View {
    let category: SpendingCategory
    let isSelected: Bool
    let multiplier: Double
    let pointType: PointType
    let onToggle: (Bool) -> Void
    let onMultiplierChange: (Double) -> Void
    let onPointTypeChange: (PointType) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(category.displayName)
                    .font(.subheadline)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { isSelected },
                    set: { onToggle($0) }
                ))
                .toggleStyle(SwitchToggleStyle())
            }
            
            if isSelected {
                VStack(spacing: 8) {
                    HStack {
                        Text("Multiplier:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        TextField("Multiplier", value: Binding(
                            get: { multiplier },
                            set: { onMultiplierChange($0) }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                        
                        Text("x")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Point Type:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Picker("Point Type", selection: Binding(
                            get: { pointType },
                            set: { onPointTypeChange($0) }
                        )) {
                            ForEach(PointType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#Preview {
    RewardCategoryRow(
        category: .groceries,
        isSelected: true,
        multiplier: 4.0,
        pointType: .membershipRewards,
        onToggle: { _ in },
        onMultiplierChange: { _ in },
        onPointTypeChange: { _ in }
    )
    .padding()
}