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
    
    // Fixed 30-minute blocks from 11:30 to 20:30 (inclusive start times)
    private var timeSlots: [TimeSlot] {
        var slots: [TimeSlot] = []
        // Generate from 11:30 up to 20:30
        var hour = 11
        var minute = 30
        while hour < 21 { // last start 20:30
            // OFF window 15:00 - 16:00 (skip 15:00 and 15:30)
            if !(hour == 15) {
                slots.append(TimeSlot(hour: hour, minute: minute))
            }
            minute += 30
            if minute >= 60 {
                minute = 0
                hour += 1
            }
        }
        return slots
    }
    
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
    
    // Get available time slots for today (Australia/Sydney); hides past times
    private func getAvailableTimeSlotsForToday() -> [TimeSlot] {
        var calendar = Calendar.current
        calendar.timeZone = australiaTimeZone
        let nowSydney = Date()
        let currentTime = calendar.dateComponents([.hour, .minute], from: nowSydney)
        let rawMinutes = (currentTime.hour ?? 0) * 60 + (currentTime.minute ?? 0)
        // Round up to the next half-hour boundary
        let nextHalfHour: Int = {
            let remainder = rawMinutes % 30
            return remainder == 0 ? rawMinutes : rawMinutes + (30 - remainder)
        }()
        
        return timeSlots.filter { timeSlot in
            let slotMinutes = timeSlot.hour * 60 + timeSlot.minute
            return slotMinutes >= nextHalfHour
        }
    }
    
    // Update selectedDateTime when time is selected (always for today)
    private func updateSelectedDateTime() {
        guard let timeSlot = selectedTimeSlot else { return }
        var calendar = Calendar.current
        calendar.timeZone = australiaTimeZone
        let todaySydney = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: todaySydney)
        components.hour = timeSlot.hour
        components.minute = timeSlot.minute
        components.second = 0
        
        if let dateTimeSydney = calendar.date(from: components) {
            selectedDateTime = dateTimeSydney
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
        // Display as a range: HH:mm - HH:mm in Australia/Sydney
        let tz = TimeZone(identifier: "Australia/Sydney")
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "HH:mm"
        
        var calendar = Calendar.current
        calendar.timeZone = tz ?? .current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        guard let start = calendar.date(from: components),
              let end = calendar.date(byAdding: .minute, value: 30, to: start) else {
            return "\(hour):\(String(format: "%02d", minute))"
        }
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
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
