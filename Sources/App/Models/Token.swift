import Vapor
import Fluent
import FluentPostgreSQL
import Foundation
import Authentication

// For authentication
import Crypto

final class Token: Codable {
    
    var id: UUID?
    var token: String
    var userID: User.ID
    
    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}

extension Token: PostgreSQLUUIDModel {}
extension Token: Content {}
extension Token: Migration {}

extension Token {
    
    var user: Parent<Token, User> {
        return parent(\.userID)
    }
}

// generate a random token with this token extension for Authentication
extension Token {
    static func generate(for user: User) throws -> Token {
        let random = try CryptoRandom().generateData(count: 16)
        return try Token(token: random.base64EncodedString(), userID: user.requireID())
    }
}

// Add for Authentication with a token
extension Token: Authentication.Token {
    
    static let userIDKey: UserIDKey = \Token.userID
    typealias  UserType = User
}

// Add this to tell it the key for the token string
extension Token: BearerAuthenticatable {
    static let tokenKey: TokenKey = \Token.token
}


