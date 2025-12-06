
import SwiftUI

struct VehicleOptionCard: View {
    let vehicle: VehicleType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(vehicle.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("Up to \(vehicle.maxPassengers) passengers", systemImage: "person.2.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.black : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
