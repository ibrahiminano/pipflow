//
//  MQL5SyntaxValidator.swift
//  Pipflow
//
//  Validates generated MQL5 code syntax
//

import Foundation

class MQL5SyntaxValidator {
    static let shared = MQL5SyntaxValidator()
    
    private init() {}
    
    // MARK: - Validation Result
    
    struct ValidationResult {
        let isValid: Bool
        let errors: [SyntaxError]
        let warnings: [SyntaxWarning]
        let suggestions: [CodeSuggestion]
    }
    
    struct SyntaxError {
        let line: Int
        let column: Int
        let message: String
        let type: ErrorType
        
        enum ErrorType {
            case missingBracket
            case undefinedVariable
            case invalidFunction
            case syntaxError
            case typeError
            case logicError
        }
    }
    
    struct SyntaxWarning {
        let line: Int
        let message: String
        let type: WarningType
        
        enum WarningType {
            case unusedVariable
            case deprecatedFunction
            case performanceIssue
            case bestPractice
        }
    }
    
    struct CodeSuggestion {
        let line: Int
        let original: String
        let suggested: String
        let reason: String
    }
    
    // MARK: - Public Methods
    
    func validateMQL5Code(_ code: String) -> ValidationResult {
        let lines = code.components(separatedBy: .newlines)
        var errors: [SyntaxError] = []
        var warnings: [SyntaxWarning] = []
        var suggestions: [CodeSuggestion] = []
        
        // Perform various validation checks
        errors.append(contentsOf: checkBracketBalance(lines))
        errors.append(contentsOf: checkVariableDeclarations(lines))
        errors.append(contentsOf: checkFunctionCalls(lines))
        errors.append(contentsOf: checkTradeOperations(lines))
        
        warnings.append(contentsOf: checkBestPractices(lines))
        warnings.append(contentsOf: checkPerformanceIssues(lines))
        
        suggestions.append(contentsOf: generateCodeSuggestions(lines))
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            suggestions: suggestions
        )
    }
    
    // MARK: - Bracket Balance Check
    
    private func checkBracketBalance(_ lines: [String]) -> [SyntaxError] {
        var errors: [SyntaxError] = []
        var bracketStack: [(Character, Int, Int)] = []
        let bracketPairs: [Character: Character] = ["(": ")", "[": "]", "{": "}"]
        
        for (lineIndex, line) in lines.enumerated() {
            for (colIndex, char) in line.enumerated() {
                if bracketPairs.keys.contains(char) {
                    bracketStack.append((char, lineIndex, colIndex))
                } else if bracketPairs.values.contains(char) {
                    if let last = bracketStack.last,
                       bracketPairs[last.0] == char {
                        bracketStack.removeLast()
                    } else {
                        errors.append(SyntaxError(
                            line: lineIndex + 1,
                            column: colIndex + 1,
                            message: "Unmatched closing bracket '\(char)'",
                            type: .missingBracket
                        ))
                    }
                }
            }
        }
        
        // Check for unclosed brackets
        for bracket in bracketStack {
            errors.append(SyntaxError(
                line: bracket.1 + 1,
                column: bracket.2 + 1,
                message: "Unclosed bracket '\(bracket.0)'",
                type: .missingBracket
            ))
        }
        
        return errors
    }
    
    // MARK: - Variable Declaration Check
    
    private func checkVariableDeclarations(_ lines: [String]) -> [SyntaxError] {
        var errors: [SyntaxError] = []
        var declaredVariables = Set<String>()
        let typeKeywords = ["int", "double", "bool", "string", "datetime", "color", "void"]
        
        // Add built-in variables
        declaredVariables.formUnion([
            "Symbol", "Period", "Point", "Digits", "Bid", "Ask",
            "Volume", "Time", "Open", "High", "Low", "Close"
        ])
        
        for (lineIndex, line) in lines.enumerated() {
            // Check for variable declarations
            for type in typeKeywords {
                let pattern = "\\b\(type)\\s+(\\w+)"
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))
                    for match in matches {
                        if let range = Range(match.range(at: 1), in: line) {
                            let varName = String(line[range])
                            declaredVariables.insert(varName)
                        }
                    }
                }
            }
            
            // Check for variable usage
            let varPattern = "\\b(\\w+)\\s*[=<>!]"
            if let regex = try? NSRegularExpression(pattern: varPattern) {
                let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))
                for match in matches {
                    if let range = Range(match.range(at: 1), in: line) {
                        let varName = String(line[range])
                        if !declaredVariables.contains(varName) && 
                           !typeKeywords.contains(varName) &&
                           !isMQL5Function(varName) {
                            errors.append(SyntaxError(
                                line: lineIndex + 1,
                                column: match.range.location + 1,
                                message: "Undefined variable '\(varName)'",
                                type: .undefinedVariable
                            ))
                        }
                    }
                }
            }
        }
        
        return errors
    }
    
    // MARK: - Function Call Check
    
    private func checkFunctionCalls(_ lines: [String]) -> [SyntaxError] {
        var errors: [SyntaxError] = []
        
        for (lineIndex, line) in lines.enumerated() {
            let functionPattern = "\\b(\\w+)\\s*\\("
            if let regex = try? NSRegularExpression(pattern: functionPattern) {
                let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))
                for match in matches {
                    if let range = Range(match.range(at: 1), in: line) {
                        let funcName = String(line[range])
                        if !isMQL5Function(funcName) && !isUserDefinedFunction(funcName, in: lines) {
                            errors.append(SyntaxError(
                                line: lineIndex + 1,
                                column: match.range.location + 1,
                                message: "Unknown function '\(funcName)'",
                                type: .invalidFunction
                            ))
                        }
                    }
                }
            }
        }
        
        return errors
    }
    
    // MARK: - Trade Operation Check
    
    private func checkTradeOperations(_ lines: [String]) -> [SyntaxError] {
        var errors: [SyntaxError] = []
        
        for (lineIndex, line) in lines.enumerated() {
            // Check for OrderSend without proper parameters
            if line.contains("OrderSend") && !line.contains("Symbol()") {
                errors.append(SyntaxError(
                    line: lineIndex + 1,
                    column: 1,
                    message: "OrderSend should include Symbol() parameter",
                    type: .logicError
                ))
            }
            
            // Check for position operations without magic number
            if (line.contains("PositionOpen") || line.contains("trade.Buy") || line.contains("trade.Sell")) &&
               !lines[max(0, lineIndex - 5)..<min(lines.count, lineIndex + 5)].contains(where: { $0.contains("SetExpertMagicNumber") }) {
                errors.append(SyntaxError(
                    line: lineIndex + 1,
                    column: 1,
                    message: "Trade operations should use magic number",
                    type: .logicError
                ))
            }
        }
        
        return errors
    }
    
    // MARK: - Best Practices Check
    
    private func checkBestPractices(_ lines: [String]) -> [SyntaxWarning] {
        var warnings: [SyntaxWarning] = []
        
        for (lineIndex, line) in lines.enumerated() {
            // Check for hardcoded values
            if let _ = line.range(of: "\\b\\d+\\.\\d{5,}\\b", options: .regularExpression) {
                warnings.append(SyntaxWarning(
                    line: lineIndex + 1,
                    message: "Avoid hardcoding price values, use Symbol properties",
                    type: .bestPractice
                ))
            }
            
            // Check for missing error handling
            if line.contains("OrderSend") && !lines[lineIndex..<min(lineIndex + 3, lines.count)].contains(where: { $0.contains("GetLastError") }) {
                warnings.append(SyntaxWarning(
                    line: lineIndex + 1,
                    message: "Add error handling after OrderSend",
                    type: .bestPractice
                ))
            }
            
            // Check for Print statements in production
            if line.contains("Print(") && !line.contains("DEBUG") {
                warnings.append(SyntaxWarning(
                    line: lineIndex + 1,
                    message: "Consider using conditional debug prints",
                    type: .bestPractice
                ))
            }
        }
        
        return warnings
    }
    
    // MARK: - Performance Check
    
    private func checkPerformanceIssues(_ lines: [String]) -> [SyntaxWarning] {
        var warnings: [SyntaxWarning] = []
        
        for (lineIndex, line) in lines.enumerated() {
            // Check for inefficient loops
            if line.contains("for") && line.contains("PositionsTotal()") {
                warnings.append(SyntaxWarning(
                    line: lineIndex + 1,
                    message: "Cache PositionsTotal() result before loop",
                    type: .performanceIssue
                ))
            }
            
            // Check for repeated indicator calls
            if line.contains("iRSI") || line.contains("iMA") || line.contains("iMACD") {
                let indicatorCount = lines.filter { $0.contains("iRSI") || $0.contains("iMA") || $0.contains("iMACD") }.count
                if indicatorCount > 3 {
                    warnings.append(SyntaxWarning(
                        line: lineIndex + 1,
                        message: "Consider caching indicator handles in OnInit",
                        type: .performanceIssue
                    ))
                }
            }
        }
        
        return warnings
    }
    
    // MARK: - Code Suggestions
    
    private func generateCodeSuggestions(_ lines: [String]) -> [CodeSuggestion] {
        var suggestions: [CodeSuggestion] = []
        
        for (lineIndex, line) in lines.enumerated() {
            // Suggest using constants
            if let match = line.range(of: "InpStopLoss = \\d+", options: .regularExpression) {
                let original = String(line[match])
                suggestions.append(CodeSuggestion(
                    line: lineIndex + 1,
                    original: original,
                    suggested: "input int InpStopLoss = 50; // Stop Loss in pips",
                    reason: "Add descriptive comment for input parameters"
                ))
            }
            
            // Suggest proper error handling
            if line.contains("trade.Buy(") && !line.contains("if(") {
                suggestions.append(CodeSuggestion(
                    line: lineIndex + 1,
                    original: line.trimmingCharacters(in: .whitespaces),
                    suggested: "if(!trade.Buy(...)) { Print(\"Buy failed: \", GetLastError()); }",
                    reason: "Add error handling for trade operations"
                ))
            }
        }
        
        return suggestions
    }
    
    // MARK: - Helper Methods
    
    private func isMQL5Function(_ name: String) -> Bool {
        let mql5Functions = [
            // Trade functions
            "OrderSend", "OrderSelect", "OrderClose", "OrderModify", "OrderDelete",
            "PositionOpen", "PositionClose", "PositionModify", "PositionSelect",
            
            // Market info
            "SymbolInfoDouble", "SymbolInfoInteger", "SymbolInfoString", "MarketInfo",
            
            // Account functions
            "AccountBalance", "AccountEquity", "AccountProfit", "AccountMargin",
            
            // Indicator functions
            "iRSI", "iMA", "iMACD", "iBands", "iATR", "iCCI", "iStochastic",
            
            // Math functions
            "MathAbs", "MathMax", "MathMin", "MathRound", "MathSqrt", "MathPow",
            
            // String functions
            "StringLen", "StringSubstr", "StringFind", "StringReplace",
            
            // Array functions
            "ArraySize", "ArrayResize", "ArraySort", "ArrayCopy",
            
            // Time functions
            "TimeCurrent", "TimeLocal", "TimeToString", "StringToTime",
            
            // Other common functions
            "Print", "Alert", "Comment", "GetLastError", "Sleep",
            "NormalizeDouble", "RefreshRates", "IsTradeAllowed"
        ]
        
        return mql5Functions.contains(name)
    }
    
    private func isUserDefinedFunction(_ name: String, in lines: [String]) -> Bool {
        let functionPattern = "\\b(void|int|double|bool|string)\\s+\(name)\\s*\\("
        return lines.contains { line in
            if let regex = try? NSRegularExpression(pattern: functionPattern) {
                return regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil
            }
            return false
        }
    }
}

