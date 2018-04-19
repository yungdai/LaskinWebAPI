import Vapor
import Leaf
import Foundation

struct WebsiteController: RouteCollection {
    
    func boot(router: Router) throws {
        
        // set up the main index route
        router.get(use: indexHandler)
        router.get("users", User.parameter, use: userHandler)
    }
    
    // this is the default where the templates will spawn from
    func indexHandler(_ request: Request) throws -> Future<View> {
        
        // query the database to get all users
        return User.query(on: request).all().flatMap(to: View.self) { users in
            
            let context = IndexContext(title: "HomePage", users: users.isEmpty ? nil : users)
            return try request.leaf().render("index", context)
        }
    }
    
    // return the user page
    func userHandler(_ request: Request) throws -> Future<View> {

        return try request.parameter(User.self).flatMap(to: View.self) { user in
            
            let context = UserContext(title: "User Information", user: user)
            return try request.leaf().render("user", context)
        }
    }
}

extension Request {
    // helper function help render the webpage with a little less boilerplate code
    func leaf() throws -> LeafRenderer {
        return try self.make(LeafRenderer.self)
    }
}

// create a struct for the objects in the index.leaf page
struct IndexContext: Codable {
    
    let title: String
    let users: [User]?
}

struct UserContext: Codable {
    
    let title: String
    let user: User
}

