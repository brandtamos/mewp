import SwiftUI

/// Presents a session's share card and rasterizes it on appearance so
/// ShareLink has an actual image to hand off, not just the live view.
struct ShareSessionSheet: View {
    let session: BreakSession

    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: Image?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ShareCardView(session: session)
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 10)

                Spacer()

                if let renderedImage {
                    ShareLink(
                        item: renderedImage,
                        preview: SharePreview("MEWP Fare", image: renderedImage)
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.amber)
                    .padding(.horizontal, 20)
                } else {
                    ProgressView()
                        .padding(.vertical, 12)
                }
            }
            .padding(.bottom, 24)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { render() }
        }
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: ShareCardView(session: session))
        renderer.scale = 3
        renderedImage = renderer.uiImage.map(Image.init(uiImage:))
    }
}

#Preview {
    ShareSessionSheet(session: .sample(minutes: 22))
}
