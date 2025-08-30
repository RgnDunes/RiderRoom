import Foundation
import CoreLocation

/// Sample data generator for testing and development
class SampleDataGenerator {
    
    // MARK: - Vehicles
    
    static func generateVehicles() -> [Vehicle] {
        return [
            Vehicle(
                id: "vehicle_1",
                make: "Royal Enfield",
                model: "Classic 350",
                year: 2022,
                registrationNumber: "DL 01 AB 1234",
                engineCC: 349,
                fuelType: .petrol,
                currentOdometer: 15234.5,
                purchaseDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
                color: "Stealth Black",
                chassisNumber: "ME3U3S5C1NT123456",
                engineNumber: "U3S5C1NT12345",
                insuranceExpiry: Date().addingTimeInterval(180 * 24 * 60 * 60),
                pucExpiry: Date().addingTimeInterval(90 * 24 * 60 * 60),
                baselineKmpl: 35.0
            ),
            Vehicle(
                id: "vehicle_2",
                make: "KTM",
                model: "Duke 390",
                year: 2023,
                registrationNumber: "MH 02 CD 5678",
                engineCC: 373,
                fuelType: .petrol,
                currentOdometer: 8456.2,
                purchaseDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                color: "Orange",
                chassisNumber: "MD2A36FY5PCF12345",
                engineNumber: "36FY5PCF1234",
                insuranceExpiry: Date().addingTimeInterval(270 * 24 * 60 * 60),
                pucExpiry: Date().addingTimeInterval(150 * 24 * 60 * 60),
                baselineKmpl: 30.0
            ),
            Vehicle(
                id: "vehicle_3",
                make: "Honda",
                model: "Activa 6G",
                year: 2021,
                registrationNumber: "KA 03 EF 9012",
                engineCC: 109,
                fuelType: .petrol,
                currentOdometer: 22567.8,
                purchaseDate: Date().addingTimeInterval(-730 * 24 * 60 * 60),
                color: "Pearl Precious White",
                chassisNumber: "ME4KC15E1M8123456",
                engineNumber: "KC15E1M812345",
                insuranceExpiry: Date().addingTimeInterval(60 * 24 * 60 * 60),
                pucExpiry: Date().addingTimeInterval(30 * 24 * 60 * 60),
                baselineKmpl: 50.0
            )
        ]
    }
    
    // MARK: - Rides
    
    static func generateRides() -> [Ride] {
        let rides = [
            // Daily commute
            generateDailyCommute(),
            // Weekend trip
            generateWeekendTrip(),
            // Long tour
            generateLongTour()
        ].flatMap { $0 }
        
        return rides
    }
    
