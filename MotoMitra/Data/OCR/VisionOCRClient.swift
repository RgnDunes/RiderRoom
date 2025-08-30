import Foundation
import Vision
import UIKit
import VisionKit

/// OCR client using Vision framework for text extraction
class VisionOCRClient: OCRClient {
    
    // MARK: - Properties
    private let textRecognitionQueue = DispatchQueue(label: "com.motomitra.ocr", qos: .userInitiated)
    
    // MARK: - OCR Processing
    
    func extractText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            textRecognitionQueue.async {
                do {
                    let result = try self.performOCR(on: cgImage)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func performOCR(on image: CGImage) throws -> OCRResult {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "hi-IN"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results else {
            throw OCRError.noTextFound
        }
        
        // Extract all text with confidence scores
        var extractedTexts: [ExtractedText] = []
        var fullText = ""
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let text = topCandidate.string
            let confidence = observation.confidence
            let boundingBox = observation.boundingBox
            
            extractedTexts.append(ExtractedText(
                text: text,
                confidence: confidence,
                boundingBox: boundingBox
            ))
            
            fullText += text + " "
        }
        
        return OCRResult(
            fullText: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
            extractedTexts: extractedTexts,
            confidence: calculateOverallConfidence(extractedTexts)
        )
    }
    
    private func calculateOverallConfidence(_ texts: [ExtractedText]) -> Float {
        guard !texts.isEmpty else { return 0 }
        let sum = texts.reduce(0) { $0 + $1.confidence }
        return sum / Float(texts.count)
    }
}

/// Fuel receipt parser for extracting specific fields
class FuelReceiptParser {
    
    // MARK: - Parsing Patterns
    private let amountPatterns = [
        // ₹ symbol patterns
        #"₹\s*(\d+\.?\d*)"#,
        #"Rs\.?\s*(\d+\.?\d*)"#,
        #"INR\s*(\d+\.?\d*)"#,
        // Total/Amount patterns
        #"(?:Total|Amount|Amt)[\s:]*₹?\s*(\d+\.?\d*)"#,
        #"(?:Sale|Price)[\s:]*₹?\s*(\d+\.?\d*)"#,
        // Generic number pattern (likely largest number)
        #"(\d{3,}\.?\d*)"#
    ]
    
    private let litrePatterns = [
        // Litre/Liter patterns
        #"(\d+\.?\d*)\s*(?:L|Lt|Ltr|Litre|Liter|LITRE|LITER)"#,
        #"(?:Qty|Quantity|Vol|Volume)[\s:]*(\d+\.?\d*)"#,
        #"(?:Litre|Liter)s?[\s:]*(\d+\.?\d*)"#,
        // Decimal pattern for litres (usually 10-50 range)
        #"(?<!\d)(\d{1,2}\.\d{1,3})(?!\d)"#
    ]
    
    private let pricePerLitrePatterns = [
        // Rate/Price per litre
        #"(?:Rate|Price|Cost).*?(\d+\.?\d*)\s*/\s*(?:L|Lt|Ltr)"#,
        #"₹\s*(\d+\.?\d*)\s*/\s*(?:L|Lt|Ltr)"#,
        #"(\d+\.?\d*)\s*(?:per|/)\s*(?:L|Lt|Ltr|Litre|Liter)"#,
        // Price in 80-120 range (typical fuel price range in India)
        #"(?<!\d)((?:8|9|10|11)\d\.\d{2})(?!\d)"#
    ]
    
    private let stationPatterns = [
        // Indian fuel brands
        #"(?:IOCL|Indian\s*Oil|IndianOil)"#,
        #"(?:HPCL|Hindustan\s*Petroleum|HP)"#,
        #"(?:BPCL|Bharat\s*Petroleum|BP)"#,
        #"(?:Shell|SHELL)"#,
        #"(?:Reliance|RIL)"#,
        #"(?:Essar|ESSAR)"#,
        #"(?:Nayara|NAYARA)"#
    ]
    
    // MARK: - Main Parsing Method
    
    func parseFuelReceipt(from ocrResult: OCRResult) -> FuelReceiptData {
        let text = ocrResult.fullText
        
        // Extract individual fields
        let amount = extractAmount(from: text)
        let litres = extractLitres(from: text)
        let pricePerLitre = extractPricePerLitre(from: text)
        let station = extractStation(from: text)
        let fuelType = extractFuelType(from: text)
        
        // Validate and cross-check values
        let validatedData = validateAndReconcile(
            amount: amount,
            litres: litres,
            pricePerLitre: pricePerLitre
        )
        
        return FuelReceiptData(
            totalAmount: validatedData.amount,
            litres: validatedData.litres,
            pricePerLitre: validatedData.pricePerLitre,
            stationBrand: station,
            fuelType: fuelType,
            confidence: calculateConfidence(validatedData),
            rawText: text
        )
    }
    
    // MARK: - Field Extraction
    
    private func extractAmount(from text: String) -> ExtractedValue<Double>? {
        for pattern in amountPatterns {
            if let match = extractFirstMatch(pattern: pattern, from: text) {
                if let value = Double(match) {
                    // Validate amount range (₹100 - ₹10000 typical)
                    if value >= 100 && value <= 10000 {
                        return ExtractedValue(value: value, confidence: 0.8)
                    }
                }
            }
        }
        
        // Fallback: Find largest number
        let numbers = extractAllNumbers(from: text)
        if let largest = numbers.filter({ $0 >= 100 && $0 <= 10000 }).max() {
            return ExtractedValue(value: largest, confidence: 0.5)
        }
        
        return nil
    }
    
