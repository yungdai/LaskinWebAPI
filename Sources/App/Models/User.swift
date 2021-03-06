import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

public enum UserType: String, Codable {
    
    case none = "none"
    case administrator = "administrator"
    case coach = "coach"
    case contactPerson = "contact person"
    case judge = "judge"
    case mooter = "mooter"
    case researcher = "researcher"
}

final class User: Codable {
    
    var id: UUID?
    var firstName: String
    var lastName: String
    var userType: String
    var userName: String
    var privileges: String
    var password: String

    
    init(firstName: String = "", lastName: String = "", userType: String = "none", privileges: String = "none", password: String, userName: String) {
        
        self.firstName = firstName
        self.lastName = lastName
        self.userType = userType
        self.privileges = privileges
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
        
        init(userName: String, firstName: String, lastName: String) {
            
            self.firstName = firstName
            self.lastName = lastName
            self.userName = userName
        }
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {}
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
}

// This is used for basic authentication
extension User: BasicAuthenticatable {

    // assign the user properties that will holder the userName and password.
    static let usernameKey: UsernameKey = \User.userName
    static let passwordKey: PasswordKey = \User.password
}

// Add this so Token Authenicatable knows what model to use for the Token
extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

//Add following extensions for Web Authentication
extension User: PasswordAuthenticatable {}
extension User: SessionAuthenticatable {}
