import Vapor
import Leaf
import Foundation
import Authentication

// this is for the Password Encryption
import Crypto

struct WebsiteController: RouteCollection {
    
    func boot(router: Router) throws {
        
        // Web Authentication Route Group ensures that the user must be logged in to use the following routes.
        let authSessionsRoutes = router.grouped(User.authSessionsMiddleware())
        
        // LOGIN Page
        authSessionsRoutes.get("login", use: loginHandler)
        // LOGIN Post Data
        authSessionsRoutes.post("login", use: loginPostHandler)
        
        // you can see the users but you cannot do anything until you log in
        // set up the main index route
        authSessionsRoutes.get(use: indexHandler)
    }
    
    // this is the default where the templates will spawn from
    func indexHandler(_ request: Request) throws -> Future<View> {
        
        // query the database to get all users
        return User.query(on: request).all().flatMap(to: View.self) { users in
            
            let context = IndexContext(title: "HomePage", users: users.isEmpty ? nil : users, authenticated: try request.isAuthenticated(User.self))
            
            return try request.leaf().render("index", context)
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
    let authenticated: Bool
}



struct LoginContext: Codable {
    let title: String
}

struct LoginPostData: Content {
    
    let userName: String
    let password: String
}


// TODO: Move these enums to where they will make sense
enum TimeZones: Int, Codable {
    case pacific = 0
    case mountain = 1
    case central = 2
    case eastern = 3
    case atlantic = 4
    case newfoundland = 5
    
    static func getTimeZones() -> [String] {
        
        let timeZones = ["Pacific", "Mountain", "Central", "Eastern", "Atlantic", "Newfoundland"]
        return timeZones
    }
    
    static func timeZoneValue(by name: String) -> Int {
        switch(name) {
        case "Pacific":
            return 0
        case "Mountain":
            return 1
        case "Central":
            return 2
        case "Eastern":
            return 3
        case "Atlantic":
            return 4
        case "Newfoundland":
            return 5
        default:
            return 0
        }
    }
}

// Public enums to be used for locations
enum Province: String, Codable {
    case britishColumbia = "British Columbia"
    case alberta = "Alberta"
    case saskatchewan = "Saskatchewan"
    case manitoba = "Manitoba"
    case ontario = "Ontario"
    case quebec = "Quebec"
    case novaScotia = "Nova Scotia"
    case newBrunswick = "New Brunswick"
    case princeEdwardIsland = "Prince Edward Island"
    case newfoundlandLabrador = "Newfoundland & Labrador"
    case yukon = "Yukon"
    case northwestTerritories = "Northwest Territories"
    case nunavut = "Nunavut"
    
    static func getProvinces() -> [String] {
        let provinces = ["British Columbia", "Alberta", "Saskatchewan", "Manitoba", "Ontario", "Quebec", "Nova Scotia", "New Brunswick", "Prince Edward Island", "Newfoundland & Labrardor", "Yukon", "Northwest Territories", "Nunavut"]
        return provinces
    }
    
    public var timeZone: TimeZones {
        switch self {
        case .britishColumbia, .yukon:
            return .pacific
        case .alberta, .northwestTerritories:
            return .mountain
        case .saskatchewan, .manitoba, .nunavut:
            return .central
        case .ontario, .quebec:
            return .eastern
        case .novaScotia, .princeEdwardIsland, .newBrunswick:
            return .atlantic
        case .newfoundlandLabrador:
            return .newfoundland
        }
    }
}

