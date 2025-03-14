import SwiftUI
import AppKit

struct ClipboardHistoryView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var selectedIndex: Int? = nil
    @State private var lastCopiedIndex: Int? = nil
    @State private var showCopyFeedback = false
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var selectedCategory: ClipboardCategory = .all
    
    var filteredHistory: [(Int, ClipboardItem)] {
        Array(clipboardManager.clipboardHistory.enumerated()).filter { _, item in
            switch selectedCategory {
            case .all:
                return item.category != .image
            case .text:
                return item.category == .text
            case .url, .email, .image:
                return item.category == selectedCategory
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text("ClipStored History")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(filteredHistory.count) items")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                
                // Category filter buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        CategoryButton(
                            icon: ClipboardCategory.all.icon,
                            title: ClipboardCategory.all.title,
                            color: Color(ClipboardCategory.all.color),
                            isSelected: selectedCategory == .all
                        ) {
                            selectedCategory = .all
                        }
                        
                        CategoryButton(
                            icon: ClipboardCategory.text.icon,
                            title: ClipboardCategory.text.title,
                            color: Color(ClipboardCategory.text.color),
                            isSelected: selectedCategory == .text
                        ) {
                            selectedCategory = .text
                        }
                        
                        CategoryButton(
                            icon: ClipboardCategory.url.icon,
                            title: ClipboardCategory.url.title,
                            color: Color(ClipboardCategory.url.color),
                            isSelected: selectedCategory == .url
                        ) {
                            selectedCategory = .url
                        }
                        
                        CategoryButton(
                            icon: ClipboardCategory.email.icon,
                            title: ClipboardCategory.email.title,
                            color: Color(ClipboardCategory.email.color),
                            isSelected: selectedCategory == .email
                        ) {
                            selectedCategory = .email
                        }
                        
                        CategoryButton(
                            icon: ClipboardCategory.image.icon,
                            title: ClipboardCategory.image.title,
                            color: Color(ClipboardCategory.image.color),
                            isSelected: selectedCategory == .image
                        ) {
                            selectedCategory = .image
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredHistory, id: \.1.id) { index, item in
                            ClipboardItemRow(
                                item: item,
                                isSelected: selectedIndex == index,
                                isLastCopied: lastCopiedIndex == index && showCopyFeedback,
                                action: {
                                    handleItemSelection(index: index, item: item)
                                }
                            )
                            .id(item.id)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: clipboardManager.clipboardHistory) { newHistory in
                    if !newHistory.isEmpty {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(newHistory.first?.id, anchor: .top)
                            selectedIndex = 0
                        }
                    }
                }
                .onAppear {
                    scrollViewProxy = proxy
                    if let firstItem = clipboardManager.clipboardHistory.first {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(firstItem.id, anchor: .top)
                            selectedIndex = 0
                        }
                    }
                }
            }
        }
        .frame(width: 300, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                handleKeyEvent(event)
                return event
            }
            
            // Disable full-screen button
            if let window = NSApplication.shared.windows.first {
                window.collectionBehavior = .managed
                window.styleMask.remove(.resizable)
                window.styleMask.remove(.fullScreen)
            }
        }
    }
    
    private func handleItemSelection(index: Int, item: ClipboardItem) {
        withAnimation(.easeOut(duration: 0.2)) {
            selectedIndex = index
            lastCopiedIndex = index
            showCopyFeedback = true
        }
        
        clipboardManager.copyToClipboard(item)
        
        // Hide feedback after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                showCopyFeedback = false
            }
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        switch event.keyCode {
        case 126: // Up arrow
            if let currentIndex = selectedIndex {
                let newIndex = max(0, currentIndex - 1)
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedIndex = newIndex
                    if let item = clipboardManager.clipboardHistory[safe: newIndex] {
                        scrollViewProxy?.scrollTo(item.id, anchor: .center)
                    }
                }
            } else if let firstItem = clipboardManager.clipboardHistory.first {
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedIndex = 0
                    scrollViewProxy?.scrollTo(firstItem.id, anchor: .center)
                }
            }
        case 125: // Down arrow
            if let currentIndex = selectedIndex {
                let newIndex = min(clipboardManager.clipboardHistory.count - 1, currentIndex + 1)
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedIndex = newIndex
                    if let item = clipboardManager.clipboardHistory[safe: newIndex] {
                        scrollViewProxy?.scrollTo(item.id, anchor: .center)
                    }
                }
            } else if let firstItem = clipboardManager.clipboardHistory.first {
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedIndex = 0
                    scrollViewProxy?.scrollTo(firstItem.id, anchor: .center)
                }
            }
        case 36: // Return key
            if let index = selectedIndex,
               let item = clipboardManager.clipboardHistory[safe: index] {
                handleItemSelection(index: index, item: item)
            }
        default:
            break
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let isLastCopied: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Category Icon
                Image(systemName: item.category.icon)
                    .foregroundColor(Color(item.category.color))
                    .font(.system(size: 12))
                    .frame(width: 14)
                
                if item.category == .image, let image = item.previewImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 36)
                        .cornerRadius(3)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.previewText)
                            .lineLimit(2)
                            .font(.system(size: 12))
                            .foregroundColor(isSelected || isLastCopied ? .white : .primary)
                        
                        HStack(spacing: 4) {
                            Text(item.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 10))
                                .foregroundColor(isSelected || isLastCopied ? .white.opacity(0.8) : .secondary)
                            
                            if isLastCopied {
                                Text("Copied!")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(
                                        Capsule()
                                            .fill(Color.green.opacity(0.3))
                                    )
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Quick Actions Menu
                if !isSelected && !isLastCopied {
                    Menu {
                        if item.category == .url, 
                           let urlString = (item.content as? NSString) as String?,
                           let url = URL(string: urlString) {
                            Button("Open URL") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        
                        if item.category == .email,
                           let email = (item.content as? NSString) as String? {
                            Button("Send Email") {
                                NSWorkspace.shared.open(URL(string: "mailto:\(email)")!)
                            }
                        }
                        
                        Button("Share...") {
                            let picker = NSSharingServicePicker(items: [item.content])
                            if let window = NSApp.windows.first,
                               let view = window.contentView {
                                picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                    }
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
    
    private var backgroundColor: Color {
        if isLastCopied {
            return Color.green
        } else if isSelected {
            return Color.accentColor
        }
        return Color(NSColor.controlBackgroundColor)
    }
}

struct CategoryButton: View {
    let icon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// Helper extension for safe array access
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ClipboardHistoryView()
        .environmentObject(ClipboardManager.shared)
} 