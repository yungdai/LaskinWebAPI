import Vapor
import FluentPostgreSQL

final class MatchMakingData: Codable {
    
    // identifier
    var id: Int?
    var userID: User.ID
    
    // school info
    var school: String
    var city: String
    var province: String
    var timeZone: Int
    
    // match making info
    var needsInterpreter: Bool
    var interpreterType: String
    var order: Int
    
    // Additional Notes for expansion:
    var additionalNotes: String
    
    init(userID: User.ID, school: String = "N/A", city: String = "N/A", province: String = "N/A", timeZone: Int = 0, needsInterpreter: Bool = false, interpreterType: String = "None", order: Int = 9, additionalNotes: String) {
        
        self.userID = userID
        self.school = school
        self.city = city
        self.province = province
        self.timeZone = timeZone
        self.needsInterpreter = needsInterpreter
        self.interpreterType = interpreterType
        self.order = order
        self.additionalNotes = additionalNotes
    }
}

extension MatchMakingData: PostgreSQLModel {}
extension MatchMakingData: Content {}
extension MatchMakingData: Parameter {}

extension MatchMakingData {
    
    var user: Parent<MatchMakingData, User> {
        return parent(\.userID)
    }
}

extension MatchMakingData: Migration {
    
    // add a function for foreign key constraints
    // impliment prepare(on
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        
        // create table for UserDetails in the database
        return Database.create(self, on: connection) { builder in
			
            // add all the fields to the database for MatchMakingData.
            try addProperties(to: builder)
            
            // add reference between the userID propery on MatchMakingData and the id properly on the User
			
			builder.reference(from: \.userID, to: \User.id)
        }
    }
}

