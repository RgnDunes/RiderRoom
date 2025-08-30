import SwiftUI
import MapKit

/// Main recording view for rides
struct RecordView: View {
    @StateObject private var viewModel = Container.shared.resolve(RecordViewModel.self)
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: NavigationRouter
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090), // Delhi
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showingModeToggle = false
    
    var body: some View {
        ZStack {
            // Map view
            MapView(region: $mapRegion,
                   routePolyline: viewModel.routePolyline,
                   currentLocation: viewModel.currentLocation?.coordinate)
                .ignoresSafeArea()
            
            // Overlay controls
            VStack {
                // Top bar
                topBar
                
                Spacer()
                
                // Metrics card
                if viewModel.recordingState != .notStarted {
                    metricsCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Control buttons
                controlButtons
                    .padding(.bottom, 30)
            }
            
            // Auto-detection indicator
            if viewModel.isAutoDetecting && viewModel.autoDetectionCountdown > 0 {
                autoDetectionOverlay
            }
        }
        .sheet(isPresented: $viewModel.showPreRideSheet) {
            PreRideSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showPostRideSheet) {
            PostRideSheet(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $viewModel.showOdometerReconciliation) {
            if let ride = viewModel.currentRide {
                OdometerReconciliationView(ride: ride, viewModel: viewModel)
            }
        }
        .onAppear {
            setupMap()
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Recording mode toggle
            Button(action: { showingModeToggle.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: appState.recordingMode == .auto ? "wand.and.stars" : "hand.tap.fill")
                        .font(.system(size: 14))
                    Text(appState.recordingMode.displayName)
                        .font(DesignSystem.Typography.labelMedium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(DesignSystem.CornerRadius.full)
            }
            
            Spacer()
            
            // Recording indicator
            if viewModel.recordingState == .recording {
                RecordingIndicator()
            } else if viewModel.recordingState == .paused {
                PausedIndicator()
            }
            
            Spacer()
            
            // Settings button
            Button(action: { router.navigate(to: .settings) }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .confirmationDialog("Recording Mode", isPresented: $showingModeToggle) {
            Button("Auto") {
                appState.recordingMode = .auto
                viewModel.startAutoDetection()
            }
            Button("Manual") {
                appState.recordingMode = .manual
            }
        }
    }
    
    // MARK: - Metrics Card
    private var metricsCard: some View {
        VStack(spacing: 0) {
            // Primary metrics
            HStack(spacing: 30) {
                MetricView(
                    value: formatTime(viewModel.elapsedTime),
                    label: "Duration",
                    icon: "clock.fill"
                )
                
                MetricView(
                    value: String(format: "%.1f", viewModel.distance),
                    label: "Distance",
                    unit: "km",
                    icon: "location.fill"
                )
                
                MetricView(
                    value: String(format: "%.0f", viewModel.currentSpeed),
                    label: "Speed",
                    unit: "km/h",
                    icon: "speedometer"
                )
            }
            .padding(.vertical, 16)
            
            Divider()
                .background(DesignSystem.Colors.textTertiary.opacity(0.3))
            
            // Secondary metrics
            HStack(spacing: 30) {
                SubMetricView(
                    label: "Avg Speed",
                    value: String(format: "%.0f km/h", viewModel.averageSpeed)
                )
                
                SubMetricView(
                    label: "Max Speed",
                    value: String(format: "%.0f km/h", viewModel.maxSpeed)
                )
                
                SubMetricView(
                    label: "Elevation",
                    value: String(format: "%.0f m", viewModel.currentLocation?.altitude ?? 0)
                )
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 20)
        .background(
            DesignSystem.Colors.surface
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                )
        )
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 20) {
            if viewModel.recordingState == .notStarted {
                // Start button
                Button(action: startRecording) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primary)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: DesignSystem.Colors.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                
            } else if viewModel.recordingState == .recording {
                // Pause button
                Button(action: { viewModel.pauseRecording() }) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.warning)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "pause.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                
                // Stop button
                Button(action: { viewModel.stopRecording() }) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.error)
                            .frame(width: 80, height: 80)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                    }
                }
                .shadow(color: DesignSystem.Colors.error.opacity(0.4), radius: 10, x: 0, y: 5)
                
            } else if viewModel.recordingState == .paused {
                // Resume button
                Button(action: { viewModel.resumeRecording() }) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.success)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                
                // Stop button
                Button(action: { viewModel.stopRecording() }) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.error)
                            .frame(width: 80, height: 80)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                    }
                }
                .shadow(color: DesignSystem.Colors.error.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            
            // Add waypoint button (when recording)
            if viewModel.recordingState == .recording || viewModel.recordingState == .paused {
                Button(action: addWaypoint) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.surface)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 20))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Auto Detection Overlay
    private var autoDetectionOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Text("Ride Detected")
                .font(DesignSystem.Typography.headlineSmall)
            
            Text("Starting in \(viewModel.autoDetectionCountdown) seconds")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    // Cancel auto-start
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Start Now") {
                    viewModel.showPreRideSheet = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(24)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.xl)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(40)
    }
    
    // MARK: - Actions
    private func startRecording() {
        if appState.recordingMode == .manual {
            viewModel.showPreRideSheet = true
        }
    }
    
    private func addWaypoint() {
        // TODO: Show waypoint dialog
    }
    
    private func setupMap() {
        if let location = viewModel.currentLocation {
            mapRegion.center = location.coordinate
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Supporting Views
struct MetricView: View {
    let value: String
    let label: String
    var unit: String? = nil
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.primary)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if let unit = unit {
                    Text(unit)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .offset(y: 4)
                }
            }
            
            Text(label)
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
    }
}

struct SubMetricView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            Text(value)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct RecordingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(DesignSystem.Colors.error)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0.6 : 1.0)
            
            Text("RECORDING")
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(DesignSystem.Colors.error)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.full)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

struct PausedIndicator: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "pause.fill")
                .font(.system(size: 10))
                .foregroundColor(DesignSystem.Colors.warning)
            
            Text("PAUSED")
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(DesignSystem.Colors.warning)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.full)
    }
}