    private func extractLitres(from text: String) -> ExtractedValue<Double>? {
        for pattern in litrePatterns {
            if let match = extractFirstMatch(pattern: pattern, from: text) {
                if let value = Double(match) {
                    // Validate litre range (1-100 typical)
                    if value >= 0.5 && value <= 100 {
                        return ExtractedValue(value: value, confidence: 0.8)
                    }
                }
            }
        }
        return nil
    }
    
    private func extractPricePerLitre(from text: String) -> ExtractedValue<Double>? {
        for pattern in pricePerLitrePatterns {
            if let match = extractFirstMatch(pattern: pattern, from: text) {
                if let value = Double(match) {
                    // Validate price range (₹70-150 typical in India)
                    if value >= 70 && value <= 150 {
                        return ExtractedValue(value: value, confidence: 0.8)
                    }
                }
            }
        }
        return nil
    }
    
    private func extractStation(from text: String) -> String? {
        let upperText = text.uppercased()
        
        for pattern in stationPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                if regex.firstMatch(in: upperText, range: NSRange(upperText.startIndex..., in: upperText)) != nil {
                    // Map to standard brand names
                    if upperText.contains("IOCL") || upperText.contains("INDIAN") {
                        return "IOCL"
                    } else if upperText.contains("HPCL") || upperText.contains("HINDUSTAN") {
                        return "HPCL"
                    } else if upperText.contains("BPCL") || upperText.contains("BHARAT") {
                        return "BPCL"
                    } else if upperText.contains("SHELL") {
                        return "Shell"
                    } else if upperText.contains("RELIANCE") {
                        return "Reliance"
                    } else if upperText.contains("ESSAR") {
                        return "Essar"
                    } else if upperText.contains("NAYARA") {
                        return "Nayara"
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractFuelType(from text: String) -> String? {
        let upperText = text.uppercased()
        
        if upperText.contains("DIESEL") {
            return "Diesel"
        } else if upperText.contains("PETROL") || upperText.contains("GASOLINE") {
            return "Petrol"
        } else if upperText.contains("PREMIUM") || upperText.contains("POWER") || upperText.contains("XTRA") {
            return "Premium Petrol"
        }
        
        return nil
    }
    
    // MARK: - Validation & Reconciliation
    
    private func validateAndReconcile(
        amount: ExtractedValue<Double>?,
        litres: ExtractedValue<Double>?,
        pricePerLitre: ExtractedValue<Double>?
    ) -> (amount: Double?, litres: Double?, pricePerLitre: Double?) {
        
        // If we have all three, validate the calculation
        if let a = amount?.value, let l = litres?.value, let p = pricePerLitre?.value {
            let calculatedAmount = l * p
            let difference = abs(calculatedAmount - a)
            
            // Allow 5% margin for rounding
            if difference / a < 0.05 {
                return (a, l, p)
            }
        }
        
        // If we have two values, calculate the third
        if let a = amount?.value, let l = litres?.value {
            let calculatedPrice = a / l
            if calculatedPrice >= 70 && calculatedPrice <= 150 {
                return (a, l, calculatedPrice)
            }
        }
        
        if let a = amount?.value, let p = pricePerLitre?.value {
            let calculatedLitres = a / p
            if calculatedLitres >= 0.5 && calculatedLitres <= 100 {
                return (a, calculatedLitres, p)
            }
        }
        
        if let l = litres?.value, let p = pricePerLitre?.value {
            let calculatedAmount = l * p
            if calculatedAmount >= 100 && calculatedAmount <= 10000 {
                return (calculatedAmount, l, p)
            }
        }
        
        // Return whatever we have
        return (amount?.value, litres?.value, pricePerLitre?.value)
    }
    
    private func calculateConfidence(_ data: (amount: Double?, litres: Double?, pricePerLitre: Double?)) -> Float {
        var fieldsFound = 0
        
        if data.amount != nil { fieldsFound += 1 }
        if data.litres != nil { fieldsFound += 1 }
        if data.pricePerLitre != nil { fieldsFound += 1 }
        
        switch fieldsFound {
        case 3:
            return 0.9
        case 2:
            return 0.7
        case 1:
            return 0.5
        default:
            return 0.3
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractFirstMatch(pattern: String, from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else {
            return nil
        }
        
        // Get the first capture group if available, otherwise the whole match
        let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
        
        guard let swiftRange = Range(captureRange, in: text) else {
            return nil
        }
        
        return String(text[swiftRange])
    }
    
    private func extractAllNumbers(from text: String) -> [Double] {
        let pattern = #"\d+\.?\d*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return Double(text[range])
        }
    }
}

// MARK: - Models

struct OCRResult {
    let fullText: String
    let extractedTexts: [ExtractedText]
    let confidence: Float
}

struct ExtractedText {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

struct ExtractedValue<T> {
    let value: T
    let confidence: Float
}

struct FuelReceiptData {
    let totalAmount: Double?
    let litres: Double?
    let pricePerLitre: Double?
    let stationBrand: String?
    let fuelType: String?
    let confidence: Float
    let rawText: String
    
    var isValid: Bool {
        // At least 2 of 3 main fields should be present
        let fieldsPresent = [totalAmount, litres, pricePerLitre].compactMap { $0 }.count
        return fieldsPresent >= 2
    }
    
    var summary: String {
        var parts: [String] = []
        
        if let amount = totalAmount {
            parts.append("₹\(String(format: "%.2f", amount))")
        }
        if let litres = litres {
            parts.append("\(String(format: "%.2f", litres))L")
        }
        if let price = pricePerLitre {
            parts.append("₹\(String(format: "%.2f", price))/L")
        }
        
        return parts.joined(separator: " • ")
    }
}

// MARK: - Protocols

protocol OCRClient {
    func extractText(from image: UIImage) async throws -> OCRResult
}

// MARK: - Errors

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided"
        case .noTextFound:
            return "No text found in image"
        case .processingFailed:
            return "Failed to process image"
        }
    }
}