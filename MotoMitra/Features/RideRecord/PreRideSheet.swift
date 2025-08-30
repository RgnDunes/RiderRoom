import SwiftUI

/// Pre-ride sheet for entering ride start details
struct PreRideSheet: View {
    @ObservedObject var viewModel: RecordViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    // Form state
    @State private var selectedVehicle: Vehicle?
    @State private var odometerString = ""
    @State private var fuelLevel: FuelLevel = .half
    @State private var frontTyrePressure = ""
    @State private var rearTyrePressure = ""
    @State private var notes = ""
    @State private var showingVehicleSelector = false
    @State private var showingOdometerError = false
    @State private var odometerErrorMessage = ""
    
    // Validation
    @State private var isValidating = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case odometer
        case frontTyre
        case rearTyre
        case notes
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Vehicle selection
                        vehicleSection
                        
                        // Odometer input (REQUIRED)
                        odometerSection
                        
                        // Fuel level
                        fuelLevelSection
                        
                        // Tyre pressure (optional)
                        tyrePressureSection
                        
                        // Notes (optional)
                        notesSection
                        
                        // Start button
                        startButton
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Pre-Ride Check")
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
        }
        .onAppear {
            loadDefaults()
            focusedField = .odometer
        }
        .sheet(isPresented: $showingVehicleSelector) {
            VehicleSelectionSheet(selectedVehicle: $selectedVehicle)
        }
        .alert("Odometer Validation", isPresented: $showingOdometerError) {
            Button("Continue Anyway") {
                startRide()
            }
            Button("Correct", role: .cancel) {
                focusedField = .odometer
            }
        } message: {
            Text(odometerErrorMessage)
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Text("Pre-Ride Safety Check")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Record your starting odometer and vehicle condition")
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }
    
    private var vehicleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Vehicle", systemImage: "car.fill")
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Button(action: { showingVehicleSelector = true }) {
                HStack {
                    if let vehicle = selectedVehicle {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(vehicle.make) \(vehicle.model)")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text(vehicle.registrationNumber)
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    } else {
                        Text("Select Vehicle")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                .padding(16)
                .background(DesignSystem.Colors.surfaceElevated)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
    }
    
    private var odometerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Start Odometer", systemImage: "speedometer")
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
                        // Format as user types
                        formatOdometerInput(newValue)
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
            
            if let lastOdometer = selectedVehicle?.currentOdometer {
                Text("Last recorded: \(String(format: "%.1f", lastOdometer)) km")
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
    }
    
    private var fuelLevelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Fuel Level", systemImage: "fuelpump.fill")
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FuelLevel.allCases, id: \.self) { level in
                        FuelLevelButton(
                            level: level,
                            isSelected: fuelLevel == level,
                            action: { fuelLevel = level }
                        )
                    }
                }
            }
        }
    }
    
    private var tyrePressureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tyre Pressure (Optional)", systemImage: "circle.circle")
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Front")
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    HStack {
                        TextField("PSI", text: $frontTyrePressure)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .frontTyre)
                        
                        Text("PSI")
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(12)
                    .background(DesignSystem.Colors.surfaceElevated)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rear")
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    HStack {
                        TextField("PSI", text: $rearTyrePressure)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .rearTyre)
                        
                        Text("PSI")
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(12)
                    .background(DesignSystem.Colors.surfaceElevated)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes (Optional)", systemImage: "note.text")
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            TextField("Weather, road conditions, etc.", text: $notes, axis: .vertical)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(3...5)
                .padding(12)
                .background(DesignSystem.Colors.surfaceElevated)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .focused($focusedField, equals: .notes)
        }
    }
    
    private var startButton: some View {
        Button(action: validateAndStart) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                
                Text("Start Recording")
                    .font(DesignSystem.Typography.titleMedium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primaryDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(!isFormValid)
        .opacity(isFormValid ? 1 : 0.6)
        .padding(.top, 20)
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        selectedVehicle != nil && !odometerString.isEmpty
    }
    
    private func validateAndStart() {
        guard let vehicle = selectedVehicle,
              let odometer = Double(odometerString.replacingOccurrences(of: ",", with: "")) else {
            return
        }
        
        // Validate odometer
        if let lastOdometer = vehicle.currentOdometer {
            if odometer < lastOdometer {
                odometerErrorMessage = "Odometer reading (\(String(format: "%.1f", odometer)) km) is less than last recorded value (\(String(format: "%.1f", lastOdometer)) km). This might indicate an error."
                showingOdometerError = true
                return
            }
            
            let difference = odometer - lastOdometer
            if difference > 1000 {
                odometerErrorMessage = "Odometer has increased by \(String(format: "%.0f", difference)) km since last ride. Is this correct?"
                showingOdometerError = true
                return
            }
        }
        
        startRide()
    }
    
    private func startRide() {
        guard let vehicle = selectedVehicle,
              let odometer = Double(odometerString.replacingOccurrences(of: ",", with: "")) else {
            return
        }
        
        // Create tyre pressure if provided
        var tyrePressure: TyrePressure?
        if !frontTyrePressure.isEmpty || !rearTyrePressure.isEmpty {
            tyrePressure = TyrePressure(
                front: Double(frontTyrePressure),
                rear: Double(rearTyrePressure),
                checkedAt: Date()
            )
        }
        
        // Start recording
        viewModel.startRecording(
            vehicle: vehicle,
            startOdometer: odometer,
            fuelLevel: fuelLevel,
            tyrePressure: tyrePressure
        )
        
        dismiss()
    }
    
    // MARK: - Helpers
    
    private func loadDefaults() {
        // Load last used vehicle
        if let vehicleId = appState.selectedVehicle?.id {
            // TODO: Load vehicle from repository
            selectedVehicle = appState.selectedVehicle
        }
        
        // Set default fuel level
        fuelLevel = .half
        
        // Pre-fill last odometer if available
        if let lastOdometer = selectedVehicle?.currentOdometer {
            odometerString = String(format: "%.0f", lastOdometer)
        }
    }
    
    private func formatOdometerInput(_ input: String) {
        // Remove non-numeric characters
        let filtered = input.filter { $0.isNumber || $0 == "." }
        
        // Limit to reasonable odometer range
        if let value = Double(filtered), value > Constants.Odometer.maxValidOdometer {
            odometerString = String(Constants.Odometer.maxValidOdometer)
        } else {
            odometerString = filtered
        }
    }
}