// MARK: - Code Quality Analyzer

extension MQL5SyntaxValidator {
    
    struct CodeQualityReport {
        let score: Double // 0-100
        let complexity: ComplexityLevel
        let maintainability: Double // 0-100
        let readability: Double // 0-100
        let testability: Double // 0-100
        let recommendations: [String]
    }
    
    enum ComplexityLevel {
        case low
        case medium
        case high
        case veryHigh
        
        var description: String {
            switch self {
            case .low: return "Low Complexity"
            case .medium: return "Medium Complexity"
            case .high: return "High Complexity"
            case .veryHigh: return "Very High Complexity"
            }
        }
    }
    
    func analyzeCodeQuality(_ code: String) -> CodeQualityReport {
        let lines = code.components(separatedBy: .newlines)
        
        // Calculate metrics
        let complexity = calculateCyclomaticComplexity(lines)
        let maintainability = calculateMaintainability(lines)
        let readability = calculateReadability(lines)
        let testability = calculateTestability(lines)
        
        // Overall score
        let score = (maintainability + readability + testability) / 3
        
        // Generate recommendations
        let recommendations = generateQualityRecommendations(
            complexity: complexity,
            maintainability: maintainability,
            readability: readability,
            testability: testability
        )
        
        return CodeQualityReport(
            score: score,
            complexity: complexity,
            maintainability: maintainability,
            readability: readability,
            testability: testability,
            recommendations: recommendations
        )
    }
    
