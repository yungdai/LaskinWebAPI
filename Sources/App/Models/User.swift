import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class User: Codable {
    
    var id: UUID?
    var firstName: String
    var lastName: String
    var userType: UserType.RawValue
    var userName: String
    var privileges: AppPrivileges.RawValue
    var password: String

    
    init(firstName: String = "", lastName: String = "", userType: UserType = .none, privileges: AppPrivileges = .none, password: String, userName: String) {
        
        self.firstName = firstName
        self.lastName = lastName
        self.userType = userType.rawValue
        self.privileges = privileges.rawValue
        self.password = password
        self.userName = userName
    }
    
    func getFullName() -> String {
        
        let fullName = "\(firstName) \(lastName)"
        return fullName
    }
    
    static func getUserTypes() -> [String] {
    
        let userTypes = ["none", "administrator", "coach", "contact person", "judge", "mooter", "researcher"]
        return userTypes
    }
    
    static func getPrivileges() -> [String] {
        
        let privileges = ["none", "admin", "user"]
        return privileges
    }
    
    // Add a public model for user authentication
    final class Public: Codable {
        
        var id: UUID?
        var userName: String
        var firstName: String
        var lastName: String
        
        init(id: UUID?, userName: String, firstName: String, lastName: String) {
            
            self.firstName = firstName
            self.lastName = lastName
            self.userName = userName
            self.id = id
        }
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        
        // create the User Table
        return Database.create(self, on: connection) { builder in
            
            // Add all the columns to the User tabkle using user properties
            try addProperties(to: builder)
            
            // add a unique index to username on the user.  This ensures that there are no duplicate usernames and it would result in an error.
            builder.unique(on: \.userName)
        }
    }
}

extension User: Parameter {}

// extend the PostgreSQLUUIDModel to the internet class so fluent can use it
extension User.Public: PostgreSQLUUIDModel {
    
    // this is to set the Public Model to have the same table name as your standard use so when we query it uses the right table
    static let entity = User.entity
    
}

// you want User.Public to work with content and parameter for web calls
extension User.Public: Content {}
extension User.Public: Parameter {}

extension User {
    
    var userDetails: Children<User, UserDetails> {
        return children(\.userID)
    }
    
    var matchMakingData: Children<User, MatchMakingData> {
        return children(\.userID)
    }
    
    /// Used to create a public version of the current object
    func convertToPublic() -> User.Public {
        return User.Public(id: id, userName: userName, firstName: firstName, lastName: lastName)
    }
}


extension Future where T: User {
    
    /// Alows to call ConvertToPublic() on Future<User>
    func convertToPublic() -> Future<User.Public> {
        
        return self.map(to: User.Public.self) { user in
            
            return user.convertToPublic()
        }
    }
}

// This is used for basic authentication
extension User: BasicAuthenticatable {

    // assign the user properties that will holder the userName and password.
    static let usernameKey: UsernameKey = \User.userName
    static let passwordKey: PasswordKey = \User.password
}

// Add this so Token Authenicatable knows what model to use for the Token
extension User: TokenAuthenticatable {
	
	// tell Vapor what a Token is
    typealias TokenType = Token
}

//Add following extensions for Web Authentication
extension User: PasswordAuthenticatable {}
extension User: SessionAuthenticatable {}

// MARK: Database migration to add an admin user

// Define AdminUser type
struct AdminUser: Migration {
	
	// this type users PostgreSQL as it's database
	typealias Database = PostgreSQLDatabase
	
	// required functiones prepared(on:) and revert(on:)
	static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
		
		// create a password hash and terminate with a fatalError if this fails
		let password = try? BCrypt.hash("password")
		
		guard let hashedPassword = password else {
			fatalError("Failed to create admin user")
		}
		
		// create a new user with the username "admin", you can change the password immediately for the user afterwards
        let user = User(firstName: "admin", lastName: "user", userType: .administrator, privileges: .admin, password: hashedPassword, userName: "admin")
		
		//  save the user and transform to the result to void
		return user.save(on: connection).transform(to: ())
	}
	
	//  impliment the required revert function and return a pre-completed Future<Void)
	static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
		
		return .done(on: connection)
	}	
}
