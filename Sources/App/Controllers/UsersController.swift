import Vapor
import FluentPostgreSQL

struct UsersController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let userRoutes = router.grouped("api", "users")
        userRoutes.post(User.self, use: createHandler)
        userRoutes.get(use: getAllHandler)
        userRoutes.get(User.parameter, use: getHandler)
        userRoutes.put(User.parameter, use: updateHandler)
        userRoutes.delete(User.parameter, use: deleteHandler)
        userRoutes.get("search", use: searchHandler)
        userRoutes.get("first", use: getFirstHandler)
        userRoutes.get("sort", use: sortHandler)
        userRoutes.get(User.parameter, "userDetails", use: getUserDetailsHandler)
        userRoutes.get(User.parameter, "matchMakingData", use: getMatchMakingDataHandler)
    }
    
    // CREATE
    func createHandler(_ request: Request, user: User) throws -> Future<User> {
        return user.save(on: request)
    }
    
    // GET ALL
    func getAllHandler(_ request: Request) throws -> Future<[User]> {
        return User.query(on: request).all()
    }
    
    // GET by api/users/#id
    func getHandler(_ request: Request) throws -> Future<User> {
        return try request.parameters.next(User.self)
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
        return try User.query(on: request).group(.or) { or in
            
            try or.filter(\.firstName == searchTerm)
            try or.filter(\.lastName == searchTerm)
            try or.filter(\.userTypeSearch == searchTerm)
            try or.filter(\.privileges == searchTerm)
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
        
        return try User.query(on: request).sort(\.lastName, .ascending).all()
    }
 
    // GET UserDetails for User
    func getUserDetailsHandler(_ request: Request) throws -> Future<[UserDetails]> {
        //  Feth the user specified in the request's paramaters and unwarp the returned future.
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
}
