import Foundation

/// Mock configuration for testing without API keys
struct Configuration {
    static let googleMapsAPIKey: String? = "MOCK_API_KEY"
    static let googlePlacesAPIKey: String? = "MOCK_API_KEY"
    static let firebaseAPIKey: String? = "MOCK_API_KEY"
    
    static let isMockMode = true
}

/// Mock implementations for testing
extension UserDefaults {
    var recordingMode: RecordingMode {
        get { return .auto }
        set { }
    }
}

/// Simplified main view for testing
import SwiftUI

struct TestMainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationView {
                VStack(spacing: 20) {
                    Text("MotoMitra")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Your Motorcycle Companion")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Start Ride Button
                    Button(action: {
                        print("Start Ride tapped")
                    }) {
                        Label("Start Ride", systemImage: "play.circle.fill")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding()
                    
                    Spacer()
                }
                .navigationTitle("Home")
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Rides Tab
            NavigationView {
                List {
                    ForEach(MockData.rides) { ride in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ride.title ?? "Ride")
                                .font(.headline)
                            HStack {
                                Label("\(String(format: "%.1f", ride.gpsDistance)) km", 
                                      systemImage: "location.fill")
                                Spacer()
                                Text(ride.startTime.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Rides")
            }
            .tabItem {
                Label("Rides", systemImage: "location.circle.fill")
            }
            .tag(1)
            
            // Expenses Tab
            NavigationView {
                List {
                    ForEach(MockData.expenses) { expense in
                        HStack {
                            Image(systemName: expense.category.icon)
                                .foregroundColor(expense.category.color)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(expense.description ?? expense.category.rawValue)
                                    .font(.headline)
                                Text("₹\(String(format: "%.2f", expense.amount))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(expense.timestamp.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Expenses")
            }
            .tabItem {
                Label("Expenses", systemImage: "indianrupeesign.circle.fill")
            }
            .tag(2)
            
            // Vehicles Tab
            NavigationView {
                List {
                    ForEach(MockData.vehicles, id: \.id) { vehicle in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(vehicle.make) \(vehicle.model)")
                                .font(.headline)
                            Text(vehicle.registrationNumber)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack {
                                Label("\(String(format: "%.0f", vehicle.currentOdometer)) km", 
                                      systemImage: "speedometer")
                                    .font(.caption)
                                Spacer()
                                Text("\(vehicle.year)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Vehicles")
            }
            .tabItem {
                Label("Vehicles", systemImage: "car.fill")
            }
            .tag(3)
        }
        .accentColor(.orange)
    }
}

/// Mock data for testing
struct MockData {
    static let rides = SampleDataGenerator.generateRides()
    static let expenses = SampleDataGenerator.generateExpenses()
    static let vehicles = SampleDataGenerator.generateVehicles()
    static let rooms = SampleDataGenerator.generateRideRooms()
    static let members = SampleDataGenerator.generateRoomMembers()
}

/// Simplified app for testing
@main
struct MotoMitraTestApp: App {
    var body: some Scene {
        WindowGroup {
            TestMainView()
        }
    }
}