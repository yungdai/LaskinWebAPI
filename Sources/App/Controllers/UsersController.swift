import Vapor
import FluentPostgreSQL
import Crypto

struct UsersController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let userRoutes = router.grouped("api", "users")
		
		// TODO: Remove the rest of the routes that don't require authentication, will have to go through each one and decide which ones required to be logged in for using a token
//        userRoutes.post(User.self, use: createHandler)
        userRoutes.get(use: getAllHandler)
        userRoutes.get(User.Public.parameter, use: getHandler)
//        userRoutes.put(User.parameter, use: updateHandler)
//        userRoutes.delete(User.parameter, use: deleteHandler)
        userRoutes.get("search", use: searchHandler)
        userRoutes.get("first", use: getFirstHandler)
        userRoutes.get("sort", use: sortHandler)
        userRoutes.get(User.parameter, "userDetails", use: getUserDetailsHandler)
        userRoutes.get(User.parameter, "matchMakingData", use: getMatchMakingDataHandler)
        
        // Create the middleware for authentication
		// instantiate a basical auth middleware that uses BCryptDigest to verify passsords.
        let basicAuthMiddleWear = User.basicAuthMiddleware(using: BCryptDigest())
		
		// create an instance of guard middleware that ensures that requests contain valid authorisation
		let guardAuthMiddleware = User.guardAuthMiddleware()
		
		// create a middleware group which uses uses basic and guardAuth Middleware.
		let protected = userRoutes.grouped(basicAuthMiddleWear, guardAuthMiddleware)
		
		// used to log in
		protected.post("login", use: loginHandler)
		
		// authentication required for the following routes
		protected.post(User.self, use: createHandler)
		protected.put(User.parameter, use: updateHandler)
		protected.delete(User.parameter, use: deleteHandler)
    }
    
    // CREATE
    func createHandler(_ request: Request, user: User) throws -> Future<User> {
        
        return try request.content.decode(User.self).flatMap(to: User.self) { user in

            // To add authentication create hasher
            // encrypt the user password with the hasher
            user.password = try request.make(BCryptDigest.self).hash(user.password)
            
            return user.save(on: request)
        }
    }
    
    // GET ALL
    // Changed for authentication
    func getAllHandler(_ request: Request) throws -> Future<[User.Public]> {
        return User.Public.query(on: request).all()
    }
    

    
    // GET by api/users/#id
    func getHandler(_ request: Request) throws -> Future<User.Public> {
        return try request.parameters.next(User.Public.self)
    }
    
    // UPDATE
    func updateHandler(_ request: Request) throws -> Future<User> {
        
        // extract the users from the users from user ID at api/users/#id
        return try flatMap(to: User.self, request.parameters.next(User.self), request.content.decode(User.self)) { user, updatedUser in
            
            // update the found user with the updated model and then save
            user.firstName = updatedUser.firstName
            user.lastName = updatedUser.lastName
            user.userType = updatedUser.userType
            user.privileges = updatedUser.privileges
            
            return user.save(on: request)
        }
    }
    
    // DELETE
    func deleteHandler(_ request: Request) throws -> Future<HTTPStatus> {
        
        // extract user form address param
        return try request.parameters.next(User.self).flatMap(to: HTTPStatus.self) { user in
            
            // delete the user using the .delete(on:) fuction and transform the response to a 204 No Content answer since it's successfully deleted and no longer there.
            return user.delete(on: request).transform(to: HTTPStatus.noContent)
        }
    }
    
    // SEARCH
    func searchHandler(_ request: Request) throws -> Future<[User]> {
        
        // retrieve the search term from the URL query string.  You can do this with any Codable object by calling request.query.decode(_:).  If there is a failure it will throw a 400 Bad Request Error
        guard let searchTerm = request.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        // used the group(.or) the group query different properties in User
		
		do {
			
		}
        return User.query(on: request).group(.or) { or in
            
            or.filter(\.firstName == searchTerm)
            or.filter(\.lastName == searchTerm)
            or.filter(\.userType == searchTerm)
            or.filter(\.privileges == searchTerm)
            or.filter(\.userName == searchTerm)
        }.all()
    }
    
    // GET FIRST USER (probably won't be used much)
    func getFirstHandler(_ request: Request) throws -> Future<User> {
        
        return User.query(on: request).first().map(to: User.self) { user in
         
            // make sure the user is object is not nil
            guard let user = user else {
                throw Abort(.notFound)
            }
            
            // return the found user
            return user
        }
    }
    
    // SORT RESULTS
    // see all users sorted ascending by last name
    func sortHandler(_ request: Request) throws -> Future<[User]> {
        
        return User.query(on: request).sort(\.lastName, .ascending).all()
    }
 
    // GET UserDetails for User
    func getUserDetailsHandler(_ request: Request) throws -> Future<[UserDetails]> {
        //  Fetch the user specified in the request's paramaters and unwarp the returned future.
        return try request.parameters.next(User.self)
            .flatMap(to: [UserDetails].self) { user in
                try user.userDetails.query(on: request).all()
        }
    }
    
    // GET Match Making Data for User
    func getMatchMakingDataHandler(_ request: Request) throws -> Future<[MatchMakingData]> {
        //  Feth the user specified in the request's paramaters and unwarp the returned future.
        return try request.parameters.next(User.self)
            .flatMap(to: [MatchMakingData].self) { user in
                try user.matchMakingData.query(on: request).all()
        }
    }
    
    // LOGIN Authentication
    func loginHandler(_ request: Request) throws -> Future<Token> {
		
		// get the authenticated user from teh request, then protect the route with the HTTP basic authenitication middleware.  This will save the user's identity in the requests's authentication cache, allowing you to retireve the user object later
		let user = try request.requireAuthenticated(User.self)
		
		// create a tokent for the user
		let token = try Token.generate(for: user)
		
		// save and return the token
		return token.save(on: request)
	}
}

