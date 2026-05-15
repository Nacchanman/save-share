import Combine
import Foundation

@MainActor
final class SaveShareStore: ObservableObject {
    @Published var following: [String]
    @Published var articles: [Article]
    @Published var likedArticleIds: [String]

    let people: [Person] = [
        Person(id: "mika", name: "Mika", avatar: "み", bio: "UXと働き方の記事が好き"),
        Person(id: "ren", name: "Ren", avatar: "れ", bio: "AI・開発・プロダクトを収集"),
        Person(id: "sora", name: "Sora", avatar: "そ", bio: "社会とカルチャーを読む")
    ]

    private let storageKey = "save-share-ios-state"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(SaveShareState.self, from: data) {
            following = decoded.following
            articles = decoded.articles
            likedArticleIds = decoded.likedArticleIds
        } else {
            following = ["mika", "ren"]
            articles = Self.defaultArticles
            likedArticleIds = []
        }
    }

    var importantArticles: [Article] {
        mine.filter { $0.folder == .important }
    }

    var tiredArticles: [Article] {
        mine.filter { $0.folder == .tired }
    }

    var sharedMineCount: Int {
        mine.filter { $0.folder == .shared }.count
    }

    var feedArticles: [Article] {
        articles
            .filter { $0.folder == .shared }
            .filter { $0.ownerId == "me" || following.contains($0.ownerId) }
            .sorted { first, second in
                first.likes == second.likes ? first.createdAt > second.createdAt : first.likes > second.likes
            }
    }

    func count(for page: AppPage) -> Int {
        switch page {
        case .privatePage: return importantArticles.count
        case .feed: return feedArticles.count
        case .trash: return tiredArticles.count
        case .friends: return following.count
        }
    }

    func addArticle(url rawURL: String, title rawTitle: String) {
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let normalizedURL = trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)"
        let article = Article(
            id: "mine-\(UUID().uuidString)",
            ownerId: "me",
            ownerName: "You",
            url: normalizedURL,
            title: rawTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Self.inferTitle(from: normalizedURL) : rawTitle,
            folder: .important,
            memo: "",
            likes: 0,
            createdAt: Date()
        )
        articles.insert(article, at: 0)
        persist()
    }

    func updateMemo(for article: Article, memo: String) {
        mutate(article.id) { $0.memo = memo }
    }

    func move(_ article: Article, to folder: ArticleFolder) {
        mutate(article.id) { $0.folder = folder }
    }

    func delete(_ article: Article) {
        articles.removeAll { $0.id == article.id }
        likedArticleIds.removeAll { $0 == article.id }
        persist()
    }

    func saveFromFeed(_ article: Article) {
        let alreadySaved = articles.contains { $0.ownerId == "me" && $0.url == article.url && $0.folder != .tired }
        guard !alreadySaved else { return }
        var copy = article
        copy.id = "mine-\(UUID().uuidString)"
        copy.ownerId = "me"
        copy.ownerName = "You"
        copy.folder = .important
        copy.memo = ""
        copy.likes = 0
        copy.createdAt = Date()
        articles.insert(copy, at: 0)
        persist()
    }

    func toggleLike(_ article: Article) {
        let liked = likedArticleIds.contains(article.id)
        likedArticleIds = liked ? likedArticleIds.filter { $0 != article.id } : likedArticleIds + [article.id]
        mutate(article.id) { $0.likes = max(0, $0.likes + (liked ? -1 : 1)) }
    }

    func toggleFollow(_ person: Person) {
        following = following.contains(person.id) ? following.filter { $0 != person.id } : following + [person.id]
        persist()
    }

    private var mine: [Article] {
        articles.filter { $0.ownerId == "me" }
    }

    private func mutate(_ id: String, change: (inout Article) -> Void) {
        guard let index = articles.firstIndex(where: { $0.id == id }) else { return }
        change(&articles[index])
        persist()
    }

    private func persist() {
        let state = SaveShareState(following: following, articles: articles, likedArticleIds: likedArticleIds)
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private static func inferTitle(from url: String) -> String {
        guard let components = URLComponents(string: url), let host = components.host else { return url }
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return path.isEmpty ? host : "\(host) / \(path.replacingOccurrences(of: "/", with: " / "))"
    }

    private static let defaultArticles: [Article] = [
        Article(id: "mine-1", ownerId: "me", ownerName: "You", url: "https://developer.apple.com/design/human-interface-guidelines", title: "Human Interface Guidelines", folder: .important, memo: "iOS版のUI確認に使う", likes: 7, createdAt: Date().addingTimeInterval(-120)),
        Article(id: "friend-1", ownerId: "mika", ownerName: "Mika", url: "https://example.com/design-systems", title: "小さなチームで育てるデザインシステム", folder: .shared, memo: "あとでコンポーネント棚卸しの参考にする", likes: 18, createdAt: Date().addingTimeInterval(-900)),
        Article(id: "friend-2", ownerId: "ren", ownerName: "Ren", url: "https://example.com/ai-agents-productivity", title: "AIエージェントで変わる個人の生産性", folder: .shared, memo: "週末に読む", likes: 31, createdAt: Date().addingTimeInterval(-1800)),
        Article(id: "friend-3", ownerId: "sora", ownerName: "Sora", url: "https://example.com/public-libraries", title: "公共図書館とデジタルアーカイブの未来", folder: .shared, memo: "共有したい", likes: 12, createdAt: Date().addingTimeInterval(-3600))
    ]
}
