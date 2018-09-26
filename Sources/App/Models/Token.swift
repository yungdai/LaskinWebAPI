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
extension Token: Migration {
	
	static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
		
		return Database.create(self, on: connection){ builder in
			
			try addProperties(to: builder)
			builder.reference(from: \.userID, to: \User.id)
		}
	}
}


extension Token {
    
    var user: Parent<Token, User> {
        return parent(\.userID)
    }
}

extension Token: Equatable {

	// allows the tokens to be searchable
	static func == (lhs: Token, rhs: Token) -> Bool {
		return (lhs.token == rhs.token) ? true : false
	}
}

// generate a random token with this token extension for Authentication
extension Token {
    static func generate(for user: User) throws -> Token {
		
		// generate 16 random bytes to act as the token
        let random = try CryptoRandom().generateData(count: 16)
		
		// create a token using the base64-encoded representation of the random byes and the user's ID
        return try Token(token: random.base64EncodedString(), userID: user.requireID())
    }
}

// Add for Authentication with a token
extension Token: Authentication.Token {
	
	// define the user ID key on Token
    static let userIDKey: UserIDKey = \Token.userID
	
	// tell vapor what type User is
    typealias  UserType = User
}

extension Token: BearerAuthenticatable {
	
	// tell vapor the keypath to the tokenKey is this case the token's string
    static let tokenKey: TokenKey = \Token.token
}


