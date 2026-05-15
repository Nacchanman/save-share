import Foundation

struct Person: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let avatar: String
    let bio: String
}

enum ArticleFolder: String, Codable, CaseIterable {
    case shared
    case important
    case tired
}

struct Article: Identifiable, Codable, Equatable {
    var id: String
    var ownerId: String
    var ownerName: String
    var url: String
    var title: String
    var folder: ArticleFolder
    var memo: String
    var likes: Int
    var createdAt: Date

    var host: String {
        guard let host = URL(string: url)?.host else { return url }
        return host.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
    }
}

struct SaveShareState: Codable {
    var following: [String]
    var articles: [Article]
    var likedArticleIds: [String]
}

enum AppPage: String, CaseIterable, Identifiable {
    case privatePage
    case feed
    case trash
    case friends

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privatePage: return "プライベート"
        case .feed: return "フィード"
        case .trash: return "トラッシュ"
        case .friends: return "友達"
        }
    }
}
