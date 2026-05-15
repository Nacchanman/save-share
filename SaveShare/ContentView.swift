import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: SaveShareStore
    @State private var selectedPage: AppPage = .important
    @State private var urlText = ""
    @State private var titleText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        quickSave
                        pageTabs
                        pageContent
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                }
            }
            .navigationTitle("Save & Share")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var quickSave: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "link.badge.plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("あとで読む")
                        .font(.title2.weight(.black))
                    Text("URLを貼るだけ")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            TextField("https://example.com/article", text: $urlText)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .textContentType(.URL)
                .fieldStyle()

            HStack(spacing: 10) {
                TextField("タイトル（任意）", text: $titleText)
                    .fieldStyle()

                Button {
                    store.addArticle(url: urlText, title: titleText)
                    urlText = ""
                    titleText = ""
                    selectedPage = .important
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.black))
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(AppTheme.accentGradient, in: Circle())
                .shadow(color: AppTheme.blue.opacity(0.28), radius: 18, y: 10)
            }
        }
        .glassCard()
    }

    private var pageTabs: some View {
        HStack(spacing: 8) {
            ForEach(AppPage.allCases) { page in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selectedPage = page
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: page.symbolName)
                            .font(.headline)
                        Text(page.title)
                            .font(.caption.weight(.bold))
                        Text("\(store.count(for: page))")
                            .font(.caption2.weight(.black))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(selectedPage == page ? .white.opacity(0.22) : AppTheme.blue.opacity(0.10), in: Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(selectedPage == page ? .white : .primary)
                    .background(selectedPage == page ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(.ultraThinMaterial), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(.white.opacity(selectedPage == page ? 0 : 0.55), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch selectedPage {
        case .feed:
            VStack(alignment: .leading, spacing: 14) {
                peopleStrip
                ArticleSection(
                    title: "フィード",
                    emptyText: "共有記事はまだありません。",
                    articles: store.feedArticles
                ) { article in
                    ArticleCardView(
                        article: article,
                        ownerLabel: article.ownerId == "me" ? "You" : article.ownerName,
                        isLiked: store.likedArticleIds.contains(article.id),
                        likes: article.likes
                    ) {
                        PrimaryPill(title: "保存", systemImage: "bookmark") {
                            store.saveFromFeed(article)
                            selectedPage = .important
                        }
                        IconPill(systemImage: store.likedArticleIds.contains(article.id) ? "heart.fill" : "heart") {
                            store.toggleLike(article)
                        }
                        .tint(.pink)
                    }
                }
            }

        case .important:
            ArticleSection(
                title: "重要",
                emptyText: "URLを追加しよう。",
                articles: store.importantArticles
            ) { article in
                ArticleCardView(
                    article: article,
                    ownerLabel: "重要",
                    showMemo: true,
                    leftHint: "共有",
                    rightHint: "ゴミ箱",
                    onMemoChanged: { store.updateMemo(for: article, memo: $0) },
                    onSwipeLeft: { store.move(article, to: .shared) },
                    onSwipeRight: { store.move(article, to: .tired) }
                ) {
                    PrimaryPill(title: "共有", systemImage: "paperplane") { store.move(article, to: .shared) }
                    SecondaryPill(title: "ゴミ箱", systemImage: "trash") { store.move(article, to: .tired) }
                }
            }

        case .trash:
            ArticleSection(
                title: "ゴミ箱",
                emptyText: "空です。",
                articles: store.tiredArticles
            ) { article in
                ArticleCardView(
                    article: article,
                    ownerLabel: "ゴミ箱",
                    showMemo: true,
                    rightHint: "削除",
                    onMemoChanged: { store.updateMemo(for: article, memo: $0) },
                    onSwipeRight: { store.delete(article) }
                ) {
                    PrimaryPill(title: "戻す", systemImage: "arrow.uturn.left") { store.move(article, to: .important) }
                    SecondaryPill(title: "削除", systemImage: "xmark.bin") { store.delete(article) }
                        .tint(.red)
                }
            }
        }
    }

    private var peopleStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.people) { person in
                    let following = store.following.contains(person.id)
                    Button { store.toggleFollow(person) } label: {
                        HStack(spacing: 8) {
                            Text(person.avatar)
                                .font(.caption.weight(.black))
                                .frame(width: 28, height: 28)
                                .foregroundStyle(.white)
                                .background(AppTheme.accentGradient, in: Circle())
                            Text(person.name)
                                .font(.subheadline.weight(.bold))
                            Image(systemName: following ? "checkmark.circle.fill" : "plus.circle")
                                .foregroundStyle(following ? .pink : .secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ArticleSection<Content: View>: View {
    let title: String
    let emptyText: String
    let articles: [Article]
    @ViewBuilder let content: (Article) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.largeTitle.weight(.black))
                .tracking(-0.7)

            if articles.isEmpty {
                Text(emptyText)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            } else {
                ForEach(articles) { article in
                    content(article)
                }
            }
        }
    }
}

struct PrimaryPill: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.black))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(.white)
                .background(AppTheme.accentGradient, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryPill: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .clipShape(Capsule())
    }
}

struct IconPill: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.black))
                .frame(width: 42, height: 42)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
    }
}
