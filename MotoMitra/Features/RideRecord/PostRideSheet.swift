import SwiftUI

/// Post-ride sheet for entering ride end details
struct PostRideSheet: View {
    @ObservedObject var viewModel: RecordViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var odometerString = ""
    @State private var selectedTags: Set<String> = []
    @State private var customTag = ""
    @State private var notes = ""
    @State private var showingOdometerError = false
    @State private var odometerErrorMessage = ""
    @State private var isSaving = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case odometer
        case customTag
        case notes
    }
    
    // Predefined tags
    let quickTags = [
        "Highway", "City", "Traffic", "Clear Roads",
        "Heavy Rain", "Light Rain", "Foggy", "Night Ride",
        "Offroad", "Twisties", "Touring", "Commute",
        "Group Ride", "Solo", "Adventure"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Summary header
                        summaryHeader
                        
                        // Odometer input (REQUIRED)
                        odometerSection
                        
                        // Distance comparison
                        if let ride = viewModel.currentRide {
                            distanceComparison(ride: ride)
                        }
                        
                        // Quick tags
                        tagsSection
                        
                        // Notes
                        notesSection
                        
                        // Save button
                        saveButton
                    }
                    .padding(20)
                }
                
                if isSaving {
                    savingOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Show confirmation if data entered
                        if !odometerString.isEmpty || !selectedTags.isEmpty || !notes.isEmpty {
                            // TODO: Show confirmation dialog
                        }
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Ride Complete")
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
        }
        .onAppear {
            loadDefaults()
            focusedField = .odometer
        }
        .alert("Odometer Validation", isPresented: $showingOdometerError) {
            Button("Continue Anyway") {
                saveRide()
            }
            Button("Correct", role: .cancel) {
                focusedField = .odometer
            }
        } message: {
            Text(odometerErrorMessage)
        }
    }
    
    // MARK: - Sections
    
    private var summaryHeader: some View {
        VStack(spacing: 16) {
            // Completion icon
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.success.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(DesignSystem.Colors.success)
            }
            
            Text("Great Ride!")
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Quick stats
            if let ride = viewModel.currentRide {
                HStack(spacing: 30) {
                    VStack(spacing: 4) {
                        Text(formatDuration(ride.duration))
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Duration")
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f km", ride.gpsDistance))
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Distance")
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f km/h", ride.averageSpeed))
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Avg Speed")
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(DesignSystem.Colors.surfaceElevated)
                .cornerRadius(DesignSystem.CornerRadius.lg)
            }
        }
    }
    
    private var odometerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("End Odometer", systemImage: "speedometer")
                    .font(DesignSystem.Typography.labelMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("(Required)")
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.error)
            }
            
            HStack {
                TextField("Enter odometer reading", text: $odometerString)
                    .font(DesignSystem.Typography.odometer)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .odometer)
                    .onChange(of: odometerString) { _, newValue in
                        formatOdometerInput(newValue)
                        updateDistanceComparison()
                    }
                
                Text("km")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(16)
            .background(DesignSystem.Colors.surfaceElevated)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        focusedField == .odometer ? DesignSystem.Colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
            
            if let startOdometer = viewModel.currentRide?.startOdometer {
                Text("Start odometer: \(String(format: "%.1f", startOdometer)) km")
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
    }
    
    private func distanceComparison(ride: Ride) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distance Verification")
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack(spacing: 20) {
                // GPS distance
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Text("GPS")
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    
                    Text(String(format: "%.1f km", ride.gpsDistance))
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                // Odometer distance
                if let endOdometer = Double(odometerString.replacingOccurrences(of: ",", with: "")),
                   let odometerDistance = calculateOdometerDistance(endOdometer: endOdometer) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "speedometer")
                                .font(.system(size: 12))
                                .foregroundColor(DesignSystem.Colors.secondary)
                            
                            Text("Odometer")
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                        
                        Text(String(format: "%.1f km", odometerDistance))
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    
                    // Difference
                    let difference = abs(odometerDistance - ride.gpsDistance)
                    let percentage = (difference / ride.gpsDistance) * 100
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Difference")
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: percentage > 10 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(percentage > 10 ? DesignSystem.Colors.warning : DesignSystem.Colors.success)
                            
                            Text(String(format: "%.1f%% (%.1f km)", percentage, difference))
                                .font(DesignSystem.Typography.bodySmall)
                                .foregroundColor(percentage > 10 ? DesignSystem.Colors.warning : DesignSystem.Colors.success)
                        }
                    }
                }
            }
            .padding(12)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tags", systemImage: "tag.fill")
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            // Quick tags
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: 8)
            ], spacing: 8) {
                ForEach(quickTags, id: \.self) { tag in
                    TagButton(
                        tag: tag,
                        isSelected: selectedTags.contains(tag),
                        action: {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    )
                }
            }
            
            // Custom tag input
            HStack {
                TextField("Add custom tag", text: $customTag)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .focused($focusedField, equals: .customTag)
                    .onSubmit {
                        addCustomTag()
                    }
                
                Button(action: addCustomTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .disabled(customTag.isEmpty)
            }
            .padding(12)
            .background(DesignSystem.Colors.surfaceElevated)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes (Optional)", systemImage: "note.text")
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            TextField("How was the ride? Any issues or highlights?", text: $notes, axis: .vertical)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(4...8)
                .padding(12)
                .background(DesignSystem.Colors.surfaceElevated)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .focused($focusedField, equals: .notes)
        }
    }
    
    private var saveButton: some View {
        Button(action: validateAndSave) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                
                Text("Save Ride")
                    .font(DesignSystem.Typography.titleMedium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [DesignSystem.Colors.success, DesignSystem.Colors.success.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .shadow(color: DesignSystem.Colors.success.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(!isFormValid || isSaving)
        .opacity(isFormValid && !isSaving ? 1 : 0.6)
        .padding(.top, 20)
    }
    
    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Saving ride...")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.lg)
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !odometerString.isEmpty
    }
    
    private func validateAndSave() {
        guard let endOdometer = Double(odometerString.replacingOccurrences(of: ",", with: "")),
              let ride = viewModel.currentRide else {
            return
        }
        
        // Validate odometer
        if endOdometer < ride.startOdometer {
            odometerErrorMessage = "End odometer (\(String(format: "%.1f", endOdometer)) km) cannot be less than start odometer (\(String(format: "%.1f", ride.startOdometer)) km)."
            showingOdometerError = true
            return
        }
        
        // Check for large discrepancy
        if let odometerDistance = calculateOdometerDistance(endOdometer: endOdometer) {
            let discrepancy = abs(odometerDistance - ride.gpsDistance) / ride.gpsDistance
            
            if discrepancy > Constants.Odometer.maxDiscrepancyPercent {
                odometerErrorMessage = """
                There's a \(String(format: "%.0f%%", discrepancy * 100)) difference between GPS distance (\(String(format: "%.1f", ride.gpsDistance)) km) and odometer distance (\(String(format: "%.1f", odometerDistance)) km).
                
                Would you like to reconcile this difference?
                """
                // This would trigger reconciliation flow
                viewModel.showOdometerReconciliation = true
                return
            }
        }
        
        saveRide()
    }
    
    private func saveRide() {
        guard let endOdometer = Double(odometerString.replacingOccurrences(of: ",", with: "")) else {
            return
        }
        
        isSaving = true
        
        // Combine selected tags and custom tags
        var allTags = Array(selectedTags)
        if !customTag.isEmpty {
            allTags.append(customTag)
        }
        
        // Save ride
        viewModel.saveRide(
            endOdometer: endOdometer,
            tags: allTags,
            notes: notes.isEmpty ? nil : notes
        )
        
        // Simulate save delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSaving = false
            dismiss()
        }
    }
    
    // MARK: - Helpers
    
    private func loadDefaults() {
        // Suggest end odometer based on GPS distance
        if let ride = viewModel.currentRide {
            let suggestedOdometer = ride.startOdometer + ride.gpsDistance
            odometerString = String(format: "%.0f", suggestedOdometer)
        }
    }
    
    private func formatOdometerInput(_ input: String) {
        let filtered = input.filter { $0.isNumber || $0 == "." }
        
        if let value = Double(filtered), value > Constants.Odometer.maxValidOdometer {
            odometerString = String(Constants.Odometer.maxValidOdometer)
        } else {
            odometerString = filtered
        }
    }
    
    private func updateDistanceComparison() {
        // Trigger UI update for distance comparison
    }
    
    private func calculateOdometerDistance(endOdometer: Double) -> Double? {
        guard let ride = viewModel.currentRide else { return nil }
        return endOdometer - ride.startOdometer
    }
    
    private func addCustomTag() {
        guard !customTag.isEmpty else { return }
        
        selectedTags.insert(customTag)
        customTag = ""
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Supporting Views

struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceElevated
                )
                .cornerRadius(DesignSystem.CornerRadius.full)
        }
    }
}