import Vapor
import Fluent


struct UserDetailsController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let userDetailsRoute = router.grouped("api","userDetails")

        userDetailsRoute.get(use: getAllHandler)
        userDetailsRoute.get(UserDetails.parameter, use: getHandler)
        userDetailsRoute.get("search", use: searchHandler)
        
        // Added to allow only authenticated users for these routes
        // use tokenAuthMiddleWare() to make sure that you're authenticated to use these routes
		let tokenAuthMiddleWare = User.tokenAuthMiddleware()
		let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = userDetailsRoute.grouped(tokenAuthMiddleWare, guardAuthMiddleware)
        
        // moving the routes for create, update, and delete down to this group
        // ensure that ONLY authenticated users can be allowed to use the routes
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.delete(UserDetails.parameter, use: deleteHandler)
        tokenAuthGroup.put(UserDetails.parameter, use: updateHandler)
    }

    // CREATE, but now used for the tokenAuthGroup
    func createHandler(_ request: Request) throws -> Future<UserDetails> {
        
        return try request.content.decode(UserDetailsCreateData.self).flatMap(to: UserDetails.self) { userDetailsData in
            
            // check to make sure the user is authenticated
            let user = try request.requireAuthenticated(User.self)
            
            // create a user user details the authenticated user.
            let userDetails = UserDetails(userID: try user.requireID(), emailAddress: userDetailsData.emailAddress, mobilePhone: userDetailsData.mobilePhone, officePhone: userDetailsData.officePhone, requiresAccessibility: userDetailsData.requiresAccessibility, accessibilityNeeds: userDetailsData.accessibilityNeeds, hasDietaryNeeds: userDetailsData.hasDietaryNeeds, dietaryNeeds: userDetailsData.dietaryNeeds, conflictingSchools: UserDetails.returnArrayOfConflctingSchools(from: userDetailsData.conflictingSchools))
            
            return userDetails.save(on: request)
        }
    }
    
    // GET ALL
    func getAllHandler(_ request: Request) throws -> Future<[UserDetails]> {
        return UserDetails.query(on: request).all()
    }

    // GET by api/users/#id
    func getHandler(_ request: Request) throws -> Future<UserDetails> {
        return try request.parameters.next(UserDetails.self)
    }
    
    // UPDATE
    func updateHandler(_ request: Request) throws -> Future<UserDetails> {
        
        // extract the users from the users from user ID at api/user/#user/userDetails/#id
        return try flatMap(to: UserDetails.self, request.parameters.next(UserDetails.self), request.content.decode(UserDetailsCreateData.self)) { userDetails, userDetailsCreateData in


            // update the found user with the updated model and then save
            userDetails.emailAddress = userDetailsCreateData.emailAddress
            userDetails.mobilePhone = userDetailsCreateData.mobilePhone
            userDetails.officePhone = userDetailsCreateData.officePhone
            userDetails.requiresAccessibility = userDetailsCreateData.requiresAccessibility
            userDetails.accessibilityNeeds = userDetailsCreateData.accessibilityNeeds
            userDetails.hasDietaryNeeds = userDetailsCreateData.hasDietaryNeeds
            userDetails.dietaryNeeds = userDetailsCreateData.dietaryNeeds
            userDetails.conflictingSchools = UserDetails.returnArrayOfConflctingSchools(from: userDetailsCreateData.conflictingSchools)
            
            // use this type of request if you want ONLY the user who is authenticated to be able to create this data
            // userDetails.userID = try request.requireAuthenticated(User.self).requireID()
            
            return userDetails.save(on: request)
        }
    }
    
    // DELETE
    func deleteHandler(_ request: Request) throws -> Future<HTTPStatus> {
        
        // extract user form address param
        return try request.parameters.next(UserDetails.self).flatMap(to: HTTPStatus.self) { user in

            return user.delete(on: request).transform(to: HTTPStatus.noContent)
        }
    }
    
    // SEARCH
    func searchHandler(_ request: Request) throws -> Future<[UserDetails]> {
        
        // retrieve the search term from the URL query string.  You can do this with any Codable object by calling request.query.decode(_:).  If there is a failure it will throw a 400 Bad Request Error
        guard let searchTerm = request.query[String.self, at: "term"] else {
            throw Abort(.badRequest, reason: "Missing search term in request")
        }

        return UserDetails.query(on: request).group(.or) { or in
            
            or.filter(\.emailAddress == searchTerm)
            or.filter(\.mobilePhone == searchTerm)
            or.filter(\.officePhone == searchTerm)
            or.filter(\.accessibilityNeeds == searchTerm)
            or.filter(\.dietaryNeeds == searchTerm)
            }.all()
    }
}

struct UserDetailsCreateData: Content {
    
    let emailAddress: String
    let mobilePhone: String
    let officePhone: String
    let requiresAccessibility: Bool
    let accessibilityNeeds: String
    let hasDietaryNeeds: Bool
    let dietaryNeeds: String
    let conflictingSchools: String
}
