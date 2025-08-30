import Foundation

/// Ride room for group trips
struct RideRoom: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let inviteCode: String
    let createdBy: String
    let createdAt: Date
    var updatedAt: Date
    
    // Members
    var memberIds: [String] = []
    var adminIds: [String] = []
    
    // Associated data
    var rideIds: [String] = []
    var expenseIds: [String] = []
    
    // Room settings
    var isActive: Bool = true
    var allowMemberInvites: Bool = true
    var requireApproval: Bool = false
    
    // Statistics
    var totalDistance: Double = 0
    var totalExpenses: Double = 0
    var totalRides: Int = 0
    
    // Itinerary
    var itinerary: [ItineraryItem] = []
    var pinnedNotes: [PinnedNote] = []
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String? = nil,
         createdBy: String) {
        self.id = id
        self.name = name
        self.description = description
        self.inviteCode = RideRoom.generateInviteCode()
        self.createdBy = createdBy
        self.createdAt = Date()
        self.updatedAt = Date()
        self.adminIds = [createdBy]
        self.memberIds = [createdBy]
    }
    
    static func generateInviteCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}

/// Room member
struct RoomMember: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let roomId: String
    let displayName: String
    let phoneNumber: String?
    let joinedAt: Date
    var role: Role
    var totalExpenses: Double = 0
    var totalPaid: Double = 0
    var balance: Double = 0
    
    enum Role: String, Codable {
        case owner = "owner"
        case admin = "admin"
        case member = "member"
    }
}

/// Expense in a room context
struct Expense: Identifiable, Codable, Equatable {
    let id: String
    let rideId: String?
    let roomId: String?
    let category: Constants.ExpenseCategory
    let amount: Double
    let description: String?
    let timestamp: Date
    let location: Location?
    
    // Payment info
    let paidBy: String // User ID who paid
    var splitType: SplitType = .equal
    var participants: [String] = [] // User IDs involved
    var splits: [String: Double] = [:] // User ID to amount owed
    
    // Receipt/Bill
    var receiptImageUrl: String?
    var ocrExtractedData: OCRData?
    
    // Metadata
    var tags: [String] = []
    var notes: String?
    var isVerified: Bool = false
    
    enum SplitType: String, Codable {
        case equal = "equal"
        case percentage = "percentage"
        case exact = "exact"
        case paidByOne = "paid_by_one"
    }
    
    init(id: String = UUID().uuidString,
         rideId: String? = nil,
         roomId: String? = nil,
         category: Constants.ExpenseCategory,
         amount: Double,
         description: String? = nil,
         paidBy: String) {
        self.id = id
        self.rideId = rideId
        self.roomId = roomId
        self.category = category
        self.amount = amount
        self.description = description
        self.timestamp = Date()
        self.location = nil
        self.paidBy = paidBy
    }
    
    /// Calculate splits based on split type
    mutating func calculateSplits() {
        switch splitType {
        case .equal:
            let perPerson = amount / Double(participants.count)
            splits = Dictionary(uniqueKeysWithValues: participants.map { ($0, perPerson) })
            
        case .percentage:
            // Splits should already be set as percentages
            // Convert to amounts
            var percentageSplits: [String: Double] = [:]
            for (userId, percentage) in splits {
                percentageSplits[userId] = amount * (percentage / 100)
            }
            splits = percentageSplits
            
        case .exact:
            // Splits should already be set as exact amounts
            // Validate they sum to total
            let sum = splits.values.reduce(0, +)
            if abs(sum - amount) > 0.01 {
                // Adjust for rounding
                if let firstKey = splits.keys.first {
                    splits[firstKey]! += (amount - sum)
                }
            }
            
        case .paidByOne:
            // Only the payer is responsible
            splits = [paidBy: amount]
        }
        
        // Remove payer's share if they're a participant
        if participants.contains(paidBy), splitType != .paidByOne {
            splits[paidBy] = 0
        }
    }
}

/// Settlement between members
struct Settlement: Identifiable, Codable, Equatable {
    let id: String
    let roomId: String
    let fromMemberId: String
    let toMemberId: String
    let amount: Double
    let createdAt: Date
    var settledAt: Date?
    var isSettled: Bool = false
    var settlementMethod: SettlementMethod?
    var transactionId: String?
    var notes: String?
    
    enum SettlementMethod: String, Codable {
        case cash = "cash"
        case upi = "upi"
        case bankTransfer = "bank_transfer"
        case other = "other"
    }
    