    private func calculateCyclomaticComplexity(_ lines: [String]) -> ComplexityLevel {
        var complexity = 1
        
        for line in lines {
            // Count decision points
            if line.contains("if") || line.contains("else") ||
               line.contains("for") || line.contains("while") ||
               line.contains("switch") || line.contains("case") ||
               line.contains("&&") || line.contains("||") {
                complexity += 1
            }
        }
        
        switch complexity {
        case 0...10: return .low
        case 11...20: return .medium
        case 21...50: return .high
        default: return .veryHigh
        }
    }
    
    private func calculateMaintainability(_ lines: [String]) -> Double {
        var score = 100.0
        
        // Deduct for long functions
        let functionLengths = getFunctionLengths(lines)
        for length in functionLengths {
            if length > 50 { score -= 10 }
            else if length > 30 { score -= 5 }
        }
        
        // Deduct for lack of comments
        let commentRatio = Double(lines.filter { $0.contains("//") || $0.contains("/*") }.count) / Double(max(lines.count, 1))
        if commentRatio < 0.1 { score -= 20 }
        else if commentRatio < 0.2 { score -= 10 }
        
        // Deduct for deep nesting
        let maxNesting = calculateMaxNesting(lines)
        if maxNesting > 4 { score -= 15 }
        else if maxNesting > 3 { score -= 10 }
        
        return max(0, score)
    }
    
