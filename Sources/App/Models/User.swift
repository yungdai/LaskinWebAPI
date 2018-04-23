import Foundation
import Vapor
import FluentPostgreSQL

final class User: Codable {
    
    var id: UUID?
    var firstName: String
    var lastName: String
    var userType: String
    var privileges: String
    
    init(firstName: String = "", lastName: String = "", userType: String = "none", privileges: String = "none") {
        
        self.firstName = firstName
        self.lastName = lastName
        self.userType = userType
        self.privileges = privileges
    }
    
    func getFullName() -> String {
        
        let fullName = "\(firstName) \(lastName)"
        return fullName
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {}
extension User: Parameter {}

extension User {
    
    var userDetails: Children<User, UserDetails> {
        return children(\.userID)
    }
    
    var matchMakingData: Children<User, MatchMakingData> {
        return children(\.userID)
    }
}
