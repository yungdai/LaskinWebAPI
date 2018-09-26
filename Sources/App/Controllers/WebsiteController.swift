import Vapor
import Leaf
import Foundation
import Authentication
import Fluent

// this is for the Password Encryption
import Crypto

struct WebsiteController: RouteCollection {
    
    func boot(router: Router) throws {
        
        // Web Authentication Route Group ensures that the user must be logged in to use the following routes.

		let tokenAuthMiddleWare = User.tokenAuthMiddleware()
		let guardAuthMiddleware = User.guardAuthMiddleware()
		
		let tokenAuthGroup = router.grouped(tokenAuthMiddleWare, guardAuthMiddleware)
        
        // LOGIN Page
        tokenAuthGroup.get("login", use: loginHandler)
        // LOGIN Post Data
        tokenAuthGroup.post("login", use: loginPostHandler)
        
        // you can see the users but you cannot do anything until you log in
        // set up the main index route
        tokenAuthGroup.get(use: indexHandler)
        
        // Authentication Middleware to ensure the user is logged in to make sure they don't need to relogin for every page.
        // REQUIRED: import Authentication
        // This allows the user to redirect to the login page if you're not already authenticated.
        let protectedRoutes = tokenAuthGroup.grouped(RedirectMiddleware<User>(path: "/login"))
        
        // log out
        protectedRoutes.get(User.parameter,"logout", use: logOutHandler)
    }
    
    // Default route where the templates will spawn from
    func indexHandler(_ request: Request) throws -> Future<View> {
        
      // query the database to get all users
        return User.query(on: request).all().flatMap(to: View.self) { users in

            let currentUser = try request.authenticated(User.self)
            let context = IndexContext(title: "HomePage", users: users.isEmpty ? nil : users, authenticatedUser: currentUser)
            
            return try request.leaf().render("index", context)
        }
    }
    
    func logOutHandler(_ request: Request) throws -> Future<Response> {
        
        return try request.parameters.next(User.self).map(to: Response.self) { user in
      
            try request.unauthenticateSession(User.self)
            
            return request.redirect(to: "/")
        }
    }

    // LOGIN Handler
    func loginHandler(_ request: Request) throws -> Future<View> {
        
        let context = LoginContext(title: "Log In")
        return try request.leaf().render("login", context)
    }
    
    func loginPostHandler(_ request: Request) throws -> Future<Response> {
        
        // send the data from the form to the decode function
        return try request.content.decode(LoginPostData.self).flatMap(to: Response.self) { data in
            
            // this requires you to import Crypto for password encyption
            let verifier = try request.make(BCryptDigest.self)
            return User.authenticate(username: data.userName, password: data.password, using: verifier, on: request).map(to: Response.self) { user in
                
                // FAILURE:
                // TODO: Throw up a real error on the login page
                guard let user = user else {
                    return request.redirect(to: "/login")
                }
                
                try request.authenticateSession(user)
                return request.redirect(to: "/")
            }
        }
    }
}

extension Request {
    // helper function help render the webpage with a little less boilerplate code
    func leaf() throws -> LeafRenderer {
        return try self.make(LeafRenderer.self)
    }
}

// create a struct for the objects for the handlers to pass data to the pages
struct IndexContext: Codable {
    
    let title: String
    let users: [User]?
    let authenticatedUser: User?
}



struct LoginContext: Codable {
    let title: String
}

struct LoginPostData: Content {
    
    let userName: String
    let password: String
}



