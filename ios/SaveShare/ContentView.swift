import SwiftUI

private enum Folder: String, Codable {
    case shared
    case important
    case trash
}

private struct Article: Identifiable, Codable, Equatable {
    let id: UUID
    var ownerName: String
    var url: String
    var title: String
    var folder: Folder
    var memo: String
    var imageNames: [String]
    var likes: Int
    var isMine: Bool

    var host: String {
        URL(string: url)?.host?.replacingOccurrences(of: "www.", with: "") ?? url
    }
}

private enum TabItem: String, CaseIterable {
    case feed = "フィード"
    case important = "重要"
    case trash = "ゴミ箱"
}

struct ContentView: View {
    @State private var selectedTab: TabItem = .feed
    @State private var articleURL = ""
    @State private var articleTitle = ""
    @State private var articles: [Article] = Self.initialArticles

    private var feedArticles: [Article] {
        articles
            .filter { $0.folder == .shared }
            .sorted { $0.likes == $1.likes ? $0.title < $1.title : $0.likes > $1.likes }
    }

    private var importantArticles: [Article] {
        articles.filter { $0.folder == .important && $0.isMine }
    }

    private var trashArticles: [Article] {
        articles.filter { $0.folder == .trash && $0.isMine }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.99, green: 0.96, blue: 0.91), Color(red: 0.92, green: 0.89, blue: 0.83)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        hero
                        tabs
                        content
                    }
                    .padding(18)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save & Share")
                .font(.caption.weight(.black))
                .foregroundStyle(.brown)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.orange.opacity(0.12), in: Capsule())

            Text("読みたいを、きれいに残す。")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .tracking(-1.4)

            Text("保存、共有、整理。必要な操作だけ。")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                TextField("URL", text: $articleURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))

                TextField("タイトル（任意）", text: $articleTitle)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))

                Button(action: addArticle) {
                    Text("重要に追加")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.black)
                .disabled(articleURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.35)))
        .shadow(color: .black.opacity(0.09), radius: 24, y: 14)
    }

    private var tabs: some View {
        HStack(spacing: 8) {
            tabButton(.feed, count: feedArticles.count)
            tabButton(.important, count: importantArticles.count)
            tabButton(.trash, count: trashArticles.count)
        }
        .padding(7)
        .background(.white.opacity(0.55), in: Capsule())
    }

    private func tabButton(_ tab: TabItem, count: Int) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 6) {
                Text(tab.rawValue)
                Text("\(count)")
                    .font(.caption.weight(.black))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(selectedTab == tab ? .white : .orange.opacity(0.12), in: Capsule())
                    .foregroundStyle(selectedTab == tab ? .black : .brown)
            }
            .font(.subheadline.weight(.black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .foregroundStyle(selectedTab == tab ? .white : .secondary)
            .background(selectedTab == tab ? Color.black : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .feed:
            articleSection(title: "フィード", subtitle: "みんなのおすすめ", articles: feedArticles, empty: "まだ何もありません") { article in
                ArticleCard(article: article, badge: article.isMine ? "自分" : article.ownerName) {
                    Button("保存") { saveFromFeed(article) }
                        .buttonStyle(.borderedProminent)
                        .tint(.black)
                    Button("♥ \(article.likes)") { like(article) }
                        .buttonStyle(.bordered)
                }
            }
        case .important:
            articleSection(title: "重要", subtitle: "左で共有、右でゴミ箱", articles: importantArticles, empty: "重要は空です") { article in
                ArticleCard(article: article, badge: "重要") {
                    Button("共有") { move(article, to: .shared) }
                        .buttonStyle(.borderedProminent)
                        .tint(.black)
                    Button("ゴミ箱") { move(article, to: .trash) }
                        .buttonStyle(.bordered)
                }
                .swipeActions(edge: .leading) {
                    Button("共有") { move(article, to: .shared) }.tint(.black)
                }
                .swipeActions(edge: .trailing) {
                    Button("ゴミ箱") { move(article, to: .trash) }.tint(.orange)
                }
            }
        case .trash:
            articleSection(title: "ゴミ箱", subtitle: "戻すか削除", articles: trashArticles, empty: "ゴミ箱は空です") { article in
                ArticleCard(article: article, badge: "ゴミ箱") {
                    Button("戻す") { move(article, to: .important) }
                        .buttonStyle(.borderedProminent)
                        .tint(.black)
                    Button("削除", role: .destructive) { delete(article) }
                        .buttonStyle(.bordered)
                }
                .swipeActions(edge: .trailing) {
                    Button("削除", role: .destructive) { delete(article) }
                }
            }
        }
    }

    private func articleSection<Content: View>(title: String, subtitle: String, articles: [Article], empty: String, @ViewBuilder card: (Article) -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                Text(title)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                Spacer()
                Text(subtitle)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            if articles.isEmpty {
                Text(empty)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 44)
                    .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 24))
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(articles) { article in
                        card(article)
                    }
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.54), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 18, y: 10)
    }

    private func addArticle() {
        let cleanURL = articleURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanURL.isEmpty else { return }
        let normalized = cleanURL.hasPrefix("http") ? cleanURL : "https://\(cleanURL)"
        let title = articleTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? inferredTitle(from: normalized) : articleTitle
        articles.insert(Article(id: UUID(), ownerName: "You", url: normalized, title: title, folder: .important, memo: "", imageNames: ["photo"], likes: 0, isMine: true), at: 0)
        articleURL = ""
        articleTitle = ""
        selectedTab = .important
    }

    private func move(_ article: Article, to folder: Folder) {
        guard let index = articles.firstIndex(of: article) else { return }
        articles[index].folder = folder
    }

    private func delete(_ article: Article) {
        articles.removeAll { $0.id == article.id }
    }

    private func saveFromFeed(_ article: Article) {
        guard !articles.contains(where: { $0.isMine && $0.url == article.url && $0.folder != .trash }) else { return }
        var copy = article
        copy.id = UUID()
        copy.ownerName = "You"
        copy.folder = .important
        copy.memo = ""
        copy.likes = 0
        copy.isMine = true
        articles.insert(copy, at: 0)
        selectedTab = .important
    }

    private func like(_ article: Article) {
        guard let index = articles.firstIndex(of: article) else { return }
        articles[index].likes += 1
    }

    private func inferredTitle(from url: String) -> String {
        guard let parsed = URL(string: url) else { return url }
        let path = parsed.path.replacingOccurrences(of: "/", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return path.isEmpty ? (parsed.host ?? url) : path
    }

    private static let initialArticles: [Article] = [
        Article(id: UUID(), ownerName: "Mika", url: "https://example.com/design-systems", title: "小さなチームで育てるデザインシステム", folder: .shared, memo: "", imageNames: ["paintpalette", "square.grid.2x2"], likes: 18, isMine: false),
        Article(id: UUID(), ownerName: "Ren", url: "https://example.com/ai-agents-productivity", title: "AIエージェントで変わる個人の生産性", folder: .shared, memo: "", imageNames: ["sparkles", "cpu"], likes: 31, isMine: false),
        Article(id: UUID(), ownerName: "Sora", url: "https://example.com/public-libraries", title: "公共図書館とデジタルアーカイブの未来", folder: .shared, memo: "", imageNames: ["books.vertical", "archivebox"], likes: 12, isMine: false),
        Article(id: UUID(), ownerName: "You", url: "https://developer.mozilla.org/ja/docs/Web/API/Pointer_events", title: "Pointer events - Web API | MDN", folder: .important, memo: "", imageNames: ["hand.tap", "iphone"], likes: 7, isMine: true)
    ]
}

private struct ArticleCard<Actions: View>: View {
    let article: Article
    let badge: String
    @ViewBuilder let actions: Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(article.imageNames.prefix(3), id: \.self) { name in
                    ZStack {
                        LinearGradient(colors: [.orange.opacity(0.24), .indigo.opacity(0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: name)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.black.opacity(0.72))
                    }
                    .frame(height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }

            HStack {
                Text(badge)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.brown)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.12), in: Capsule())
                Spacer()
                Text(article.host)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            Link(article.title, destination: URL(string: article.url) ?? URL(string: "https://example.com")!)
                .font(.title3.weight(.black))
                .foregroundStyle(.primary)
                .lineLimit(2)

            HStack(spacing: 10) {
                actions
            }
        }
        .padding(12)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.45)))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

#Preview {
    ContentView()
}