// MARK: - Supporting Views

struct FuelLevelButton: View {
    let level: FuelLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: fuelIcon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.textSecondary)
                
                Text(level.displayName)
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.textSecondary)
            }
            .frame(width: 60, height: 60)
            .background(
                isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceElevated
            )
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
    }
    
    private var fuelIcon: String {
        switch level {
        case .empty: return "fuelpump.slash"
        case .low: return "fuelpump.exclamationmark"
        case .quarter: return "fuelpump"
        case .half: return "fuelpump.fill"
        case .threeQuarter: return "fuelpump.fill"
        case .full: return "fuelpump.circle.fill"
        }
    }
}

struct VehicleSelectionSheet: View {
    @Binding var selectedVehicle: Vehicle?
    @Environment(\.dismiss) private var dismiss
    
    // TODO: Load vehicles from repository
    let vehicles = SampleDataGenerator.generateVehicles()
    
    var body: some View {
        NavigationView {
            List(vehicles, id: \.id) { vehicle in
                Button(action: {
                    selectedVehicle = vehicle
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(vehicle.make) \(vehicle.model)")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text(vehicle.registrationNumber)
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        if selectedVehicle?.id == vehicle.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add New") {
                        // TODO: Navigate to add vehicle
                    }
                }
            }
        }
    }
}