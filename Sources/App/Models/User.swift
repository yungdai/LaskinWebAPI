import Foundation
import Vapor
import FluentPostgreSQL

final class User: Codable {
    
    var id: UUID?
    var firstName: String
    var lastName: String
    var userType: String
    var priviledges: String
    var fullName: String
    
    init(firstName: String = "", lastName: String = "", userType: String = "none", priviledges: String = "none") {
        
        self.firstName = firstName
        self.lastName = lastName
        self.userType = userType
        self.priviledges = priviledges
        self.fullName = "\(firstName) \(lastName)"
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
