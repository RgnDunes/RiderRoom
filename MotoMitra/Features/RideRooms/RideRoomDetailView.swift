import SwiftUI

/// Ride room detail view
struct RideRoomDetailView: View {
    let roomId: String
    @StateObject private var viewModel = Container.shared.resolve(RideRoomViewModel.self)
    @EnvironmentObject var router: NavigationRouter
    @State private var selectedTab = 0
    @State private var showingAddExpense = false
    @State private var showingExportOptions = false
    @State private var showingMemberOptions = false
    @State private var selectedMember: RoomMember?
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(0)
                    
                    expensesTab
                        .tag(1)
                    
                    settlementsTab
                        .tag(2)
                    
                    membersTab
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
            // Floating action button
            if selectedTab == 1 { // Expenses tab
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Button(action: { showingAddExpense = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(DesignSystem.Colors.primary)
                                .clipShape(Circle())
                                .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(viewModel: viewModel)
        }
        .confirmationDialog("Export Options", isPresented: $showingExportOptions) {
            Button("Export PDF") {
                exportPDF()
            }
            Button("Share Room Code") {
                shareRoomCode()
            }
        }
        .task {
            await viewModel.loadRoomData(roomId: roomId)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { router.navigateBack() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack {
                    Text(viewModel.currentRoom?.name ?? "Loading...")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if let code = viewModel.currentRoom?.inviteCode {
                        Text("Code: \(code)")
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: { showingExportOptions = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            .padding(.bottom, 10)
        }
        .background(DesignSystem.Colors.surface)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "Overview", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabButton(title: "Expenses", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            TabButton(title: "Settlements", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            TabButton(title: "Members", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
        }
        .background(DesignSystem.Colors.surface)
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary card
                summaryCard
                
                // Balance overview
                balanceOverview
                
                // Quick actions
                quickActions
                
                // Recent activity
                recentActivity
            }
            .padding(20)
        }
    }
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trip Summary")
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack(spacing: 30) {
                SummaryMetric(
                    value: "\(viewModel.members.count)",
                    label: "Members",
                    icon: "person.3.fill"
                )
                
                SummaryMetric(
                    value: String(format: "₹%.0f", viewModel.getTotalExpenses()),
                    label: "Total Spent",
                    icon: "indianrupeesign.circle.fill"
                )
                
                SummaryMetric(
                    value: "\(viewModel.expenses.count)",
                    label: "Expenses",
                    icon: "receipt.fill"
                )
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.surfaceElevated)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    private var balanceOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Balances")
                .font(DesignSystem.Typography.titleMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(viewModel.balances.prefix(3), id: \.memberId) { balance in
                BalanceRow(
                    memberName: viewModel.getMemberName(for: balance.memberId),
                    balance: balance.balance
                )
            }
            
            if viewModel.balances.count > 3 {
                Button("View All") {
                    selectedTab = 2
                }
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.surfaceElevated)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                title: "Add Expense",
                icon: "plus.circle.fill",
                color: DesignSystem.Colors.primary
            ) {
                showingAddExpense = true
            }
            
            QuickActionButton(
                title: "Export PDF",
                icon: "doc.richtext.fill",
                color: DesignSystem.Colors.secondary
            ) {
                exportPDF()
            }
            
            QuickActionButton(
                title: "Share Code",
                icon: "qrcode",
                color: DesignSystem.Colors.success
            ) {
                shareRoomCode()
            }
        }
    }
    
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Expenses")
                .font(DesignSystem.Typography.titleMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if viewModel.expenses.isEmpty {
                Text("No expenses yet")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.expenses.sorted(by: { $0.timestamp > $1.timestamp }).prefix(5)) { expense in
                    ExpenseRow(expense: expense, memberName: viewModel.getMemberName(for: expense.paidBy))
                }
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.surfaceElevated)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    // MARK: - Expenses Tab
    private var expensesTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Category breakdown
                categoryBreakdown
                
                // Expense list
                ForEach(viewModel.expenses.sorted(by: { $0.timestamp > $1.timestamp })) { expense in
                    ExpenseCard(
                        expense: expense,
                        memberName: viewModel.getMemberName(for: expense.paidBy),
                        onDelete: {
                            Task {
                                await viewModel.deleteExpense(expense)
                            }
                        }
                    )
                }
            }
            .padding(20)
            .padding(.bottom, 80) // Space for FAB
        }
    }
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category")
                .font(DesignSystem.Typography.titleMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            let categoryTotals = viewModel.getExpensesByCategory()
            
            ForEach(Array(categoryTotals.keys), id: \.self) { category in
                HStack {
                    Image(systemName: category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(category.color)
                        .frame(width: 24)
                    
                    Text(category.rawValue)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(String(format: "₹%.2f", categoryTotals[category] ?? 0))
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.surfaceElevated)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    // MARK: - Settlements Tab
    private var settlementsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Settlement summary
                settlementSummary
                
                // Pending settlements
                if !viewModel.settlements.filter({ !$0.isSettled }).isEmpty {
                    pendingSettlements
                }
                
                // Settled history
                if !viewModel.settlements.filter({ $0.isSettled }).isEmpty {
                    settledHistory
                }
            }
            .padding(20)
        }
    }
    
