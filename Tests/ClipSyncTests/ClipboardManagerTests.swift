import XCTest
@testable import ClipSync

final class ClipboardManagerTests: XCTestCase {
    var clipboardManager: ClipboardManager!
    
    override func setUp() {
        super.setUp()
        clipboardManager = ClipboardManager.shared
        clipboardManager.stopMonitoring() // Stop automatic monitoring during tests
    }
    
    override func tearDown() {
        // Clean up
        clipboardManager.clipboardHistory.removeAll()
        super.tearDown()
    }
    
    func testAddingItemToHistory() {
        // Given an empty history
        XCTAssertEqual(clipboardManager.clipboardHistory.count, 0, "History should start empty")
        
        // When adding a test string
        let testString = "Test string" as NSString
        let item = ClipboardItem(content: testString)
        
        // Directly add to history using reflection (since addToHistory is private)
        let mirror = Mirror(reflecting: clipboardManager)
        if let addToHistory = mirror.children.first(where: { $0.label == "addToHistory" })?.value as? (ClipboardItem) -> Void {
            addToHistory(item)
        } else {
            // Fallback if reflection fails - we'll just check if monitoring captures items
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(testString as String, forType: .string)
            clipboardManager.startMonitoring()
            // Wait briefly for the timer to fire
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
            clipboardManager.stopMonitoring()
        }
        
        // Then the history should contain our item
        XCTAssertGreaterThan(clipboardManager.clipboardHistory.count, 0, "Item should be added to history")
        
        if let firstItem = clipboardManager.clipboardHistory.first {
            XCTAssertEqual((firstItem.content as? NSString) as String?, testString as String, "Item content should match")
        } else {
            XCTFail("No item in history")
        }
    }
    
    func testCopyToClipboard() {
        // Given a test string item
        let testString = "Test copy to clipboard" as NSString
        let item = ClipboardItem(content: testString)
        
        // Clear the clipboard and copy our item
        NSPasteboard.general.clearContents()
        clipboardManager.copyToClipboard(item)
        
        // Then the clipboard should contain our test string
        let clipboardString = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(clipboardString, testString as String, "Copied string should be on clipboard")
    }
} 