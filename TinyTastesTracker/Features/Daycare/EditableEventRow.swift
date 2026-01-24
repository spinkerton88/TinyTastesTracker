//
//  EditableEventRow.swift
//  TinyTastesTracker
//
//  Editable row component for reviewing and editing parsed daycare events
//

import SwiftUI

struct EditableEventRow: View {
    @Binding var event: SuggestedLog
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack {
                // Confirmation status indicator
                Image(systemName: event.isConfirmed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(event.isConfirmed ? .green : .red)
                    .font(.caption)
                
                // Type Icon
                Image(systemName: iconForType(event.type))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(colorForType(event.type))
                    .clipShape(Circle())
                
                Text(event.type.rawValue.capitalized)
                    .font(.headline)
                
                Spacer()
                
                // Duplicate warning badge
                if event.isDuplicate {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
                
                Text(event.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Expand/collapse button
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Duplicate warning message
            if event.isDuplicate, let reason = event.duplicateReason {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text(reason)
                        .font(.caption)
                }
                .foregroundStyle(.yellow)
                .padding(6)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Collapsed view - basic info
            if !isExpanded {
                if !event.details.isEmpty {
                    Text(event.details)
                        .font(.body)
                        .lineLimit(2)
                }
                
                if let quantity = event.quantity {
                    Text("Amt: \(quantity)")
                        .font(.caption)
                        .padding(4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            // Expanded view - editable fields
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Start time picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        DatePicker("", selection: Binding(
                            get: { event.startTime },
                            set: { newValue in
                                event = SuggestedLog(
                                    type: event.type,
                                    startTime: newValue,
                                    endTime: event.endTime,
                                    quantity: event.quantity,
                                    details: event.details,
                                    isConfirmed: event.isConfirmed,
                                    isWet: event.isWet,
                                    isDirty: event.isDirty,
                                    isDuplicate: event.isDuplicate,
                                    duplicateReason: event.duplicateReason
                                )
                            }
                        ), displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                    }
                    
                    // End time picker (for sleep)
                    if event.type == .sleep {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("End Time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            DatePicker("", selection: Binding(
                                get: { event.endTime ?? event.startTime.addingTimeInterval(3600) },
                                set: { newValue in
                                    event = SuggestedLog(
                                        type: event.type,
                                        startTime: event.startTime,
                                        endTime: newValue,
                                        quantity: event.quantity,
                                        details: event.details,
                                        isConfirmed: event.isConfirmed,
                                        isWet: event.isWet,
                                        isDirty: event.isDirty,
                                        isDuplicate: event.isDuplicate,
                                        duplicateReason: event.duplicateReason
                                    )
                                }
                            ), displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                        }
                    }
                    
                    // Quantity field
                    if event.type == .feed {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quantity")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("e.g., 5 oz", text: Binding(
                                get: { event.quantity ?? "" },
                                set: { newValue in
                                    event = SuggestedLog(
                                        type: event.type,
                                        startTime: event.startTime,
                                        endTime: event.endTime,
                                        quantity: newValue.isEmpty ? nil : newValue,
                                        details: event.details,
                                        isConfirmed: event.isConfirmed,
                                        isWet: event.isWet,
                                        isDirty: event.isDirty,
                                        isDuplicate: event.isDuplicate,
                                        duplicateReason: event.duplicateReason
                                    )
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    // Diaper type picker
                    if event.type == .diaper {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Diaper Type")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 12) {
                                Toggle("Wet", isOn: Binding(
                                    get: { event.isWet ?? false },
                                    set: { newValue in
                                        event = SuggestedLog(
                                            type: event.type,
                                            startTime: event.startTime,
                                            endTime: event.endTime,
                                            quantity: event.quantity,
                                            details: event.details,
                                            isConfirmed: event.isConfirmed,
                                            isWet: newValue,
                                            isDirty: event.isDirty,
                                            isDuplicate: event.isDuplicate,
                                            duplicateReason: event.duplicateReason
                                        )
                                    }
                                ))
                                .toggleStyle(.button)
                                
                                Toggle("Dirty", isOn: Binding(
                                    get: { event.isDirty ?? false },
                                    set: { newValue in
                                        event = SuggestedLog(
                                            type: event.type,
                                            startTime: event.startTime,
                                            endTime: event.endTime,
                                            quantity: event.quantity,
                                            details: event.details,
                                            isConfirmed: event.isConfirmed,
                                            isWet: event.isWet,
                                            isDirty: newValue,
                                            isDuplicate: event.isDuplicate,
                                            duplicateReason: event.duplicateReason
                                        )
                                    }
                                ))
                                .toggleStyle(.button)
                            }
                        }
                    }
                    
                    // Details/notes
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Details")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Notes", text: Binding(
                            get: { event.details },
                            set: { newValue in
                                event = SuggestedLog(
                                    type: event.type,
                                    startTime: event.startTime,
                                    endTime: event.endTime,
                                    quantity: event.quantity,
                                    details: newValue,
                                    isConfirmed: event.isConfirmed,
                                    isWet: event.isWet,
                                    isDirty: event.isDirty,
                                    isDuplicate: event.isDuplicate,
                                    duplicateReason: event.duplicateReason
                                )
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForType(_ type: SuggestedLogType) -> String {
        switch type {
        case .sleep: return "bed.double.fill"
        case .feed: return "fork.knife"
        case .diaper: return "toilet.fill"
        case .activity: return "figure.play"
        case .other: return "doc.text"
        }
    }
    
    private func colorForType(_ type: SuggestedLogType) -> Color {
        switch type {
        case .sleep: return .indigo
        case .feed: return .orange
        case .diaper: return .blue
        case .activity: return .green
        case .other: return .gray
        }
    }
}