    private static func generateDailyCommute() -> [Ride] {
        var rides: [Ride] = []
        
        for i in 0..<5 {
            let startDate = Date().addingTimeInterval(Double(-i) * 24 * 60 * 60)
            
            // Morning ride
            var morningRide = Ride(
                id: "ride_commute_\(i)_morning",
                vehicleId: "vehicle_3",
                userId: "user_1",
                startTime: Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: startDate)!,
                startOdometer: 22500 + Double(i * 50),
                recordingMode: .auto
            )
            morningRide.endTime = morningRide.startTime.addingTimeInterval(35 * 60)
            morningRide.endOdometer = morningRide.startOdometer + 12.5
            morningRide.gpsDistance = 12.3
            morningRide.averageSpeed = 25.5
            morningRide.maxSpeed = 45.0
            morningRide.movingTime = 30 * 60
            morningRide.title = "Office Commute"
            morningRide.tags = ["daily", "office", "morning"]
            morningRide.routePoints = generateRoutePoints(
                start: CLLocationCoordinate2D(latitude: 28.5355, longitude: 77.3910),
                end: CLLocationCoordinate2D(latitude: 28.5706, longitude: 77.3249),
                duration: 35 * 60
            )
            rides.append(morningRide)
            
            // Evening ride
            var eveningRide = Ride(
                id: "ride_commute_\(i)_evening",
                vehicleId: "vehicle_3",
                userId: "user_1",
                startTime: Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: startDate)!,
                startOdometer: morningRide.endOdometer! + 0.5,
                recordingMode: .auto
            )
            eveningRide.endTime = eveningRide.startTime.addingTimeInterval(40 * 60)
            eveningRide.endOdometer = eveningRide.startOdometer + 13.0
            eveningRide.gpsDistance = 12.8
            eveningRide.averageSpeed = 22.0
            eveningRide.maxSpeed = 42.0
            eveningRide.movingTime = 35 * 60
            eveningRide.title = "Home Commute"
            eveningRide.tags = ["daily", "home", "evening", "traffic"]
            eveningRide.routePoints = generateRoutePoints(
                start: CLLocationCoordinate2D(latitude: 28.5706, longitude: 77.3249),
                end: CLLocationCoordinate2D(latitude: 28.5355, longitude: 77.3910),
                duration: 40 * 60
            )
            rides.append(eveningRide)
        }
        
        return rides
    }
    
    private static func generateWeekendTrip() -> [Ride] {
        var ride = Ride(
            id: "ride_weekend_1",
            vehicleId: "vehicle_1",
            userId: "user_1",
            startTime: Date().addingTimeInterval(-2 * 24 * 60 * 60),
            startOdometer: 15000,
            recordingMode: .manual
        )
        
        ride.endTime = ride.startTime.addingTimeInterval(6 * 60 * 60)
        ride.endOdometer = 15280
        ride.gpsDistance = 278.5
        ride.averageSpeed = 55.0
        ride.maxSpeed = 95.0
        ride.movingTime = 5 * 60 * 60
        ride.title = "Weekend Ride to Agra"
        ride.notes = "Beautiful weather, smooth highways. Stopped at Mathura for breakfast."
        ride.tags = ["weekend", "highway", "agra", "touring"]
        ride.weather = Weather(condition: .clear, temperature: 28, humidity: 45)
        ride.fuelLevel = .threeQuarter
        
        // Generate route Delhi to Agra
        ride.routePoints = generateHighwayRoute()
        
        // Add waypoints
        ride.waypoints = [
            Waypoint(
                id: "waypoint_1",
                timestamp: ride.startTime.addingTimeInterval(90 * 60),
                coordinate: Coordinate(latitude: 28.4089, longitude: 77.3178),
                type: .stop,
                title: "Mathura",
                notes: "Breakfast stop"
            ),
            Waypoint(
                id: "waypoint_2",
                timestamp: ride.startTime.addingTimeInterval(4 * 60 * 60),
                coordinate: Coordinate(latitude: 27.1767, longitude: 78.0081),
                type: .photo,
                title: "Taj Mahal",
                notes: "Tourist spot"
            )
        ]
        
        return [ride]
    }
    
    private static func generateLongTour() -> [Ride] {
        var rides: [Ride] = []
        let tourStartDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        // Day 1: Delhi to Jaipur
        var day1 = Ride(
            id: "ride_tour_day1",
            vehicleId: "vehicle_2",
            userId: "user_1",
            startTime: Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: tourStartDate)!,
            startOdometer: 8000,
            recordingMode: .manual
        )
        day1.endTime = day1.startTime.addingTimeInterval(7 * 60 * 60)
        day1.endOdometer = 8280
        day1.gpsDistance = 278.0
        day1.averageSpeed = 60.0
        day1.maxSpeed = 110.0
        day1.movingTime = 5.5 * 60 * 60
        day1.title = "Ladakh Tour - Day 1: Delhi to Jaipur"
        day1.roomId = "room_ladakh_tour"
        rides.append(day1)
        
        // Day 2: Jaipur to Bikaner
        var day2 = Ride(
            id: "ride_tour_day2",
            vehicleId: "vehicle_2",
            userId: "user_1",
            startTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, 
                                            of: tourStartDate.addingTimeInterval(24 * 60 * 60))!,
            startOdometer: 8280,
            recordingMode: .manual
        )
        day2.endTime = day2.startTime.addingTimeInterval(8 * 60 * 60)
        day2.endOdometer = 8610
        day2.gpsDistance = 328.0
        day2.averageSpeed = 55.0
        day2.maxSpeed = 100.0
        day2.movingTime = 6.5 * 60 * 60
        day2.title = "Ladakh Tour - Day 2: Jaipur to Bikaner"
        day2.roomId = "room_ladakh_tour"
        rides.append(day2)
        
        return rides
    }
    
    // MARK: - Expenses
    
    static func generateExpenses() -> [Expense] {
        var expenses: [Expense] = []
        
        // Fuel expenses
        expenses.append(contentsOf: [
            Expense(
                id: "expense_fuel_1",
                rideId: "ride_weekend_1",
                category: .fuel,
                amount: 500.0,
                description: "Full tank at IOCL",
                paidBy: "user_1"
            ),
            Expense(
                id: "expense_fuel_2",
                rideId: "ride_tour_day1",
                roomId: "room_ladakh_tour",
                category: .fuel,
                amount: 850.0,
                description: "Refuel at HPCL Jaipur",
                paidBy: "user_1"
            ),
            Expense(
                id: "expense_fuel_3",
                rideId: "ride_tour_day2",
                roomId: "room_ladakh_tour",
                category: .fuel,
                amount: 920.0,
                description: "Refuel at BPCL Bikaner",
                paidBy: "user_2"
            )
        ])
        
        // Food expenses
        expenses.append(contentsOf: [
            Expense(
                id: "expense_food_1",
                rideId: "ride_weekend_1",
                category: .food,
                amount: 350.0,
                description: "Breakfast at Mathura",
                paidBy: "user_1"
            ),
            Expense(
                id: "expense_food_2",
                roomId: "room_ladakh_tour",
                category: .food,
                amount: 1200.0,
                description: "Dinner at Jaipur",
                paidBy: "user_1"
            ),
            Expense(
                id: "expense_food_3",
                roomId: "room_ladakh_tour",
                category: .food,
                amount: 800.0,
                description: "Lunch at highway dhaba",
                paidBy: "user_3"
            )
        ])
        
        // Hotel expenses
        expenses.append(
            Expense(
                id: "expense_hotel_1",
                roomId: "room_ladakh_tour",
                category: .hotel,
                amount: 3500.0,
                description: "Hotel stay in Jaipur",
                paidBy: "user_2"
            )
        )
        
        // Toll expenses
        expenses.append(contentsOf: [
            Expense(
                id: "expense_toll_1",
                rideId: "ride_weekend_1",
                category: .toll,
                amount: 165.0,
                description: "Delhi-Agra toll",
                paidBy: "user_1"
            ),
            Expense(
                id: "expense_toll_2",
                rideId: "ride_tour_day1",
                roomId: "room_ladakh_tour",
                category: .toll,
                amount: 245.0,
                description: "Delhi-Jaipur tolls",
                paidBy: "user_1"
            )
        ])
        
        // Set split types for room expenses
        for i in 0..<expenses.count {
            if expenses[i].roomId != nil {
                expenses[i].splitType = .equal
                expenses[i].participants = ["user_1", "user_2", "user_3"]
                expenses[i].calculateSplits()
            }
        }
        
        return expenses
    }
    
    // MARK: - Ride Rooms
    
    static func generateRideRooms() -> [RideRoom] {
        var room = RideRoom(
            id: "room_ladakh_tour",
            name: "Ladakh Tour 2024",
            description: "Epic bike tour to Ladakh with friends",
            createdBy: "user_1"
        )
        
        room.memberIds = ["user_1", "user_2", "user_3"]
        room.adminIds = ["user_1"]
        room.totalDistance = 2500.0
        room.totalExpenses = 15000.0
        room.totalRides = 10
        
        room.itinerary = [
            ItineraryItem(
                title: "Day 1: Delhi to Jaipur",
                description: "Start early, reach by evening",
                scheduledTime: Date().addingTimeInterval(-7 * 24 * 60 * 60)
            ),
            ItineraryItem(
                title: "Day 2: Jaipur to Bikaner",
                description: "Desert route",
                scheduledTime: Date().addingTimeInterval(-6 * 24 * 60 * 60)
            ),
            ItineraryItem(
                title: "Day 3: Bikaner to Jaisalmer",
                description: "Golden city",
                scheduledTime: Date().addingTimeInterval(-5 * 24 * 60 * 60)
            )
        ]
        
        room.pinnedNotes = [
            PinnedNote(
                content: "Carry extra fuel cans for desert stretches",
                createdBy: "user_1"
            ),
            PinnedNote(
                content: "Book hotels in advance for Leh",
                createdBy: "user_2"
            )
        ]
        
        return [room]
    }
    
    // MARK: - Room Members
    
    static func generateRoomMembers() -> [RoomMember] {
        return [
            RoomMember(
                id: "member_1",
                userId: "user_1",
                roomId: "room_ladakh_tour",
                displayName: "Rajesh Kumar",
                phoneNumber: "+91 98765 43210",
                joinedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                role: .owner,
                totalExpenses: 5500.0,
                totalPaid: 6000.0,
                balance: 500.0
            ),
            RoomMember(
                id: "member_2",
                userId: "user_2",
                roomId: "room_ladakh_tour",
                displayName: "Amit Singh",
                phoneNumber: "+91 87654 32109",
                joinedAt: Date().addingTimeInterval(-25 * 24 * 60 * 60),
                role: .member,
                totalExpenses: 4500.0,
                totalPaid: 4000.0,
                balance: -500.0
            ),
            RoomMember(
                id: "member_3",
                userId: "user_3",
                roomId: "room_ladakh_tour",
                displayName: "Priya Sharma",
                phoneNumber: "+91 76543 21098",
                joinedAt: Date().addingTimeInterval(-20 * 24 * 60 * 60),
                role: .member,
                totalExpenses: 5000.0,
                totalPaid: 5000.0,
                balance: 0.0
            )
        ]
    }
    
    // MARK: - POIs
    
    static func generatePOIs() -> [POI] {
        return [
            POI(
                id: "poi_1",
                name: "IOCL Petrol Pump - NH44",
                placeId: "ChIJN1t_tDeuEmsRUsoyG83frY4",
                location: Coordinate(latitude: 28.4595, longitude: 77.0266),
                type: .gasStation,
                address: "NH 44, Gurugram, Haryana",
                rating: 4.2,
                distance: 0,
                isOpen: true,
                brand: "IOCL"
            ),
            POI(
                id: "poi_2",
                name: "Highway King Dhaba",
                placeId: "ChIJN1t_tDeuEmsRUsoyG83frY5",
                location: Coordinate(latitude: 28.3670, longitude: 77.1200),
                type: .restaurant,
                address: "NH 48, Manesar, Haryana",
                rating: 4.5,
                distance: 0,
                isOpen: true,
                brand: nil
            ),
            POI(
                id: "poi_3",
                name: "Hotel Rajputana",
                placeId: "ChIJN1t_tDeuEmsRUsoyG83frY6",
                location: Coordinate(latitude: 26.9124, longitude: 75.7873),
                type: .lodging,
                address: "MI Road, Jaipur, Rajasthan",
                rating: 4.0,
                distance: 0,
                isOpen: true,
                brand: nil
            ),
            POI(
                id: "poi_4",
                name: "Bullet Mechanic - Royal Motors",
                placeId: "ChIJN1t_tDeuEmsRUsoyG83frY7",
                location: Coordinate(latitude: 28.6139, longitude: 77.2090),
                type: .mechanic,
                address: "Karol Bagh, New Delhi",
                rating: 4.8,
                distance: 0,
                isOpen: true,
                brand: nil
            )
        ]
    }
    
    // MARK: - Service Reminders
    
    static func generateServiceReminders() -> [ServiceReminder] {
        return [
            ServiceReminder(
                id: "service_1",
                vehicleId: "vehicle_1",
                type: "engine_oil",
                name: "Engine Oil Change",
                intervalKm: 5000,
                intervalDays: 180,
                lastServiceKm: 13000,
                lastServiceDate: Date().addingTimeInterval(-60 * 24 * 60 * 60),
                nextDueKm: 18000,
                nextDueDate: Date().addingTimeInterval(120 * 24 * 60 * 60)
            ),
            ServiceReminder(
                id: "service_2",
                vehicleId: "vehicle_1",
                type: "chain_clean",
                name: "Chain Cleaning & Lubrication",
                intervalKm: 1000,
                intervalDays: 30,
                lastServiceKm: 15000,
                lastServiceDate: Date().addingTimeInterval(-10 * 24 * 60 * 60),
                nextDueKm: 16000,
                nextDueDate: Date().addingTimeInterval(20 * 24 * 60 * 60)
            ),
            ServiceReminder(
                id: "service_3",
                vehicleId: "vehicle_2",
                type: "air_filter",
                name: "Air Filter Replacement",
                intervalKm: 10000,
                intervalDays: 365,
                lastServiceKm: 5000,
                lastServiceDate: Date().addingTimeInterval(-90 * 24 * 60 * 60),
                nextDueKm: 15000,
                nextDueDate: Date().addingTimeInterval(275 * 24 * 60 * 60)
            )
        ]
    }
    
    // MARK: - Helper Methods
    
    private static func generateRoutePoints(start: CLLocationCoordinate2D,
                                           end: CLLocationCoordinate2D,
                                           duration: TimeInterval) -> [RidePoint] {
        var points: [RidePoint] = []
        let pointCount = Int(duration / 30) // One point every 30 seconds
        
        for i in 0..<pointCount {
            let progress = Double(i) / Double(pointCount - 1)
            let lat = start.latitude + (end.latitude - start.latitude) * progress
            let lon = start.longitude + (end.longitude - start.longitude) * progress
            
            // Add some randomness for realistic path
            let latOffset = Double.random(in: -0.001...0.001)
            let lonOffset = Double.random(in: -0.001...0.001)
            
            let location = CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: lat + latOffset,
                    longitude: lon + lonOffset
                ),
                altitude: 200 + Double.random(in: -10...10),
                horizontalAccuracy: 5,
                verticalAccuracy: 10,
                course: calculateBearing(from: start, to: end),
                speed: Double.random(in: 10...30), // m/s
                timestamp: Date().addingTimeInterval(-duration + Double(i) * 30)
            )
            
            points.append(RidePoint(from: location))
        }
        
        return points
    }
    
    private static func generateHighwayRoute() -> [RidePoint] {
        // Simplified Delhi to Agra route
        let waypoints = [
            CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090), // Delhi
            CLLocationCoordinate2D(latitude: 28.5355, longitude: 77.3910), // Noida
            CLLocationCoordinate2D(latitude: 28.4089, longitude: 77.3178), // Faridabad
            CLLocationCoordinate2D(latitude: 28.0229, longitude: 77.4971), // Palwal
            CLLocationCoordinate2D(latitude: 27.4924, longitude: 77.6737), // Mathura
            CLLocationCoordinate2D(latitude: 27.1767, longitude: 78.0081)  // Agra
        ]
        
        var points: [RidePoint] = []
        
        for i in 0..<waypoints.count - 1 {
            let segmentPoints = generateRoutePoints(
                start: waypoints[i],
                end: waypoints[i + 1],
                duration: 60 * 60 // 1 hour per segment
            )
            points.append(contentsOf: segmentPoints)
        }
        
        return points
    }
    
    private static func calculateBearing(from start: CLLocationCoordinate2D,
                                        to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(x, y)
        return (bearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
}

// MARK: - Mock Models

struct Vehicle {
    let id: String
    let make: String
    let model: String
    let year: Int
    let registrationNumber: String
    let engineCC: Int
    let fuelType: Constants.Fuel.Type
    var currentOdometer: Double
    let purchaseDate: Date?
    let color: String?
    let chassisNumber: String?
    let engineNumber: String?
    let insuranceExpiry: Date?
    let pucExpiry: Date?
    let baselineKmpl: Double
}

struct ServiceReminder {
    let id: String
    let vehicleId: String
    let type: String
    let name: String
    let intervalKm: Int
    let intervalDays: Int
    let lastServiceKm: Double
    let lastServiceDate: Date?
    let nextDueKm: Double
    let nextDueDate: Date?
}