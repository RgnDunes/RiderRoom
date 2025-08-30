import SwiftUI
import Combine

/// View model for ride room management
@MainActor
class RideRoomViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentRoom: RideRoom?
    @Published var members: [RoomMember] = []
    @Published var expenses: [Expense] = []
    @Published var settlements: [Settlement] = []
    @Published var balances: [BalanceCalculation] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Dependencies
    private let createRoomUseCase: CreateRideRoomUseCase
    private let calculateSettlementsUseCase: CalculateSettlementsUseCase
    private let roomRepository: RideRoomRepository
    private let expenseRepository: ExpenseRepository
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(createRoomUseCase: CreateRideRoomUseCase,
         calculateSettlementsUseCase: CalculateSettlementsUseCase,
         roomRepository: RideRoomRepository,
         expenseRepository: ExpenseRepository) {
        self.createRoomUseCase = createRoomUseCase
        self.calculateSettlementsUseCase = calculateSettlementsUseCase
        self.roomRepository = roomRepository
        self.expenseRepository = expenseRepository
    }
    
    // MARK: - Room Management
    
    func createRoom(name: String, description: String?) async {
        isLoading = true
        error = nil
        
        do {
            let room = try await createRoomUseCase.execute(name: name, description: description)
            currentRoom = room
            
            // Create initial member entry for creator
            let creator = RoomMember(
                id: getCurrentUserId(),
                userId: getCurrentUserId(),
                roomId: room.id,
                displayName: getCurrentUserName(),
                phoneNumber: nil,
                joinedAt: Date(),
                role: .owner
            )
            members = [creator]
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func joinRoom(inviteCode: String) async {
        isLoading = true
        error = nil
        
        do {
            let room = try await roomRepository.findRoom(byInviteCode: inviteCode)
            currentRoom = room
            
            // Add current user as member
            let newMember = RoomMember(
                id: getCurrentUserId(),
                userId: getCurrentUserId(),
                roomId: room.id,
                displayName: getCurrentUserName(),
                phoneNumber: nil,
                joinedAt: Date(),
                role: .member
            )
            
            try await roomRepository.addMember(newMember, to: room)
            await loadRoomData(roomId: room.id)
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func loadRoomData(roomId: String) async {
        isLoading = true
        
        do {
            // Load room details
            currentRoom = try await roomRepository.getRoom(id: roomId)
            
            // Load members
            members = try await roomRepository.getMembers(for: roomId)
            
            // Load expenses
            expenses = try await expenseRepository.getExpenses(for: roomId)
            
            // Calculate balances and settlements
            calculateBalances()
            calculateSettlements()
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    // MARK: - Expense Management
    
    func addExpense(_ expense: Expense) async {
        isLoading = true
        
        do {
            var mutableExpense = expense
            mutableExpense.calculateSplits()
            
            try await expenseRepository.saveExpense(mutableExpense)
            expenses.append(mutableExpense)
            
            // Recalculate balances
            calculateBalances()
            calculateSettlements()
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func deleteExpense(_ expense: Expense) async {
        isLoading = true
        
        do {
            try await expenseRepository.deleteExpense(expense)
            expenses.removeAll { $0.id == expense.id }
            
            // Recalculate balances
            calculateBalances()
            calculateSettlements()
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    // MARK: - Settlement Calculation
    
    func calculateBalances() {
        balances = SettlementOptimizer.calculateBalances(for: expenses, members: members)
    }
    
    func calculateSettlements() {
        settlements = SettlementOptimizer.calculateSettlements(for: expenses, members: members)
        
        // Set room ID for settlements
        if let roomId = currentRoom?.id {
            settlements = settlements.map { settlement in
                var mutableSettlement = settlement
                mutableSettlement = Settlement(
                    roomId: roomId,
                    fromMemberId: settlement.fromMemberId,
                    toMemberId: settlement.toMemberId,
                    amount: settlement.amount
                )
                return mutableSettlement
            }
        }
    }
    
    func markSettlementAsPaid(_ settlement: Settlement, method: Settlement.SettlementMethod, transactionId: String? = nil) async {
        isLoading = true
        
        do {
            var mutableSettlement = settlement
            mutableSettlement.isSettled = true
            mutableSettlement.settledAt = Date()
            mutableSettlement.settlementMethod = method
            mutableSettlement.transactionId = transactionId
            
            try await roomRepository.updateSettlement(mutableSettlement)
            
            // Update local settlement
            if let index = settlements.firstIndex(where: { $0.id == settlement.id }) {
                settlements[index] = mutableSettlement
            }
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    // MARK: - Export
    
    func exportRoomPDF() async -> Data? {
        guard let room = currentRoom else { return nil }
        
        let pdfRenderer = PDFRenderer()
        return pdfRenderer.exportRoomPDF(
            room: room,
            members: members,
            expenses: expenses,
            settlements: settlements.filter { !$0.isSettled }
        )
    }
    
    // MARK: - Member Management
    
    func removeMember(_ member: RoomMember) async {
        guard member.role != .owner else { return }
        
        isLoading = true
        
        do {
            try await roomRepository.removeMember(member)
            members.removeAll { $0.id == member.id }
            
            // Recalculate if member had expenses
            if expenses.contains(where: { $0.paidBy == member.id || $0.participants.contains(member.id) }) {
                calculateBalances()
                calculateSettlements()
            }
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func updateMemberRole(_ member: RoomMember, to role: RoomMember.Role) async {
        guard member.role != .owner else { return }
        
        isLoading = true
        
        do {
            var updatedMember = member
            updatedMember.role = role
            
            try await roomRepository.updateMember(updatedMember)
            
            if let index = members.firstIndex(where: { $0.id == member.id }) {
                members[index] = updatedMember
            }
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    // MARK: - Helpers
    
    private func getCurrentUserId() -> String {
        // TODO: Get from auth service
        return "current_user_id"
    }
    
    private func getCurrentUserName() -> String {
        // TODO: Get from auth service
        return "Current User"
    }
    
    func getMemberName(for userId: String) -> String {
        return members.first { $0.userId == userId }?.displayName ?? "Unknown"
    }
    
    func getMemberBalance(for userId: String) -> Double {
        return balances.first { $0.memberId == userId }?.balance ?? 0
    }
    
    func getTotalExpenses() -> Double {
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    func getExpensesByCategory() -> [Constants.ExpenseCategory: Double] {
        var categoryTotals: [Constants.ExpenseCategory: Double] = [:]
        
        for expense in expenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        
        return categoryTotals
    }
}

// MARK: - Mock Use Cases (for compilation)
struct CreateRideRoomUseCase {
    func execute(name: String, description: String?) async throws -> RideRoom {
        return RideRoom(name: name, description: description, createdBy: "current_user_id")
    }
}

struct CalculateSettlementsUseCase {
    func execute(expenses: [Expense], members: [RoomMember]) -> [Settlement] {
        return SettlementOptimizer.calculateSettlements(for: expenses, members: members)
    }
}

// MARK: - Mock Repository Protocols
protocol RideRoomRepository {
    func createRoom(_ room: RideRoom) async throws
    func getRoom(id: String) async throws -> RideRoom
    func findRoom(byInviteCode code: String) async throws -> RideRoom
    func addMember(_ member: RoomMember, to room: RideRoom) async throws
    func removeMember(_ member: RoomMember) async throws
    func updateMember(_ member: RoomMember) async throws
    func getMembers(for roomId: String) async throws -> [RoomMember]
    func updateSettlement(_ settlement: Settlement) async throws
}

protocol ExpenseRepository {
    func saveExpense(_ expense: Expense) async throws
    func getExpenses(for roomId: String) async throws -> [Expense]
    func deleteExpense(_ expense: Expense) async throws
}