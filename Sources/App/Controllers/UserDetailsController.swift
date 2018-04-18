import Vapor
import Fluent

struct UserDetailsController: RouteCollection {
    
    func boot(router: Router) throws {
        let userDetailsRoutes = router.grouped("api","userDetails")
        
        userDetailsRoutes.post(UserDetails.self, use: createHandler)
        userDetailsRoutes.get(use: getAllHandler)
        userDetailsRoutes.get(UserDetails.parameter, use: getHandler)
        userDetailsRoutes.put(UserDetails.parameter, use: updateHandler)
        userDetailsRoutes.delete(UserDetails.parameter, use: deleteHandler)
        userDetailsRoutes.get("search", use: searchHandler)
    }
    
    // CREATE
    func createHandler(_ request: Request, userDetails: UserDetails) throws -> Future<UserDetails> {
        return userDetails.save(on: request)
    }
    
    // GET ALL
    func getAllHandler(_ request: Request) throws -> Future<[UserDetails]> {
        return UserDetails.query(on: request).all()
    }
    
    // GET by api/users/#id
    func getHandler(_ request: Request) throws -> Future<UserDetails> {
        return try request.parameter(UserDetails.self)
    }
    
    // UPDATE
    func updateHandler(_ request: Request) throws -> Future<UserDetails> {
        
        // extract the users from the users from user ID at api/user/#user/userDetails/#id
        return try flatMap(to: UserDetails.self, request.parameter(UserDetails.self), request.content.decode(UserDetails.self)) { userDetails, updatedUserDetails in
            
            // update the found user with the updated model and then save
            userDetails.userID = updatedUserDetails.userID
            userDetails.emailAddress = updatedUserDetails.emailAddress
            userDetails.mobilePhone = updatedUserDetails.mobilePhone
            userDetails.officePhone = updatedUserDetails.officePhone
            userDetails.requiresAccessibility = updatedUserDetails.requiresAccessibility
            userDetails.accessibilityNeeds = updatedUserDetails.accessibilityNeeds
            userDetails.hasDietaryNeeds = updatedUserDetails.hasDietaryNeeds
            userDetails.dietaryNeeds = updatedUserDetails.dietaryNeeds
            userDetails.conflictingSchools = updatedUserDetails.conflictingSchools
            
            return userDetails.save(on: request)
        }
    }
    
    // DELETE
    func deleteHandler(_ request: Request) throws -> Future<HTTPStatus> {
        
        // extract user form address param
        return try request.parameter(UserDetails.self).flatMap(to: HTTPStatus.self) { user in

            return user.delete(on: request).transform(to: HTTPStatus.noContent)
        }
    }
    
    // SEARCH
    func searchHandler(_ request: Request) throws -> Future<[UserDetails]> {
        
        // retrieve the search term from the URL query string.  You can do this with any Codable object by calling request.query.decode(_:).  If there is a failure it will throw a 400 Bad Request Error
        guard let searchTerm = request.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        

        return try UserDetails.query(on: request).group(.or) { or in
            
            try or.filter(\.emailAddress == searchTerm)
            try or.filter(\.mobilePhone == searchTerm)
            try or.filter(\.officePhone == searchTerm)
            try or.filter(\.accessibilityNeeds == searchTerm)
            try or.filter(\.dietaryNeeds == searchTerm)
            }.all()
    }
}
