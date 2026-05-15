import LinkPresentation
import SwiftUI
import UIKit

struct ArticleCardView<Actions: View>: View {
    let article: Article
    let ownerLabel: String
    var showMemo = false
    var leftHint: String?
    var rightHint: String?
    var isLiked = false
    var likes: Int?
    var onMemoChanged: (String) -> Void = { _ in }
    var onSwipeLeft: () -> Void = {}
    var onSwipeRight: () -> Void = {}
    @ViewBuilder let actions: () -> Actions

    @State private var dragOffset: CGFloat = 0
    @State private var memoText: String
    @State private var previewImage: UIImage?

    init(
        article: Article,
        ownerLabel: String,
        showMemo: Bool = false,
        leftHint: String? = nil,
        rightHint: String? = nil,
        isLiked: Bool = false,
        likes: Int? = nil,
        onMemoChanged: @escaping (String) -> Void = { _ in },
        onSwipeLeft: @escaping () -> Void = {},
        onSwipeRight: @escaping () -> Void = {},
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.article = article
        self.ownerLabel = ownerLabel
        self.showMemo = showMemo
        self.leftHint = leftHint
        self.rightHint = rightHint
        self.isLiked = isLiked
        self.likes = likes
        self.onMemoChanged = onMemoChanged
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        self.actions = actions
        _memoText = State(initialValue: article.memo)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            preview
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(alignment: .topLeading) { badge(ownerLabel) }
                .overlay(alignment: .topTrailing) { likesBadge }
                .overlay(alignment: .bottom) { swipeHints }

            VStack(alignment: .leading, spacing: 14) {
                Text(article.host.uppercased())
                    .font(.caption.weight(.black))
                    .foregroundStyle(AppTheme.blue)
                    .tracking(0.9)

                if let url = URL(string: article.url) {
                    Link(article.title, destination: url)
                        .font(.title2.weight(.black))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                } else {
                    Text(article.title)
                        .font(.title2.weight(.black))
                        .lineLimit(3)
                }

                if showMemo {
                    TextEditor(text: $memoText)
                        .frame(minHeight: 78)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(alignment: .topLeading) {
                            if memoText.isEmpty {
                                Text("メモ")
                                    .foregroundStyle(.secondary.opacity(0.7))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 18)
                                    .allowsHitTesting(false)
                            }
                        }
                        .onChange(of: memoText) { newValue in onMemoChanged(newValue) }
                }

                HStack(spacing: 10) { actions() }
            }
            .padding(18)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(.white.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 24, y: 14)
        .offset(x: dragOffset)
        .rotationEffect(.degrees(dragOffset / 30))
        .gesture(
            DragGesture(minimumDistance: 18)
                .onChanged { value in dragOffset = value.translation.width }
                .onEnded { value in
                    if value.translation.width < -90 { onSwipeLeft() }
                    if value.translation.width > 90 { onSwipeRight() }
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) { dragOffset = 0 }
                }
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.78), value: dragOffset)
        .task(id: article.url) { await loadPreviewImage() }
    }

    private var preview: some View {
        ZStack {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [AppTheme.blue, .purple, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 42, weight: .bold))
                    Text(article.host)
                        .font(.headline.weight(.black))
                }
                .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    @ViewBuilder
    private var likesBadge: some View {
        if let likes {
            Label("\(likes)", systemImage: isLiked ? "heart.fill" : "heart")
                .font(.caption.weight(.black))
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .foregroundStyle(.white)
                .background(.black.opacity(0.32), in: Capsule())
                .padding(12)
        }
    }

    @ViewBuilder
    private var swipeHints: some View {
        if leftHint != nil || rightHint != nil {
            HStack {
                Text(leftHint.map { "← \($0)" } ?? "")
                Spacer()
                Text(rightHint.map { "\($0) →" } ?? "")
            }
            .font(.caption.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.black.opacity(0.24))
        }
    }

    private func badge(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.32), in: Capsule())
            .padding(12)
    }

    private func loadPreviewImage() async {
        guard let url = URL(string: article.url) else { return }
        do {
            let metadata = try await LPMetadataProvider().metadata(for: url)
            guard let provider = metadata.imageProvider ?? metadata.iconProvider else { return }
            let image = await provider.loadUIImage()
            await MainActor.run { previewImage = image }
        } catch {
            await MainActor.run { previewImage = nil }
        }
    }
}

private extension LPMetadataProvider {
    func metadata(for url: URL) async throws -> LPLinkMetadata {
        try await withCheckedThrowingContinuation { continuation in
            startFetchingMetadata(for: url) { metadata, error in
                if let metadata {
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: error ?? URLError(.badServerResponse))
                }
            }
        }
    }
}

private extension NSItemProvider {
    func loadUIImage() async -> UIImage? {
        await withCheckedContinuation { continuation in
            if canLoadObject(ofClass: UIImage.self) {
                loadObject(ofClass: UIImage.self) { object, _ in
                    continuation.resume(returning: object as? UIImage)
                }
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}

enum AppTheme {
    static let blue = Color(red: 0.145, green: 0.341, blue: 0.839)
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.12, green: 0.32, blue: 0.95), Color(red: 0.56, green: 0.28, blue: 0.96), Color(red: 1.0, green: 0.31, blue: 0.48)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let background = LinearGradient(
        colors: [Color(red: 0.98, green: 0.98, blue: 1.0), Color(red: 0.91, green: 0.94, blue: 1.0), Color(red: 0.96, green: 0.91, blue: 0.98)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func glassCard(padding: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.65), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 22, y: 12)
    }

    func fieldStyle() -> some View {
        self
            .padding(14)
            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.8), lineWidth: 1)
            )
    }
}
