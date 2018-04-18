import Vapor
import FluentPostgreSQL

final class MatchMakingInfo: Codable {
    
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
    
    init(userID: User.ID, school: String = "N/A", city: String = "N/A", province: String = "N/A", timeZone: Int = 0, needsInterpreter: Bool = false, interpreterType: String = "None", order: Int = 9) {
        
        self.userID = userID
        self.school = school
        self.city = city
        self.province = province
        self.timeZone = timeZone
        self.needsInterpreter = needsInterpreter
        self.interpreterType = interpreterType
        self.order = order
    }
}

extension MatchMakingInfo: PostgreSQLModel {}
extension MatchMakingInfo: Content {}
extension MatchMakingInfo: Parameter {}


extension MatchMakingInfo {
    
    var user: Parent<MatchMakingInfo, User> {
        return parent(\.userID)
    }
}
