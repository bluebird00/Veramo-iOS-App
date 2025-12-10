import SwiftUI


struct DatePickerCard: View {
    let title: LocalizedStringKey
    let icon: String
    @Binding var date: Date
    let displayedComponents: DatePickerComponents
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            DatePicker(
                "",
                selection: $date,
                displayedComponents: displayedComponents
            )
            .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