    init(roomId: String,
         fromMemberId: String,
         toMemberId: String,
         amount: Double) {
        self.id = UUID().uuidString
        self.roomId = roomId
        self.fromMemberId = fromMemberId
        self.toMemberId = toMemberId
        self.amount = amount
        self.createdAt = Date()
    }
}

/// OCR extracted data
struct OCRData: Codable, Equatable {
    var extractedText: String?
    var amount: Double?
    var vendor: String?
    var date: Date?
    var items: [String] = []
    var confidence: Double = 0
    
    // Fuel-specific
    var fuelLitres: Double?
    var pricePerLitre: Double?
    var fuelType: String?
    var stationBrand: String?
}

/// Itinerary item
struct ItineraryItem: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String?
    let scheduledTime: Date?
    let location: Location?
    var isCompleted: Bool = false
    
    init(title: String,
         description: String? = nil,
         scheduledTime: Date? = nil,
         location: Location? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.scheduledTime = scheduledTime
        self.location = location
    }
}

/// Pinned note
struct PinnedNote: Identifiable, Codable, Equatable {
    let id: String
    let content: String
    let createdBy: String
    let createdAt: Date
    var isPinned: Bool = true
    
    init(content: String, createdBy: String) {
        self.id = UUID().uuidString
        self.content = content
        self.createdBy = createdBy
        self.createdAt = Date()
    }
}

/// Balance calculation result
struct BalanceCalculation {
    let memberId: String
    let totalPaid: Double
    let totalOwed: Double
    let balance: Double // positive = owed to them, negative = they owe
    let settlements: [Settlement]
}

/// Settlement optimizer
class SettlementOptimizer {
    
    /// Calculate minimal settlements for a group
    static func calculateSettlements(for expenses: [Expense], members: [RoomMember]) -> [Settlement] {
        // Calculate net balance for each member
        var balances: [String: Double] = [:]
        
        for member in members {
            balances[member.id] = 0
        }
        
        // Process each expense
        for expense in expenses {
            // Add amount paid by payer
            balances[expense.paidBy, default: 0] += expense.amount
            
            // Subtract amounts owed by participants
            for (userId, amountOwed) in expense.splits {
                balances[userId, default: 0] -= amountOwed
            }
        }
        
        // Separate creditors and debtors
        var creditors: [(String, Double)] = []
        var debtors: [(String, Double)] = []
        
        for (memberId, balance) in balances {
            if balance > 0.01 { // Creditor (owed money)
                creditors.append((memberId, balance))
            } else if balance < -0.01 { // Debtor (owes money)
                debtors.append((memberId, -balance))
            }
        }
        
        // Sort for optimal matching
        creditors.sort { $0.1 > $1.1 }
        debtors.sort { $0.1 > $1.1 }
        
        // Generate minimal settlements
        var settlements: [Settlement] = []
        var creditorIndex = 0
        var debtorIndex = 0
        
        while creditorIndex < creditors.count && debtorIndex < debtors.count {
            let creditor = creditors[creditorIndex]
            let debtor = debtors[debtorIndex]
            
            let settlementAmount = min(creditor.1, debtor.1)
            
            if settlementAmount > 0.01 { // Ignore tiny amounts
                let settlement = Settlement(
                    roomId: "", // Will be set by caller
                    fromMemberId: debtor.0,
                    toMemberId: creditor.0,
                    amount: settlementAmount
                )
                settlements.append(settlement)
            }
            
            // Update remaining amounts
            creditors[creditorIndex].1 -= settlementAmount
            debtors[debtorIndex].1 -= settlementAmount
            
            // Move to next if current is settled
            if creditors[creditorIndex].1 < 0.01 {
                creditorIndex += 1
            }
            if debtors[debtorIndex].1 < 0.01 {
                debtorIndex += 1
            }
        }
        
        return settlements
    }
    
    /// Calculate individual balances
    static func calculateBalances(for expenses: [Expense], members: [RoomMember]) -> [BalanceCalculation] {
        var calculations: [BalanceCalculation] = []
        
        for member in members {
            var totalPaid: Double = 0
            var totalOwed: Double = 0
            
            for expense in expenses {
                if expense.paidBy == member.id {
                    totalPaid += expense.amount
                }
                
                if let amountOwed = expense.splits[member.id] {
                    totalOwed += amountOwed
                }
            }
            
            let balance = totalPaid - totalOwed
            
            let calculation = BalanceCalculation(
                memberId: member.id,
                totalPaid: totalPaid,
                totalOwed: totalOwed,
                balance: balance,
                settlements: []
            )
            
            calculations.append(calculation)
        }
        
        return calculations
    }
}