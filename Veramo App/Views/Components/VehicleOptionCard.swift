
import SwiftUI

struct VehicleOptionCard: View {
    let vehicle: VehicleType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Vehicle image - spans both rows
            Group {
                if vehicle.useSystemImage {
                    Image(systemName: vehicle.imageName)
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                } else {
                    Image(vehicle.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(width: 90, height: 90)
            
            // Right side: Two rows of content
            VStack(alignment: .leading, spacing: 8) {
                // First row: Name and Price
                HStack {
                    Text(vehicle.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let priceFormatted = vehicle.priceFormatted {
                        Text(priceFormatted)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                
                // Second row: Passengers and Description
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                        Text("\(vehicle.maxPassengers)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Text(vehicle.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.black : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
