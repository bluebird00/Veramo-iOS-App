import SwiftUI


struct DatePickerCard: View {
    let title: LocalizedStringKey
    let icon: String
    @Binding var date: Date
    let displayedComponents: DatePickerComponents
    var timeZone: TimeZone = .current  // Add optional timezone parameter
    
    @Environment(\.calendar) private var calendar
    
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
            .environment(\.timeZone, timeZone)  // Set the timezone for display
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
