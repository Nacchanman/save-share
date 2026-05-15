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

    var symbolName: String {
        switch self {
        case .feed: return "sparkles"
        case .important: return "bookmark.fill"
        case .trash: return "trash.fill"
        }
    }
}
