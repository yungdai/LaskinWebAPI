import Vapor
import FluentPostgreSQL

final class UserDetails: Codable {
    
    // Identifies
    var id: Int?
    var userID: User.ID
    
    // contact Info
    var emailAddress: String
    var mobilePhone: String
    var officePhone: String
    
    
    // accessiblity
    var requiresAccessibility: Bool
    var accessibilityNeeds: String
    
    // dietary
    var hasDietaryNeeds: Bool
    var dietaryNeeds: String
    
    // conflicting schools for judge
    var conflictingSchools: [String]
    
    init(userID: User.ID, emailAddress: String = "none", mobilePhone: String = "none", officePhone: String = "none", requiresAccessibility: Bool = false, accessibilityNeeds: String = "none", hasDietaryNeeds: Bool = false, dietaryNeeds: String = "none", conflictingSchools: [String] = []) {
        
        self.userID = userID
        self.emailAddress = emailAddress
        self.mobilePhone = mobilePhone
        self.officePhone = officePhone
        self.requiresAccessibility = requiresAccessibility
        self.accessibilityNeeds = accessibilityNeeds
        self.hasDietaryNeeds = hasDietaryNeeds
        self.dietaryNeeds = dietaryNeeds
        self.conflictingSchools = conflictingSchools
    }
}

extension UserDetails: PostgreSQLModel {}
extension UserDetails: Content {}
extension UserDetails: Parameter {}

extension UserDetails {
    
    // add a computered property to acronym to get the user object of the User's owner.  This returns fluent's generic Parent Type
    var user: Parent<UserDetails, User> {
        // Users Flurent's parent function to retreive the parent.  This take the keypath of the user reference on the acronym.
        return parent(\.userID)
    }
}


extension UserDetails: Migration{
    
    // add a function for foreign key constraints
    // impliment prepare(on
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        
        // create table for UserDetails in the database
        return Database.create(self, on: connection) { builder in
            
            // add all the fields to the database for UserDetails.
            try addProperties(to: builder)
            
            // add reference between the userID propery on UserDetails and the id properly on the User
            try builder.addReference(from: \.userID, to: \User.id)
        }
    }
}