    private func calculateReadability(_ lines: [String]) -> Double {
        var score = 100.0
        
        // Check variable naming
        let poorlyNamedVars = lines.filter { line in
            line.contains(#"\b[a-z]\s*="#) || line.contains(#"\b[a-z]\d\s*="#)
        }.count
        score -= Double(poorlyNamedVars) * 2
        
        // Check line length
        let longLines = lines.filter { $0.count > 120 }.count
        score -= Double(longLines) * 1
        
        // Check consistent formatting
        let inconsistentSpacing = lines.filter { line in
            line.contains("if(") || line.contains("for(") || line.contains("while(")
        }.count
        score -= Double(inconsistentSpacing) * 0.5
        
        return max(0, score)
    }
    
    private func calculateTestability(_ lines: [String]) -> Double {
        var score = 100.0
        
        // Check for global state
        let globalVars = lines.filter { $0.contains("static") && !$0.contains("const") }.count
        score -= Double(globalVars) * 5
        
        // Check for side effects in functions
        let sideEffects = lines.filter { $0.contains("Print") || $0.contains("Alert") || $0.contains("Comment") }.count
        score -= Double(sideEffects) * 2
        
        // Check for hardcoded values
        let hardcodedValues = lines.filter { line in
            line.contains(#"\b\d+\.\d{4,}\b"#) && !line.contains("input")
        }.count
        score -= Double(hardcodedValues) * 3
        
        return max(0, score)
    }
    
    private func getFunctionLengths(_ lines: [String]) -> [Int] {
        var lengths: [Int] = []
        var currentLength = 0
        var inFunction = false
        var bracketCount = 0
        
        for line in lines {
            if line.contains("int ") || line.contains("void ") || line.contains("double ") || line.contains("bool ") {
                if line.contains("(") && line.contains(")") && !line.contains(";") {
                    inFunction = true
                    currentLength = 0
                    bracketCount = 0
                }
            }
            
            if inFunction {
                currentLength += 1
                bracketCount += line.filter { $0 == "{" }.count
                bracketCount -= line.filter { $0 == "}" }.count
                
                if bracketCount == 0 && currentLength > 1 {
                    lengths.append(currentLength)
                    inFunction = false
                }
            }
        }
        
        return lengths
    }
    
    private func calculateMaxNesting(_ lines: [String]) -> Int {
        var maxNesting = 0
        var currentNesting = 0
        
        for line in lines {
            currentNesting += line.filter { $0 == "{" }.count
            maxNesting = max(maxNesting, currentNesting)
            currentNesting -= line.filter { $0 == "}" }.count
        }
        
        return maxNesting
    }
    
    private func generateQualityRecommendations(complexity: ComplexityLevel, maintainability: Double, readability: Double, testability: Double) -> [String] {
        var recommendations: [String] = []
        
        if complexity == .high || complexity == .veryHigh {
            recommendations.append("Consider breaking down complex functions into smaller ones")
        }
        
        if maintainability < 70 {
            recommendations.append("Add more comments to explain complex logic")
            recommendations.append("Reduce function length to improve maintainability")
        }
        
        if readability < 70 {
            recommendations.append("Use more descriptive variable names")
            recommendations.append("Keep line length under 120 characters")
        }
        
        if testability < 70 {
            recommendations.append("Reduce global state and side effects")
            recommendations.append("Extract hardcoded values to input parameters")
        }
        
        return recommendations
    }
}