    private var settlementSummary: some View {
        VStack(spacing: 16) {
            Text("Settlement Plan")
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Minimal transactions to settle all balances")
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            // Visual representation
            ForEach(viewModel.settlements.filter { !$0.isSettled }) { settlement in
                SettlementCard(
                    settlement: settlement,
                    fromName: viewModel.getMemberName(for: settlement.fromMemberId),
                    toName: viewModel.getMemberName(for: settlement.toMemberId),
                    onMarkPaid: {
                        markSettlementPaid(settlement)
                    }
                )
            }
            
            if viewModel.settlements.filter({ !$0.isSettled }).isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(DesignSystem.Colors.success)
                    
                    Text("All Settled!")
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("No pending settlements")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.vertical, 30)
            }
        }
        .padding(20)
        .background(DesignSystem.Colors.surfaceElevated)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    private var pendingSettlements: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending")
                .font(DesignSystem.Typography.titleMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(viewModel.settlements.filter { !$0.isSettled }) { settlement in
                SettlementRow(
                    settlement: settlement,
                    fromName: viewModel.getMemberName(for: settlement.fromMemberId),
                    toName: viewModel.getMemberName(for: settlement.toMemberId)
                )
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.surfaceElevated)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    private var settledHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settled")
                .font(DesignSystem.Typography.titleMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(viewModel.settlements.filter { $0.isSettled }) { settlement in
                SettlementRow(
                    settlement: settlement,
                    fromName: viewModel.getMemberName(for: settlement.fromMemberId),
                    toName: viewModel.getMemberName(for: settlement.toMemberId),
                    isSettled: true
                )
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.surfaceElevated)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    // MARK: - Members Tab
    private var membersTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.members) { member in
                    MemberCard(
                        member: member,
                        balance: viewModel.getMemberBalance(for: member.id),
                        onTap: {
                            selectedMember = member
                            showingMemberOptions = true
                        }
                    )
                }
            }
            .padding(20)
        }
        .confirmationDialog("Member Options", isPresented: $showingMemberOptions, presenting: selectedMember) { member in
            if member.role != .owner {
                Button("Make Admin") {
                    Task {
                        await viewModel.updateMemberRole(member, to: .admin)
                    }
                }
                
                Button("Remove from Room", role: .destructive) {
                    Task {
                        await viewModel.removeMember(member)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func exportPDF() {
        Task {
            if let pdfData = await viewModel.exportRoomPDF() {
                // Share PDF
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(viewModel.currentRoom?.name ?? "room")_report.pdf")
                
                try? pdfData.write(to: tempURL)
                
                await MainActor.run {
                    let activityVC = UIActivityViewController(
                        activityItems: [tempURL],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityVC, animated: true)
                    }
                }
            }
        }
    }
    
    private func shareRoomCode() {
        guard let code = viewModel.currentRoom?.inviteCode else { return }
        
        let message = "Join my MotoMitra ride room!\n\nRoom: \(viewModel.currentRoom?.name ?? "")\nCode: \(code)\n\nDownload MotoMitra to join: https://motomitra.app/join?code=\(code)"
        
        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func markSettlementPaid(_ settlement: Settlement) {
        // Show payment method options
        // For now, just mark as cash
        Task {
            await viewModel.markSettlementAsPaid(settlement, method: .cash)
        }
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.labelMedium)
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                
                Rectangle()
                    .fill(isSelected ? DesignSystem.Colors.primary : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SummaryMetric: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Text(value)
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(label)
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct BalanceRow: View {
    let memberName: String
    let balance: Double
    
    var body: some View {
        HStack {
            Text(memberName)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Text(String(format: "₹%.2f", abs(balance)))
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(balance > 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
            
            Text(balance > 0 ? "to receive" : "to pay")
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(DesignSystem.Colors.surfaceElevated)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    let memberName: String
    
    var body: some View {
        HStack {
            Image(systemName: expense.category.icon)
                .font(.system(size: 16))
                .foregroundColor(expense.category.color)
                .frame(width: 32, height: 32)
                .background(expense.category.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.description ?? expense.category.rawValue)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("by \(memberName)")
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            
            Spacer()
            
            Text(String(format: "₹%.2f", expense.amount))
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

struct ExpenseCard: View {
    let expense: Expense
    let memberName: String
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: expense.category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(expense.category.color)
                
                Text(expense.category.rawValue)
                    .font(DesignSystem.Typography.labelMedium)
                    .foregroundColor(expense.category.color)
                
                Spacer()
                
                Text(String(format: "₹%.2f", expense.amount))
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            if let description = expense.description {
                Text(description)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            HStack {
                Text("Paid by \(memberName)")
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                
                Spacer()
                
                Text(expense.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            
            // Split info
            if expense.splitType != .paidByOne {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Text("Split \(expense.splitType.rawValue) among \(expense.participants.count)")
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.surfaceElevated)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct SettlementCard: View {
    let settlement: Settlement
    let fromName: String
    let toName: String
    let onMarkPaid: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.error)
                    
                    Text(fromName)
                        .font(DesignSystem.Typography.labelMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                VStack {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(String(format: "₹%.2f", settlement.amount))
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.success)
                    
                    Text(toName)
                        .font(DesignSystem.Typography.labelMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
            
            Button(action: onMarkPaid) {
                Text("Mark as Paid")
                    .font(DesignSystem.Typography.labelMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
}

struct SettlementRow: View {
    let settlement: Settlement
    let fromName: String
    let toName: String
    var isSettled: Bool = false
    
    var body: some View {
        HStack {
            Text("\(fromName) → \(toName)")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .strikethrough(isSettled)
            
            Spacer()
            
            Text(String(format: "₹%.2f", settlement.amount))
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(isSettled ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.primary)
            
            if isSettled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.Colors.success)
            }
        }
    }
}

struct MemberCard: View {
    let member: RoomMember
    let balance: Double
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(member.displayName)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if member.role != .member {
                            Text(member.role.rawValue.capitalized)
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignSystem.Colors.primary.opacity(0.1))
                                .cornerRadius(DesignSystem.CornerRadius.xs)
                        }
                    }
                    
                    Text(balance > 0 ? "To receive" : balance < 0 ? "To pay" : "Settled")
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if balance != 0 {
                    Text(String(format: "₹%.2f", abs(balance)))
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(balance > 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                }
            }
            .padding(16)
            .background(DesignSystem.Colors.surfaceElevated)
            .cornerRadius(DesignSystem.CornerRadius.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }
}