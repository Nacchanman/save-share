import SwiftUI

struct ArticleCardView<Actions: View>: View {
    let article: Article
    let ownerLabel: String
    var showMemo = false
    var leftHint: String?
    var rightHint: String?
    var onMemoChanged: (String) -> Void = { _ in }
    var onSwipeLeft: () -> Void = {}
    var onSwipeRight: () -> Void = {}
    @ViewBuilder let actions: () -> Actions

    @State private var dragOffset: CGFloat = 0
    @State private var memoText: String

    init(
        article: Article,
        ownerLabel: String,
        showMemo: Bool = false,
        leftHint: String? = nil,
        rightHint: String? = nil,
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
        self.onMemoChanged = onMemoChanged
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        self.actions = actions
        _memoText = State(initialValue: article.memo)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if leftHint != nil || rightHint != nil {
                HStack {
                    Text(leftHint.map { "← \($0)" } ?? "")
                    Spacer()
                    Text(rightHint.map { "\($0) →" } ?? "")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            }

            HStack {
                Text(ownerLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.blue.opacity(0.12), in: Capsule())
                Spacer()
                Text(article.host)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if let url = URL(string: article.url) {
                Link(article.title, destination: url)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.primary)
            } else {
                Text(article.title)
                    .font(.title3.weight(.black))
            }

            Text(article.url)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            if showMemo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("メモ").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    TextEditor(text: $memoText)
                        .frame(minHeight: 90)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                        .onChange(of: memoText) { newValue in onMemoChanged(newValue) }
                }
            }

            HStack(spacing: 10) {
                actions()
            }
        }
        .cardStyle(padding: 18)
        .offset(x: dragOffset)
        .rotationEffect(.degrees(dragOffset / 28))
        .gesture(
            DragGesture(minimumDistance: 18)
                .onChanged { value in dragOffset = value.translation.width }
                .onEnded { value in
                    if value.translation.width < -90 { onSwipeLeft() }
                    if value.translation.width > 90 { onSwipeRight() }
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) { dragOffset = 0 }
                }
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: dragOffset)
    }
}

enum AppTheme {
    static let blue = Color(red: 0.145, green: 0.341, blue: 0.839)
    static let background = LinearGradient(
        colors: [Color(red: 0.97, green: 0.98, blue: 1.0), Color(red: 0.88, green: 0.93, blue: 0.98)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func cardStyle(padding: CGFloat = 24) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }

    func fieldStyle() -> some View {
        self
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
