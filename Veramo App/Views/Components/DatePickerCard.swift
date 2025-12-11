import SwiftUI


struct DatePickerCard: View {
    let title: LocalizedStringKey
    let icon: String
    @Binding var date: Date
    let displayedComponents: DatePickerComponents
    var timeZone: TimeZone = .current  // Add optional timezone parameter
    
    @Environment(\.calendar) private var calendar
    @State private var showingTimePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if displayedComponents == .hourAndMinute {
                // Custom time picker with 5-minute increments
                FiveMinuteTimePicker(date: $date, timeZone: timeZone, showingPicker: $showingTimePicker)
            } else {
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: displayedComponents
                )
                .labelsHidden()
                .environment(\.timeZone, timeZone)  // Set the timezone for display
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .fullScreenCover(isPresented: $showingTimePicker) {
            TimePickerModal(
                showingPicker: $showingTimePicker,
                date: $date,
                timeZone: timeZone
            )
            .presentationBackground(.clear)
        }
    }
}

// MARK: - Five Minute Time Picker
struct FiveMinuteTimePicker: View {
    @Binding var date: Date
    let timeZone: TimeZone
    @Binding var showingPicker: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showingPicker = true
            }
        }) {
            Text(formattedTime)
                .font(.system(.body, design: .default))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(UIColor.quaternarySystemFill))
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var formattedTime: String {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - Time Picker Modal
private struct TimePickerModal: View {
    @Binding var showingPicker: Bool
    @Binding var date: Date
    let timeZone: TimeZone
    
    @State private var selectedHour: Int = 0
    @State private var selectedMinute: Int = 0
    
    // Create a large range for infinite scrolling effect
    private let hourRange = 0..<(24 * 100) // 100 repetitions of 0-23
    private let minuteRange = 0..<(12 * 100) // 100 repetitions of 0-55 (12 values * 100)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-screen transparent background
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingPicker = false
                    }
                }
            
            // Picker card at bottom center
            HStack {
                Spacer()
                
                VStack(spacing: 0) {
                    ZStack {
                        // Unified pill-shaped highlight for selected row - positioned behind
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(UIColor.quaternarySystemFill))
                            .frame(width: 160, height: 36)
                            .allowsHitTesting(false)
                        
                        HStack(spacing: 0) {
                            // Hour picker (infinite loop)
                            Picker("Hour", selection: $selectedHour) {
                                ForEach(hourRange, id: \.self) { index in
                                    let hour = index % 24
                                    Text(String(format: "%02d", hour))
                                        .tag(index)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            .clipped()
                            
                            Text(":")
                                .font(.title)
                                .foregroundColor(.primary)
                                .frame(width: 20)
                            
                            // Minute picker (5-minute increments, infinite loop)
                            Picker("Minute", selection: $selectedMinute) {
                                ForEach(minuteRange, id: \.self) { index in
                                    let minute = (index % 12) * 5
                                    Text(String(format: "%02d", minute))
                                        .tag(index)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            .clipped()
                        }
                    }
                    .padding()
                }
                .frame(width: 240, height: 200)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 40, x: 0, y: 20)
                
                Spacer()
            }
            .padding(.bottom, 180)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            updatePickerFromDate()
        }
        .onChange(of: selectedHour) { oldValue, newValue in
            updateDateFromPicker()
        }
        .onChange(of: selectedMinute) { oldValue, newValue in
            updateDateFromPicker()
        }
    }
    
    private func updatePickerFromDate() {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        
        // Round to nearest 5 minutes
        let rawMinute = components.minute ?? 0
        let minute = (rawMinute / 5) * 5
        
        // Set to middle of range to allow scrolling in both directions
        let hourOffset = 24 * 50 // Middle of 100 repetitions
        let minuteOffset = 12 * 50 // Middle of 100 repetitions
        
        selectedHour = hourOffset + hour
        selectedMinute = minuteOffset + (minute / 5)
    }
    
    private func updateDateFromPicker() {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        
        // Extract actual hour and minute from the looping ranges
        let hour = selectedHour % 24
        let minute = (selectedMinute % 12) * 5
        
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        if let newDate = calendar.date(from: DateComponents(
            year: components.year,
            month: components.month,
            day: components.day,
            hour: hour,
            minute: minute
        )) {
            date = newDate
        }
    }
}
