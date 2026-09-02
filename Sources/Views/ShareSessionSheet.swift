import SwiftUI
import UIKit

/// A Wordle-style share: plain monospaced text, copy-to-clipboard as the
/// primary action, with the native share sheet as a secondary option.
struct ShareSessionSheet: View {
    let session: BreakSession

    @Environment(\.dismiss) private var dismiss
    @State private var didCopy = false

    private var shareText: String {
        ShareText.wordleStyle(for: session)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                preview

                Spacer()

                VStack(spacing: 10) {
                    Button(action: copy) {
                        Label(didCopy ? "Copied" : "Copy", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.amber)
                    .sensoryFeedback(.success, trigger: didCopy)

                    ShareLink(item: shareText) {
                        Label("Share…", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var preview: some View {
        Text(shareText)
            .font(.system(size: 18, weight: .medium, design: .monospaced))
            .foregroundStyle(Theme.amber)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Theme.panelEdge, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
    }

    private func copy() {
        UIPasteboard.general.string = shareText
        withAnimation { didCopy = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { didCopy = false }
        }
    }
}

#Preview {
    ShareSessionSheet(session: .sample(minutes: 22))
}
