import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: SaveShareStore
    @State private var selectedPage: AppPage = .privatePage
    @State private var urlText = ""
    @State private var titleText = ""

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

            Text("読みたい記事を保存し、スワイプで共有・整理する。")
                .font(.largeTitle.weight(.black))
                .tracking(-1.2)

            Text("URLをアップロードすると重要フォルダへ追加。左スワイプで共有、右スワイプで「もういい」へ。友達の共有記事はフィードで読めます。")
                .foregroundStyle(.secondary)
                .lineSpacing(4)

            VStack(spacing: 12) {
                TextField("https://example.com/article", text: $urlText)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .submitLabel(.done)
                    .fieldStyle()

                TextField("タイトル（任意）", text: $titleText)
                    .fieldStyle()

                Button {
                    store.addArticle(url: urlText, title: titleText)
                    urlText = ""
                    titleText = ""
                    selectedPage = .privatePage
                } label: {
                    Label("重要フォルダに追加", systemImage: "tray.and.arrow.down.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .cardStyle()
    }

    private var pagePicker: some View {
        Picker("ページ", selection: $selectedPage) {
            ForEach(AppPage.allCases) { page in
                Text("\(page.title) \(store.count(for: page))").tag(page)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch selectedPage {
        case .privatePage:
            FolderSection(
                title: "重要フォルダ",
                description: "左スワイプで共有フォルダ、右スワイプで「もういいフォルダ」に移動します。",
                emptyText: "重要フォルダは空です。上のフォームからURLを追加してください。",
                articles: store.importantArticles
            ) { article in
                ArticleCardView(
                    article: article,
                    ownerLabel: "重要フォルダ",
                    showMemo: true,
                    leftHint: "共有へ",
                    rightHint: "もういいへ",
                    onMemoChanged: { store.updateMemo(for: article, memo: $0) },
                    onSwipeLeft: { store.move(article, to: .shared) },
                    onSwipeRight: { store.move(article, to: .tired) }
                ) {
                    Button("共有へ") { store.move(article, to: .shared) }
                    Button("もういい") { store.move(article, to: .tired) }
                        .buttonStyle(.bordered)
                }
            }

        case .feed:
            FolderSection(
                title: "共有フォルダ / フィード",
                description: "自分とフォロー中の友達の共有記事を、いいねが多い順に表示します。メモは非表示です。",
                emptyText: "フィードは空です。友達をフォローするか、記事を共有してください。",
                articles: store.feedArticles
            ) { article in
                ArticleCardView(
                    article: article,
                    ownerLabel: article.ownerId == "me" ? "あなたの共有" : "\(article.ownerName) の共有"
                ) {
                    Button("セーブ") {
                        store.saveFromFeed(article)
                        selectedPage = .privatePage
                    }
                    Button {
                        store.toggleLike(article)
                    } label: {
                        Label("\(article.likes)", systemImage: store.likedArticleIds.contains(article.id) ? "heart.fill" : "heart")
                    }
                    .buttonStyle(.bordered)
                    .tint(.pink)
                }

                if store.sharedMineCount > 0 {
                    Text("あなたの共有フォルダ: \(store.sharedMineCount)件が友達のフィードに表示されます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

        case .trash:
            FolderSection(
                title: "もういいフォルダ / トラッシュ",
                description: "右スワイプで削除フォルダへ送り、データベース（このデモでは端末内保存）から完全削除します。",
                emptyText: "トラッシュは空です。",
                articles: store.tiredArticles
            ) { article in
                ArticleCardView(
                    article: article,
                    ownerLabel: "もういいフォルダ",
                    showMemo: true,
                    rightHint: "完全削除",
                    onMemoChanged: { store.updateMemo(for: article, memo: $0) },
                    onSwipeRight: { store.delete(article) }
                ) {
                    Button("戻す") { store.move(article, to: .important) }
                    Button("完全削除", role: .destructive) { store.delete(article) }
                        .buttonStyle(.bordered)
                }
            }

        case .friends:
            friendsSection
        }
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "友達をフォロー", description: "フォローした友達の共有フォルダだけがフィードページに流れます。")

            ForEach(store.people) { person in
                HStack(spacing: 14) {
                    Text(person.avatar)
                        .font(.title3.weight(.black))
                        .frame(width: 52, height: 52)
                        .foregroundStyle(.white)
                        .background(LinearGradient(colors: [AppTheme.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(person.name).font(.headline)
                        Text(person.bio).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(store.following.contains(person.id) ? "フォロー中" : "フォロー") {
                        store.toggleFollow(person)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.following.contains(person.id) ? .pink : AppTheme.blue)
                }
                .cardStyle(padding: 16)
            }
        }
        .cardStyle()
    }
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
