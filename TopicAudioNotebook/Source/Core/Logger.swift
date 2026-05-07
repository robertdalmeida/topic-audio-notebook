import Foundation
import os.log

enum LogCategory: String {
    case general = "General"
    case transcription = "Transcription"
    case summarization = "Summarization"
    case recording = "Recording"
    case repository = "Repository"
    case ui = "UI"
    case network = "Network"
    case audio = "Audio"
}

enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🔥"
        }
    }
}

final class Logger {
    static let shared = Logger()
    
    private let subsystem = Bundle.main.bundleIdentifier ?? "TopicAudioNotebook"
    private var loggers: [LogCategory: os.Logger] = [:]
    
    #if DEBUG
    var minimumLevel: LogLevel = .debug
    #else
    var minimumLevel: LogLevel = .info
    #endif
    
    private init() {
        for category in [LogCategory.general, .transcription, .summarization, .recording, .repository, .ui, .network, .audio] {
            loggers[category] = os.Logger(subsystem: subsystem, category: category.rawValue)
        }
    }
    
    private func logger(for category: LogCategory) -> os.Logger {
        loggers[category] ?? os.Logger(subsystem: subsystem, category: category.rawValue)
    }
    
    func log(
        _ message: String,
        level: LogLevel = .debug,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level >= minimumLevel else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let formattedMessage = "\(level.emoji) [\(fileName):\(line)] \(function) - \(message)"
        
        logger(for: category).log(level: level.osLogType, "\(formattedMessage)")
        
        #if DEBUG
        print(formattedMessage)
        #endif
    }
    
    func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }
}

let log = Logger.shared
