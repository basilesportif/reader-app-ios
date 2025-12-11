import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let historyManager: HistoryManager
    let onSelect: (QueryHistoryItem) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if historyManager.history.isEmpty {
                    emptyView
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !historyManager.history.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All", role: .destructive) {
                            historyManager.clearHistory()
                        }
                    }
                }
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No query history yet")
                .font(.headline)
                .foregroundColor(.primary)
            Text("Your queries will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var historyList: some View {
        List {
            ForEach(historyManager.history) { item in
                HistoryItemRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(item)
                        dismiss()
                    }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    historyManager.removeFromHistory(id: historyManager.history[index].id)
                }
            }
        }
        .listStyle(.plain)
    }
}

struct HistoryItemRow: View {
    let item: QueryHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let thumbnailData = item.thumbnail,
               let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.prompt)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack {
                    Text(item.model)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(item.relativeTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView(historyManager: HistoryManager()) { _ in }
}
