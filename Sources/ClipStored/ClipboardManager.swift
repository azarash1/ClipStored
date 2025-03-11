import Cocoa
import Collections
import Foundation

enum ClipboardCategory {
    case all
    case text
    case url
    case email
    case image
    
    var icon: String {
        switch self {
        case .all: return "doc.text"
        case .text: return "text.alignleft"
        case .url: return "link"
        case .email: return "envelope"
        case .image: return "photo"
        }
    }
    
    var color: NSColor {
        switch self {
        case .all: return .systemBlue
        case .text: return .secondaryLabelColor
        case .url: return .systemPurple
        case .email: return .systemGreen
        case .image: return .systemPink
        }
    }
    
    var title: String {
        switch self {
        case .all: return "All"
        case .text: return "Text"
        case .url: return "URLs"
        case .email: return "Email"
        case .image: return "Images"
        }
    }
}

/// Represents a clipboard item
class ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let content: NSObject
    var previewText: String
    var category: ClipboardCategory
    var previewImage: NSImage?
    
    init(content: NSObject, timestamp: Date = Date()) {
        self.content = content
        self.timestamp = timestamp
        
        // Determine category and preview text
        if let image = content as? NSImage {
            self.previewText = "Image"
            self.category = .image
            self.previewImage = image
        } else if let string = content as? NSString {
            let text = string as String
            self.previewText = text.count > 100 ? String(text.prefix(100)) + "..." : text
            self.category = Self.categorizeContent(text)
            self.previewImage = nil
        } else if let url = content as? NSURL {
            self.previewText = url.absoluteString ?? "URL"
            self.category = .url
            self.previewImage = nil
        } else if let attributedString = content as? NSAttributedString {
            let text = attributedString.string
            self.previewText = text.count > 100 ? String(text.prefix(100)) + "..." : text
            self.category = Self.categorizeContent(text)
            self.previewImage = nil
        } else {
            self.previewText = "Unsupported content type"
            self.category = .text
            self.previewImage = nil
        }
    }
    
    private static func categorizeContent(_ text: String) -> ClipboardCategory {
        // URL detection
        let urlPattern = "^(https?://)?([\\da-z.-]+)\\.([a-z.]{2,6})[/\\w .-]*/?$"
        if text.range(of: urlPattern, options: .regularExpression) != nil ||
           text.lowercased().hasPrefix("http") || 
           text.lowercased().hasPrefix("www.") {
            return .url
        }
        
        // Email detection
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        if text.range(of: emailPattern, options: .regularExpression) != nil {
            return .email
        }
        
        // Phone number detection
        let phonePattern = "^[+]?[(]?[0-9]{3}[)]?[-\\s.]?[0-9]{3}[-\\s.]?[0-9]{4,}$"
        if text.range(of: phonePattern, options: .regularExpression) != nil {
            return .text
        }
        
        return .text
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
}

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private var isMonitoring = false
    private var isUpdating = false
    
    // Use an empty deque initially
    @Published var clipboardHistory: Deque<ClipboardItem> = Deque()
    
    private init() {
        // Get the current pasteboard change count
        lastChangeCount = pasteboard.changeCount
        
        // Start monitoring
        startMonitoring()
        
        // Capture current clipboard content if any
        captureCurrentContents()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        // Stop any existing timer
        stopMonitoring()
        
        // Create a new timer that checks very frequently (20 times per second)
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        
        // Make sure the timer runs even during tracking and scrolling
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
            RunLoop.main.add(timer, forMode: .eventTracking)
        }
        
        isMonitoring = true
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    private func checkForChanges() {
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            // Use the main thread for UI updates
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isUpdating else { return }
                self.captureCurrentContents()
            }
        }
    }
    
    private func captureCurrentContents() {
        guard !isUpdating else { return }
        isUpdating = true
        
        // Detect the type of content in the clipboard
        if let string = pasteboard.string(forType: .string) {
            addToHistory(ClipboardItem(content: string as NSString))
        } else if let image = pasteboard.data(forType: .tiff).flatMap({ NSImage(data: $0) }) {
            addToHistory(ClipboardItem(content: image))
        } else if let url = pasteboard.string(forType: .URL).flatMap({ URL(string: $0) }) {
            addToHistory(ClipboardItem(content: url as NSURL))
        } else if let attributedString = pasteboard.data(forType: .rtf).flatMap({ try? NSAttributedString(data: $0, options: [:], documentAttributes: nil) }) {
            addToHistory(ClipboardItem(content: attributedString))
        }
        
        isUpdating = false
    }
    
    private func addToHistory(_ item: ClipboardItem) {
        // Run on main thread since we're updating the UI
        DispatchQueue.main.async {
            // Check for duplicates
            if let newString = item.content as? NSString {
                // If adding text, check if it already exists
                for (index, existingItem) in self.clipboardHistory.enumerated() {
                    if let existingString = existingItem.content as? NSString, 
                       existingString.isEqual(to: newString as String) {
                        self.clipboardHistory.remove(at: index)
                        break
                    }
                }
            }
            
            // Add to the front of the history
            self.clipboardHistory.prepend(item)
            
            // Limit history size (configurable in settings)
            while self.clipboardHistory.count > 50 {
                self.clipboardHistory.removeLast()
            }
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        // Stop monitoring temporarily to avoid feedback loop
        stopMonitoring()
        
        // Clear clipboard
        pasteboard.clearContents()
        
        // Copy item to clipboard based on type
        if let string = item.content as? NSString {
            pasteboard.setString(string as String, forType: .string)
        } else if let image = item.content as? NSImage {
            pasteboard.writeObjects([image])
        } else if let url = item.content as? NSURL {
            pasteboard.setString(url.absoluteString ?? "", forType: .string)
        } else if let attributedString = item.content as? NSAttributedString {
            if let rtfData = try? attributedString.data(from: .init(location: 0, length: attributedString.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
                pasteboard.setData(rtfData, forType: .rtf)
            }
            pasteboard.setString(attributedString.string, forType: .string)
        }
        
        // Update last change count
        lastChangeCount = pasteboard.changeCount
        
        // Resume monitoring after a very short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.startMonitoring()
        }
    }
} 