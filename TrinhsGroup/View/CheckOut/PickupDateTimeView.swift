//
//  PickupDateTimeView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI

struct PickupDateTimeView: View {
    @Binding var selectedDateTime: Date?
    @State private var showTimePicker = false
    @State private var selectedTimeSlot: TimeSlot?
    
    // Australia timezone
    private let australiaTimeZone = TimeZone(identifier: "Australia/Sydney") ?? TimeZone.current
    
    // Available time slots (30-minute intervals)
    private let timeSlots: [TimeSlot] = [
        TimeSlot(hour: 11, minute: 0),  // 11:00 AM
        TimeSlot(hour: 11, minute: 30), // 11:30 AM
        TimeSlot(hour: 12, minute: 0),  // 12:00 PM
        TimeSlot(hour: 12, minute: 30), // 12:30 PM
        TimeSlot(hour: 13, minute: 0),  // 1:00 PM
        TimeSlot(hour: 13, minute: 30), // 1:30 PM
        TimeSlot(hour: 14, minute: 0),  // 2:00 PM
        TimeSlot(hour: 14, minute: 30), // 2:30 PM
        // Break from 15:00 to 16:30 (3:00 PM to 4:30 PM)
        TimeSlot(hour: 16, minute: 30), // 4:30 PM
        TimeSlot(hour: 17, minute: 0),  // 5:00 PM
        TimeSlot(hour: 17, minute: 30), // 5:30 PM
        TimeSlot(hour: 18, minute: 0),  // 6:00 PM
        TimeSlot(hour: 18, minute: 30), // 6:30 PM
        TimeSlot(hour: 19, minute: 0),  // 7:00 PM
        TimeSlot(hour: 19, minute: 30), // 7:30 PM
        TimeSlot(hour: 20, minute: 0),  // 8:00 PM
        TimeSlot(hour: 20, minute: 30)  // 8:30 PM
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pickup Time (Today Only)")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Today's Date Display (Read-only)
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Today: \(formatTodayDate())")
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            
            // Time Selection Button
            Button(action: {
                showTimePicker = true
            }) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text(selectedTimeSlot != nil ? selectedTimeSlot!.displayText : "Select Pickup Time")
                        .foregroundColor(selectedTimeSlot != nil ? .primary : .gray)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selectedTimeSlot != nil ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Selected DateTime Display
            if let dateTime = selectedDateTime {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Selected: \(formatFullDateTime(dateTime))")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showTimePicker) {
            TimeSlotPickerSheet(
                selectedTimeSlot: $selectedTimeSlot,
                availableTimeSlots: getAvailableTimeSlotsForToday(),
                onTimeSelected: { timeSlot in
                    selectedTimeSlot = timeSlot
                    showTimePicker = false
                    updateSelectedDateTime()
                }
            )
        }
    }
    
    // Get available time slots for today only
    private func getAvailableTimeSlotsForToday() -> [TimeSlot] {
        let calendar = Calendar.current
        let now = Date()
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = currentTime.hour! * 60 + currentTime.minute!
        
        return timeSlots.filter { timeSlot in
            let slotMinutes = timeSlot.hour * 60 + timeSlot.minute
            return slotMinutes > currentMinutes
        }
    }
    
    // Update selectedDateTime when time is selected (always for today)
    private func updateSelectedDateTime() {
        guard let timeSlot = selectedTimeSlot else { return }
        
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.hour = timeSlot.hour
        components.minute = timeSlot.minute
        components.second = 0
        
        // Convert to Australia timezone
        if let dateTime = calendar.date(from: components) {
            selectedDateTime = dateTime
        }
    }
    
    // Format today's date for display
    private func formatTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        formatter.timeZone = australiaTimeZone
        return formatter.string(from: Date())
    }
    
    // Format full date and time for display
    private func formatFullDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy 'at' h:mm a"
        formatter.timeZone = australiaTimeZone
        return formatter.string(from: date)
    }
}

// TimeSlot struct to represent available time slots
struct TimeSlot: Identifiable, Equatable {
    let id = UUID()
    let hour: Int
    let minute: Int
    
    var displayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):\(String(format: "%02d", minute))"
    }
}

// Time Slot Picker Sheet
struct TimeSlotPickerSheet: View {
    @Binding var selectedTimeSlot: TimeSlot?
    let availableTimeSlots: [TimeSlot]
    let onTimeSelected: (TimeSlot) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(availableTimeSlots) { timeSlot in
                Button(action: {
                    onTimeSelected(timeSlot)
                }) {
                    HStack {
                        Text(timeSlot.displayText)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedTimeSlot == timeSlot {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Pickup Time")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct PickupDateTimeView_Previews: PreviewProvider {
    @State static var selectedDateTime: Date? = nil
    
    static var previews: some View {
        PickupDateTimeView(selectedDateTime: $selectedDateTime)
            .padding()
    }
}
