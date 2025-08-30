import UIKit
import PDFKit
import MapKit
import SwiftUI

/// PDF renderer for exporting rides and rooms
class PDFRenderer {
    
    // MARK: - Properties
    private let pageSize = CGSize(width: 595, height: 842) // A4
    private let margin: CGFloat = 50
    private let contentWidth: CGFloat = 495 // pageSize.width - 2*margin
    private let primaryColor = UIColor(DesignSystem.Colors.primary)
    private let secondaryColor = UIColor(DesignSystem.Colors.secondary)
    
    // MARK: - Fonts
    private let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
    private let headingFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
    private let subheadingFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    private let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    private let captionFont = UIFont.systemFont(ofSize: 10, weight: .regular)
    private let monoFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    
    // MARK: - Ride PDF Export
    func exportRidePDF(ride: Ride, expenses: [Expense], vehicle: Vehicle) -> Data? {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: ride.title ?? "Ride Report",
            kCGPDFContextAuthor as String: "MotoMitra",
            kCGPDFContextCreator as String: "MotoMitra iOS App"
        ]
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)
        
        return renderer.pdfData { context in
            // Page 1: Cover & Summary
            context.beginPage()
            var yPosition = margin
            
            // Header
            yPosition = drawHeader(in: context, at: yPosition)
            
            // Title
            yPosition = drawTitle(ride: ride, in: context, at: yPosition)
            
            // Vehicle info
            yPosition = drawVehicleInfo(vehicle: vehicle, in: context, at: yPosition)
            
            // Summary stats
            yPosition = drawRideSummary(ride: ride, in: context, at: yPosition)
            
            // Route map
            if !ride.routePoints.isEmpty {
                yPosition = drawRouteMap(ride: ride, in: context, at: yPosition)
            }
            
            // Page 2: Detailed Metrics
            if yPosition > pageSize.height - 200 {
                context.beginPage()
                yPosition = margin
            }
            
            // Speed & elevation charts
            yPosition = drawCharts(ride: ride, in: context, at: yPosition)
            
            // Page 3: Expenses
            if !expenses.isEmpty {
                context.beginPage()
                yPosition = margin
                yPosition = drawExpenses(expenses: expenses, in: context, at: yPosition)
            }
            
            // Footer on last page
            drawFooter(in: context)
        }
    }
    
    // MARK: - Room PDF Export
    func exportRoomPDF(room: RideRoom, members: [RoomMember], expenses: [Expense], settlements: [Settlement]) -> Data? {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: room.name,
            kCGPDFContextAuthor as String: "MotoMitra",
            kCGPDFContextCreator as String: "MotoMitra iOS App"
        ]
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)
        
        return renderer.pdfData { context in
            // Page 1: Room Summary
            context.beginPage()
            var yPosition = margin
            
            // Header
            yPosition = drawHeader(in: context, at: yPosition)
            
            // Room title
            yPosition = drawRoomTitle(room: room, in: context, at: yPosition)
            
            // Members
            yPosition = drawMembers(members: members, in: context, at: yPosition)
            
            // Summary stats
            yPosition = drawRoomSummary(room: room, expenses: expenses, in: context, at: yPosition)
            
            // Page 2: Expenses
            context.beginPage()
            yPosition = margin
            yPosition = drawSharedExpenses(expenses: expenses, members: members, in: context, at: yPosition)
            
            // Page 3: Settlements
            context.beginPage()
            yPosition = margin
            yPosition = drawSettlements(settlements: settlements, members: members, in: context, at: yPosition)
            
            // Settlement summary
            yPosition = drawSettlementSummary(settlements: settlements, in: context, at: yPosition)
            
            // Signature section
            yPosition = drawSignatureSection(members: members, in: context, at: yPosition)
            
            // Footer
            drawFooter(in: context)
        }
    }
    
    // MARK: - Drawing Methods - Ride
    
    private func drawHeader(in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Logo/App name
        let logoRect = CGRect(x: margin, y: y, width: 150, height: 30)
        let logoAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: primaryColor
        ]
        "MotoMitra".draw(in: logoRect, withAttributes: logoAttributes)
        
        // Date
        let dateRect = CGRect(x: pageSize.width - margin - 150, y: y, width: 150, height: 30)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: UIColor.gray
        ]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.Format.dateTimeFormat
        dateFormatter.draw(in: dateRect, withAttributes: dateAttributes)
        
        y += 40
        
        // Separator line
        context.cgContext.setStrokeColor(UIColor.separator.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.move(to: CGPoint(x: margin, y: y))
        context.cgContext.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
        context.cgContext.strokePath()
        
        return y + 20
    }
    
    private func drawTitle(ride: Ride, in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Title
        let title = ride.title ?? "Ride Report"
        let titleRect = CGRect(x: margin, y: y, width: contentWidth, height: 30)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ]
        title.draw(in: titleRect, withAttributes: titleAttributes)
        y += 35
        
        // Date & Duration
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.Format.dateTimeFormat
        let subtitle = "\(dateFormatter.string(from: ride.startTime)) • \(formatDuration(ride.duration))"
        let subtitleRect = CGRect(x: margin, y: y, width: contentWidth, height: 20)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        
        return y + 30
    }
    
    private func drawVehicleInfo(vehicle: Vehicle, in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Vehicle box
        let boxRect = CGRect(x: margin, y: y, width: contentWidth, height: 60)
        context.cgContext.setFillColor(UIColor.secondarySystemBackground.cgColor)
        context.cgContext.fill(boxRect)
        
        // Vehicle details
        let vehicleText = "\(vehicle.make) \(vehicle.model) (\(vehicle.year))"
        let vehicleRect = CGRect(x: margin + 10, y: y + 10, width: contentWidth - 20, height: 20)
        let vehicleAttributes: [NSAttributedString.Key: Any] = [
            .font: subheadingFont,
            .foregroundColor: UIColor.label
        ]
        vehicleText.draw(in: vehicleRect, withAttributes: vehicleAttributes)
        
        // Registration
        let regText = "Registration: \(vehicle.registrationNumber)"
        let regRect = CGRect(x: margin + 10, y: y + 30, width: contentWidth - 20, height: 20)
        let regAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        regText.draw(in: regRect, withAttributes: regAttributes)
        
        return y + 70
    }
    
    private func drawRideSummary(ride: Ride, in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Section title
        let sectionRect = CGRect(x: margin, y: y, width: contentWidth, height: 25)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: primaryColor
        ]
        "Ride Summary".draw(in: sectionRect, withAttributes: sectionAttributes)
        y += 30
        
        // Stats grid
        let stats = [
            ("Distance (GPS)", String(format: "%.2f km", ride.gpsDistance)),
            ("Distance (Odometer)", String(format: "%.2f km", ride.odometerDistance ?? 0)),
            ("Average Speed", String(format: "%.1f km/h", ride.averageSpeed)),
            ("Max Speed", String(format: "%.1f km/h", ride.maxSpeed)),
            ("Moving Time", formatDuration(ride.movingTime)),
            ("Total Time", formatDuration(ride.duration)),
            ("Start Odometer", String(format: "%.0f km", ride.startOdometer)),
            ("End Odometer", String(format: "%.0f km", ride.endOdometer ?? 0))
        ]
        
        let columnWidth = contentWidth / 2
        for (index, stat) in stats.enumerated() {
            let column = index % 2
            let row = index / 2
            let x = margin + (columnWidth * CGFloat(column))
            let statY = y + (CGFloat(row) * 25)
            
            // Label
            let labelRect = CGRect(x: x, y: statY, width: columnWidth / 2 - 5, height: 20)
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: captionFont,
                .foregroundColor: UIColor.secondaryLabel
            ]
            stat.0.draw(in: labelRect, withAttributes: labelAttributes)
            
            // Value
            let valueRect = CGRect(x: x + columnWidth / 2, y: statY, width: columnWidth / 2 - 5, height: 20)
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: monoFont,
                .foregroundColor: UIColor.label
            ]
            stat.1.draw(in: valueRect, withAttributes: valueAttributes)
        }
        
        return y + (CGFloat((stats.count + 1) / 2) * 25) + 20
    }
    
    private func drawRouteMap(ride: Ride, in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Section title
        let sectionRect = CGRect(x: margin, y: y, width: contentWidth, height: 25)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: primaryColor
        ]
        "Route Map".draw(in: sectionRect, withAttributes: sectionAttributes)
        y += 30
        
        // Map snapshot
        let mapRect = CGRect(x: margin, y: y, width: contentWidth, height: 200)
        
        // Create map snapshot
        if let mapImage = createMapSnapshot(for: ride) {
            mapImage.draw(in: mapRect)
        } else {
            // Placeholder
            context.cgContext.setFillColor(UIColor.tertiarySystemFill.cgColor)
            context.cgContext.fill(mapRect)
            
            let placeholderAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.tertiaryLabel
            ]
            "Map not available".draw(
                in: CGRect(x: mapRect.midX - 50, y: mapRect.midY - 10, width: 100, height: 20),
                withAttributes: placeholderAttributes
            )
        }
        
        return y + 210
    }
    
    private func drawCharts(ride: Ride, in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Speed chart
        y = drawSpeedChart(ride: ride, in: context, at: y)
        
        // Elevation chart
        if ride.routePoints.contains(where: { $0.altitude != nil }) {
            y = drawElevationChart(ride: ride, in: context, at: y)
        }
        
        return y
    }
    
    private func drawExpenses(expenses: [Expense], in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Section title
        let sectionRect = CGRect(x: margin, y: y, width: contentWidth, height: 25)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: primaryColor
        ]
        "Expenses".draw(in: sectionRect, withAttributes: sectionAttributes)
        y += 30
        
        // Table header
        let headers = ["Date/Time", "Category", "Description", "Amount"]
        let columnWidths = [120, 80, contentWidth - 280, 80]
        var xPosition = margin
        
        for (index, header) in headers.enumerated() {
            let headerRect = CGRect(x: xPosition, y: y, width: columnWidths[index], height: 20)
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: subheadingFont,
                .foregroundColor: UIColor.label
            ]
            header.draw(in: headerRect, withAttributes: headerAttributes)
            xPosition += columnWidths[index]
        }
        y += 25
        
        // Separator
        context.cgContext.setStrokeColor(UIColor.separator.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.move(to: CGPoint(x: margin, y: y))
        context.cgContext.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
        context.cgContext.strokePath()
        y += 5
        
        // Expense rows
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM HH:mm"
        
        for expense in expenses {
            xPosition = margin
            
            // Date
            let dateRect = CGRect(x: xPosition, y: y, width: columnWidths[0], height: 20)
            dateFormatter.string(from: expense.timestamp).draw(in: dateRect, withAttributes: [
                .font: captionFont,
                .foregroundColor: UIColor.label
            ])
            xPosition += columnWidths[0]
            
            // Category
            let categoryRect = CGRect(x: xPosition, y: y, width: columnWidths[1], height: 20)
            expense.category.rawValue.draw(in: categoryRect, withAttributes: [
                .font: captionFont,
                .foregroundColor: getCategoryColor(expense.category)
            ])
            xPosition += columnWidths[1]
            
            // Description
            let descRect = CGRect(x: xPosition, y: y, width: columnWidths[2], height: 20)
            (expense.description ?? "").draw(in: descRect, withAttributes: [
                .font: captionFont,
                .foregroundColor: UIColor.label
            ])
            xPosition += columnWidths[2]
            
            // Amount
            let amountRect = CGRect(x: xPosition, y: y, width: columnWidths[3], height: 20)
            String(format: "₹%.2f", expense.amount).draw(in: amountRect, withAttributes: [
                .font: monoFont,
                .foregroundColor: UIColor.label
            ])
            
            y += 22
        }
        
        // Total
        y += 10
        context.cgContext.setStrokeColor(UIColor.separator.cgColor)
        context.cgContext.move(to: CGPoint(x: pageSize.width - margin - 100, y: y))
        context.cgContext.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
        context.cgContext.strokePath()
        y += 5
        
        let total = expenses.reduce(0) { $0 + $1.amount }
        let totalRect = CGRect(x: pageSize.width - margin - 100, y: y, width: 100, height: 20)
        String(format: "Total: ₹%.2f", total).draw(in: totalRect, withAttributes: [
            .font: subheadingFont,
            .foregroundColor: UIColor.label
        ])
        
        return y + 30
    }
    
    // MARK: - Drawing Methods - Room
    
    private func drawRoomTitle(room: RideRoom, in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Room name
        let titleRect = CGRect(x: margin, y: y, width: contentWidth, height: 30)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ]
        room.name.draw(in: titleRect, withAttributes: titleAttributes)
        y += 35
        
        // Room code
        let codeRect = CGRect(x: margin, y: y, width: contentWidth, height: 20)
        let codeAttributes: [NSAttributedString.Key: Any] = [
            .font: monoFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        "Room Code: \(room.inviteCode)".draw(in: codeRect, withAttributes: codeAttributes)
        
        return y + 30
    }
    
    private func drawMembers(members: [RoomMember], in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Section title
        let sectionRect = CGRect(x: margin, y: y, width: contentWidth, height: 25)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: primaryColor
        ]
        "Members (\(members.count))".draw(in: sectionRect, withAttributes: sectionAttributes)
        y += 30
        
        // Member list
        for member in members {
            let memberRect = CGRect(x: margin + 20, y: y, width: contentWidth - 20, height: 20)
            let memberText = "• \(member.displayName) (\(member.role.rawValue))"
            let memberAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.label
            ]
            memberText.draw(in: memberRect, withAttributes: memberAttributes)
            y += 22
        }
        
        return y + 10
    }
    
    private func drawSharedExpenses(expenses: [Expense], members: [RoomMember], in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Section title
        let sectionRect = CGRect(x: margin, y: y, width: contentWidth, height: 25)
        "Shared Expenses".draw(in: sectionRect, withAttributes: [
            .font: headingFont,
            .foregroundColor: primaryColor
        ])
        y += 30
        
        // Group expenses by payer
        let groupedExpenses = Dictionary(grouping: expenses) { $0.paidBy }
        
        for (payerId, payerExpenses) in groupedExpenses {
            // Payer name
            let payerName = members.first { $0.id == payerId }?.displayName ?? "Unknown"
            let payerRect = CGRect(x: margin, y: y, width: contentWidth, height: 20)
            "Paid by \(payerName):".draw(in: payerRect, withAttributes: [
                .font: subheadingFont,
                .foregroundColor: UIColor.label
            ])
            y += 25
            
            // Expenses
            for expense in payerExpenses {
                let expenseText = "  • \(expense.description ?? "Expense") - ₹\(String(format: "%.2f", expense.amount))"
                let expenseRect = CGRect(x: margin + 20, y: y, width: contentWidth - 40, height: 20)
                expenseText.draw(in: expenseRect, withAttributes: [
                    .font: captionFont,
                    .foregroundColor: UIColor.secondaryLabel
                ])
                y += 20
            }
            y += 10
        }
        
        return y
    }
    
    private func drawSettlements(settlements: [Settlement], members: [RoomMember], in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Section title
        let sectionRect = CGRect(x: margin, y: y, width: contentWidth, height: 25)
        "Settlement Plan".draw(in: sectionRect, withAttributes: [
            .font: headingFont,
            .foregroundColor: primaryColor
        ])
        y += 30
        
        // Settlement list
        for settlement in settlements {
            let fromName = members.first { $0.id == settlement.fromMemberId }?.displayName ?? "Unknown"
            let toName = members.first { $0.id == settlement.toMemberId }?.displayName ?? "Unknown"
            
            let settlementText = "\(fromName) → \(toName): ₹\(String(format: "%.2f", settlement.amount))"
            let settlementRect = CGRect(x: margin + 20, y: y, width: contentWidth - 40, height: 25)
            
            // Draw arrow and amount
            let arrowAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.label
            ]
            settlementText.draw(in: settlementRect, withAttributes: arrowAttributes)
            
            y += 30
        }
        
        return y + 10
    }
    
    private func drawSettlementSummary(settlements: [Settlement], in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Total settlement amount
        let totalAmount = settlements.reduce(0) { $0 + $1.amount }
        let summaryRect = CGRect(x: margin, y: y, width: contentWidth, height: 30)
        let summaryText = "Total Settlements: ₹\(String(format: "%.2f", totalAmount))"
        summaryText.draw(in: summaryRect, withAttributes: [
            .font: subheadingFont,
            .foregroundColor: primaryColor
        ])
        
        return y + 40
    }
    
    private func drawSignatureSection(members: [RoomMember], in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Check if we need a new page
        if y > pageSize.height - 200 {
            context.beginPage()
            y = margin
        }
        
        // Section title
        let sectionRect = CGRect(x: margin, y: y, width: contentWidth, height: 25)
        "Signatures".draw(in: sectionRect, withAttributes: [
            .font: headingFont,
            .foregroundColor: primaryColor
        ])
        y += 40
        
        // Signature lines
        let signatureWidth = (contentWidth - 20) / 2
        for (index, member) in members.enumerated() {
            let column = index % 2
            let row = index / 2
            let x = margin + (signatureWidth + 20) * CGFloat(column)
            let signatureY = y + (CGFloat(row) * 80)
            
            // Line
            context.cgContext.setStrokeColor(UIColor.separator.cgColor)
            context.cgContext.setLineWidth(0.5)
            context.cgContext.move(to: CGPoint(x: x, y: signatureY + 40))
            context.cgContext.addLine(to: CGPoint(x: x + signatureWidth, y: signatureY + 40))
            context.cgContext.strokePath()
            
            // Name
            let nameRect = CGRect(x: x, y: signatureY + 45, width: signatureWidth, height: 20)
            member.displayName.draw(in: nameRect, withAttributes: [
                .font: captionFont,
                .foregroundColor: UIColor.secondaryLabel
            ])
        }
        
        return y + CGFloat((members.count + 1) / 2) * 80 + 20
    }
    
    // MARK: - Common Drawing Methods
    
    private func drawFooter(in context: UIGraphicsPDFRendererContext) {
        let footerY = pageSize.height - 30
        
        // Separator
        context.cgContext.setStrokeColor(UIColor.separator.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.move(to: CGPoint(x: margin, y: footerY - 10))
        context.cgContext.addLine(to: CGPoint(x: pageSize.width - margin, y: footerY - 10))
        context.cgContext.strokePath()
        
        // Footer text
        let footerRect = CGRect(x: margin, y: footerY - 5, width: contentWidth, height: 20)
        let footerText = "Generated by MotoMitra • \(Date().formatted())"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: UIColor.tertiaryLabel
        ]
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        var attributes = footerAttributes
        attributes[.paragraphStyle] = paragraphStyle
        
        footerText.draw(in: footerRect, withAttributes: attributes)
    }
    
    private func drawSpeedChart(ride: Ride, in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Title
        "Speed Profile".draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 20), withAttributes: [
            .font: subheadingFont,
            .foregroundColor: UIColor.label
        ])
        y += 25
        
        // Chart area
        let chartRect = CGRect(x: margin, y: y, width: contentWidth, height: 100)
        context.cgContext.setFillColor(UIColor.tertiarySystemFill.cgColor)
        context.cgContext.fill(chartRect)
        
        // Draw speed line chart
        if !ride.routePoints.isEmpty {
            let speeds = ride.routePoints.compactMap { $0.speedKmh }
            if !speeds.isEmpty {
                drawLineChart(values: speeds, in: chartRect, context: context, color: primaryColor)
            }
        }
        
        return y + 110
    }
    
    private func drawElevationChart(ride: Ride, in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        
        // Title
        "Elevation Profile".draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 20), withAttributes: [
            .font: subheadingFont,
            .foregroundColor: UIColor.label
        ])
        y += 25
        
        // Chart area
        let chartRect = CGRect(x: margin, y: y, width: contentWidth, height: 100)
        context.cgContext.setFillColor(UIColor.tertiarySystemFill.cgColor)
        context.cgContext.fill(chartRect)
        
        // Draw elevation chart
        let elevations = ride.routePoints.compactMap { $0.altitude }
        if !elevations.isEmpty {
            drawLineChart(values: elevations, in: chartRect, context: context, color: secondaryColor)
        }
        
        return y + 110
    }
    
    private func drawLineChart(values: [Double], in rect: CGRect, context: UIGraphicsPDFRendererContext, color: UIColor) {
        guard !values.isEmpty else { return }
        
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let range = maxValue - minValue
        
        guard range > 0 else { return }
        
        let points = values.enumerated().map { index, value in
            let x = rect.minX + (rect.width * CGFloat(index) / CGFloat(values.count - 1))
            let y = rect.maxY - ((CGFloat(value - minValue) / CGFloat(range)) * rect.height)
            return CGPoint(x: x, y: y)
        }
        
        // Draw line
        context.cgContext.setStrokeColor(color.cgColor)
        context.cgContext.setLineWidth(2)
        context.cgContext.move(to: points[0])
        for point in points.dropFirst() {
            context.cgContext.addLine(to: point)
        }
        context.cgContext.strokePath()
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func getCategoryColor(_ category: Constants.ExpenseCategory) -> UIColor {
        switch category {
        case .fuel: return UIColor(DesignSystem.Colors.fuel)
        case .food: return UIColor(DesignSystem.Colors.food)
        case .hotel: return UIColor(DesignSystem.Colors.hotel)
        case .toll: return UIColor(DesignSystem.Colors.toll)
        case .other: return UIColor(DesignSystem.Colors.other)
        }
    }
    
    private func createMapSnapshot(for ride: Ride) -> UIImage? {
        // TODO: Implement map snapshot generation
        // This would use MKMapSnapshotter to create a static map image
        return nil
    }
}