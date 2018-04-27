import Vapor
import Leaf
import Foundation
import Authentication
import Crypto

struct UserWebsiteController: RouteCollection {
    
    func boot(router: Router) throws {
    
        // Uncomment this and push to the server when you need to start out and create a new user for administration.
        //        router.get("create-user", use: createUserHandler)
        //        router.post("create-user", use: createUserPostHandler)
        
        // Web Authentication Route Group ensures that the user must be logged in to use the following routes.
        let authSessionsRoutes = router.grouped(User.authSessionsMiddleware())
        
        // Authentication Middleware to ensure the user is logged in to make sure they don't need to relogin for every page.
        // REQUIRED: import Authentication
        // This allows the user to redirect to the login page if you're not already authenticated.
        let proctectedRoutes = authSessionsRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
        
        // NOTE: Any routes here can always get the authenitcation user by doing the following in their route functions:
        // let user = try request.requiredAuthenticated(User.self) to get the authenticated user
        // You will still need to pass a userID and get the parameter if you want another user.
        
        proctectedRoutes.get("users", User.parameter, use: userHandler)
        
        // CREATE USER and POST DATA
        proctectedRoutes.get("create-user", use: createUserHandler)
        proctectedRoutes.post("create-user", use: createUserPostHandler)
        
        
        // EDIT USER and POST DATA
        proctectedRoutes.get("users", User.parameter, "edit", use: editUserHandler)
        proctectedRoutes.post("users", User.parameter, "edit", use: editUserPostHandler)
    }
    
    // return the user page
    func userHandler(_ request: Request) throws -> Future<View> {
        
        return try request.parameters.next(User.self).flatMap(to: View.self) { user in
            
            return try flatMap(to: View.self, user.userDetails.query(on: request).first(), user.matchMakingData.query(on: request).first()) { userDetails, matchMakingData in
                
                let context = UserContext(title: "User Information", user: user, fullName: user.getFullName(), userDetails: userDetails, matchMakingData: matchMakingData)
                return try request.leaf().render("user", context)
            }
        }
    }
    
    // CREATE USER
    func createUserHandler(_ request: Request) throws -> Future<View> {
        
        // send an array of userTypes and privileges to make sure they're selectable
        let context = CreateUserContext(title: "Create User", userTypes: User.getUserTypes(), userPrivileges: User.getPrivileges())
        
        return try request.leaf().render("createUser", context)
    }
    
    // CREATE POST USER
    func createUserPostHandler(_ request: Request) throws ->Future<Response> {
        
        return try request.content.decode(UserPostData.self).flatMap(to: Response.self) { data in
            
            // create the user
            let user = User(firstName: data.firstName, lastName: data.lastName, userType: data.userType, privileges: data.privileges, password: data.password, userName: data.userName)
            
            // save the user and check the ID to make sure it's saved properly
            return user.save(on: request).map(to: Response.self) { user in
                
                guard let id = user.id else {
                    
                    // send home for now, but we will need to deal with an error in creating a user in the future
                    return request.redirect(to: "/")
                }
                
                // All okay, redirect to the newly created user
                return request.redirect(to: "/users/\(id)")
            }
        }
    }
    
    // EDIT USER
    func editUserHandler(_ request: Request) throws -> Future<View> {
        
        return try request.parameters.next(User.self).flatMap(to: View.self) { user in
            
            let fullName = user.getFullName()
            let context = EditUserContext(title: "Edit User: \(fullName) ", user: user, fullName: fullName, userTypes: User.getUserTypes(), userPrivileges: User.getPrivileges())
            
            return try request.leaf().render("createUser", context)
        }
    }
    
    // EDIT USER POST Handler
    func editUserPostHandler(_ request: Request) throws -> Future<Response> {
        
        return try flatMap(to: Response.self, request.parameters.next(User.self), request.content.decode(UserPostData.self)) { user, data in
            
            user.firstName = data.firstName
            user.lastName = data.lastName
            user.userType = data.userType
            user.privileges = data.privileges
            
            if data.privileges == "" {
                user.privileges = "none"
            }
            
            return user.save(on: request).map(to: Response.self) { user in
                
                guard let id = user.id else {
                    
                    // failure
                    return request.redirect(to: "/")
                }
                
                // success!
                return request.redirect(to: "/users/\(id)")
            }
        }
    }
}

struct UserContext: Codable {
    
    let title: String
    let user: User
    let fullName: String
    
    let userDetails: UserDetails?
    let matchMakingData: MatchMakingData?
}

struct CreateUserContext: Codable {
    
    let title: String
    let userTypes: [String]
    let userPrivileges: [String]
}

struct UserPostData: Content {
    
    static var defaultMediaType = MediaType.urlEncodedForm
    
    let firstName: String
    let lastName: String
    let userType: String
    let privileges: String
    let userName: String
    let password: String
}

// EDIT User struct
struct EditUserContext: Codable {
    
    let title: String
    let user: User
    let fullName: String
    let userTypes: [String]
    let userPrivileges: [String]
    
    let editing = true
}
