import SwiftUI

private enum LocalPage: String, CaseIterable, Identifiable {
    case feed
    case important
    case trash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feed: return "フィード"
        case .important: return "重要"
        case .trash: return "ゴミ箱"
        }
    }
}

struct ContentView: View {
    @State private var selectedPage: LocalPage = .feed
    @State private var urlText = ""
    @State private var titleText = ""
    @State private var articles: [Article] = ContentView.defaultArticles
    @State private var likedArticleIds: Set<String> = []

    private var myArticles: [Article] { articles.filter { $0.ownerId == "me" } }
    private var importantArticles: [Article] { myArticles.filter { $0.folder == .important } }
    private var trashArticles: [Article] { myArticles.filter { $0.folder == .tired } }
    private var feedArticles: [Article] {
        articles
            .filter { $0.folder == .shared }
            .sorted { $0.likes == $1.likes ? $0.createdAt > $1.createdAt : $0.likes > $1.likes }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    pagePicker
                    pageContent
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Save & Share")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save & Share")
                .font(.caption.weight(.black))
                .foregroundStyle(AppTheme.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(AppTheme.blue.opacity(0.12), in: Capsule())

            Text("読みたいを、きれいに残す。")
                .font(.largeTitle.weight(.black))
                .tracking(-1.2)

            Text("保存、共有、整理。必要な操作だけ。")
                .foregroundStyle(.secondary)
                .lineSpacing(4)

            VStack(spacing: 12) {
                TextField("URL", text: $urlText)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .submitLabel(.done)
                    .fieldStyle()

                TextField("タイトル（任意）", text: $titleText)
                    .fieldStyle()

                Button {
                    addArticle()
                } label: {
                    Label("重要に追加", systemImage: "tray.and.arrow.down.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .cardStyle()
    }

    private var pagePicker: some View {
        Picker("ページ", selection: $selectedPage) {
            ForEach(LocalPage.allCases) { page in
                Text("\(page.title) \(count(for: page))").tag(page)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch selectedPage {
        case .feed:
            FolderSection(
                title: "フィード",
                description: "みんなのおすすめ",
                emptyText: "まだ何もありません",
                articles: feedArticles
            ) { article in
                ArticleCardView(
                    article: article,
                    ownerLabel: article.ownerId == "me" ? "自分" : article.ownerName,
                    isLiked: likedArticleIds.contains(article.id),
                    likes: article.likes
                ) {
                    Button("保存") {
                        saveFromFeed(article)
                    }
                    Button {
                        toggleLike(article)
                    } label: {
                        Label("\(article.likes)", systemImage: likedArticleIds.contains(article.id) ? "heart.fill" : "heart")
                    }
                    .buttonStyle(.bordered)
                    .tint(.pink)
                }
            }

        case .important:
            FolderSection(
                title: "重要",
                description: "左で共有、右でゴミ箱",
                emptyText: "重要は空です",
                articles: importantArticles
            ) { article in
                ArticleCardView(
                    article: article,
                    ownerLabel: "重要",
                    showMemo: true,
                    leftHint: "共有",
                    rightHint: "ゴミ箱",
                    onMemoChanged: { updateMemo(for: article, memo: $0) },
                    onSwipeLeft: { move(article, to: ArticleFolder.shared) },
                    onSwipeRight: { move(article, to: ArticleFolder.tired) }
                ) {
                    Button("共有") { move(article, to: ArticleFolder.shared) }
                    Button("ゴミ箱") { move(article, to: ArticleFolder.tired) }
                        .buttonStyle(.bordered)
                }
            }

        case .trash:
            FolderSection(
                title: "ゴミ箱",
                description: "戻すか削除",
                emptyText: "ゴミ箱は空です",
                articles: trashArticles
            ) { article in
                ArticleCardView(
                    article: article,
                    ownerLabel: "ゴミ箱",
                    showMemo: true,
                    rightHint: "削除",
                    onMemoChanged: { updateMemo(for: article, memo: $0) },
                    onSwipeRight: { delete(article) }
                ) {
                    Button("戻す") { move(article, to: ArticleFolder.important) }
                    Button("削除", role: .destructive) { delete(article) }
                        .buttonStyle(.bordered)
                }
            }
        }
    }

    private func count(for page: LocalPage) -> Int {
        switch page {
        case .feed: return feedArticles.count
        case .important: return importantArticles.count
        case .trash: return trashArticles.count
        }
    }

    private func addArticle() {
        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else { return }
        let normalizedURL = trimmedURL.hasPrefix("http") ? trimmedURL : "https://\(trimmedURL)"
        let title = titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? inferTitle(from: normalizedURL) : titleText
        let article = Article(
            id: "mine-\(UUID().uuidString)",
            ownerId: "me",
            ownerName: "You",
            url: normalizedURL,
            title: title,
            folder: ArticleFolder.important,
            memo: "",
            likes: 0,
            createdAt: Date()
        )
        articles.insert(article, at: 0)
        urlText = ""
        titleText = ""
        selectedPage = .important
    }

    private func move(_ article: Article, to folder: ArticleFolder) {
        guard let index = articles.firstIndex(where: { $0.id == article.id }) else { return }
        articles[index].folder = folder
    }

    private func updateMemo(for article: Article, memo: String) {
        guard let index = articles.firstIndex(where: { $0.id == article.id }) else { return }
        articles[index].memo = memo
    }

    private func delete(_ article: Article) {
        articles.removeAll { $0.id == article.id }
        likedArticleIds.remove(article.id)
    }

    private func saveFromFeed(_ article: Article) {
        let alreadySaved = articles.contains { $0.ownerId == "me" && $0.url == article.url && $0.folder != .tired }
        guard !alreadySaved else { return }
        var copy = article
        copy.id = "mine-\(UUID().uuidString)"
        copy.ownerId = "me"
        copy.ownerName = "You"
        copy.folder = ArticleFolder.important
        copy.memo = ""
        copy.likes = 0
        copy.createdAt = Date()
        articles.insert(copy, at: 0)
        selectedPage = .important
    }

    private func toggleLike(_ article: Article) {
        guard let index = articles.firstIndex(where: { $0.id == article.id }) else { return }
        if likedArticleIds.contains(article.id) {
            likedArticleIds.remove(article.id)
            articles[index].likes = max(0, articles[index].likes - 1)
        } else {
            likedArticleIds.insert(article.id)
            articles[index].likes += 1
        }
    }

    private func inferTitle(from url: String) -> String {
        guard let components = URLComponents(string: url), let host = components.host else { return url }
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return path.isEmpty ? host : "\(host) / \(path.replacingOccurrences(of: "/", with: " / "))"
    }

    private static let defaultArticles: [Article] = [
        Article(id: "mine-1", ownerId: "me", ownerName: "You", url: "https://developer.apple.com/design/human-interface-guidelines", title: "Human Interface Guidelines", folder: ArticleFolder.important, memo: "iOS版のUI確認に使う", likes: 7, createdAt: Date().addingTimeInterval(-120)),
        Article(id: "friend-1", ownerId: "mika", ownerName: "Mika", url: "https://example.com/design-systems", title: "小さなチームで育てるデザインシステム", folder: ArticleFolder.shared, memo: "", likes: 18, createdAt: Date().addingTimeInterval(-900)),
        Article(id: "friend-2", ownerId: "ren", ownerName: "Ren", url: "https://example.com/ai-agents-productivity", title: "AIエージェントで変わる個人の生産性", folder: ArticleFolder.shared, memo: "", likes: 31, createdAt: Date().addingTimeInterval(-1800)),
        Article(id: "friend-3", ownerId: "sora", ownerName: "Sora", url: "https://example.com/public-libraries", title: "公共図書館とデジタルアーカイブの未来", folder: ArticleFolder.shared, memo: "", likes: 12, createdAt: Date().addingTimeInterval(-3600))
    ]
}

struct FolderSection<Content: View>: View {
    let title: String
    let description: String
    let emptyText: String
    let articles: [Article]
    @ViewBuilder let content: (Article) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: title, description: description)

            if articles.isEmpty {
                Text(emptyText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(36)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
            } else {
                ForEach(articles) { article in
                    content(article)
                }
            }
        }
        .cardStyle()
    }
}

struct SectionHeader: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.title2.weight(.black))
            Text(description).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
