import Vapor
import Leaf
import Foundation
import Authentication
import Fluent

// this is for the Password Encryption
import Crypto

struct WebsiteController: RouteCollection {
    
    func boot(router: Router) throws {
        
        // public
        router.get("create-admin", use: createAdminUserHandler)
        
        // Web Authentication Route Group ensures that the user must be logged in to use the following routes.
        let authSessionsRoutes = router.grouped(User.authSessionsMiddleware())
        
        // LOGIN Page
        authSessionsRoutes.get("login", use: loginHandler)
        // LOGIN Post Data
        authSessionsRoutes.post("login", use: loginPostHandler)
        
        // you can see the users but you cannot do anything until you log in
        // set up the main index route
        authSessionsRoutes.get(use: indexHandler)
        
        // Authentication Middleware to ensure the user is logged in to make sure they don't need to relogin for every page.
        // REQUIRED: import Authentication
        // This allows the user to redirect to the login page if you're not already authenticated.
        let proctectedRoutes = authSessionsRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
        
        // log out
        proctectedRoutes.get(User.parameter,"logout", use: logOutHandler)
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
    
    // One time use route to create an admin account
    func createAdminUserHandler(_ request: Request) throws -> Future<Response> {

        return try User.Public.query(on: request).filter(\.userName == "admin").first().map(to: Response.self) { user in

            // if there is no user we will create a new admin user with a password default.
            guard let _ = user else  {
                
                let adminUser = User(firstName: "Administrator", lastName: "User", userType: "administrator", privileges: "admin", password: "password", userName: "admin")
                
                adminUser.password = try request.make(BCryptDigest.self).hash(adminUser.password)
                _ = adminUser.save(on: request)
                print("Saved User")
                return request.redirect(to: "/login")
            }

            return request.redirect(to: "/login")
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

public enum SchoolName: String, StringRepresentableEnum, Codable {
    case alberta = "Alberta"
    case dalhousie = "Dalhousie"
    case laval = "Laval"
    case manitoba = "Manitoba"
    case mcgill = "McGill"
    case moncton = "Moncton"
    case montreal = "Montreal"
    case montréal = "Montréal"
    case osgoode = "Osgoode"
    case ottawaCivil = "Ottawa Civil"
    case ottawaCommon = "Ottawa Common"
    case queens = "Queen's"
    case saskatchewan = "Saskatchewan"
    case sherbrooke = "Sherbrooke"
    case toronto = "Toronto"
    case ubc = "UBC"
    case unb = "UNB"
    case uqam = "UQAM"
    case western = "Western"
    case windsor = "Windsor"
 
    static func getSchools() -> [SchoolData] {
        
        let alberta = SchoolData(name: "Alberta", city: "Edmonton", province:  "Edmonton", timeZone: "Mountain")
        let dalhousie = SchoolData(name: "Dalhousie", city: "Halifax", province: "Nova Scotia", timeZone: "Atlantic")
        let laval = SchoolData(name: "Laval", city: "Montréal", province: "Quebec", timeZone: "Eastern")
        let manitoba = SchoolData(name: "Manitoba", city: "Winnipeg", province: "Manitoba", timeZone: "Central")
        let mcGill = SchoolData(name: "McGill", city: "Montréal", province: "Quebec", timeZone: "Eastern")
        let moncton = SchoolData(name: "Moncton", city: "Moncton", province: "New Brunswick", timeZone: "Atlantic")
        let montreal = SchoolData(name: "Montréal", city: "Montréal", province: "Quebec", timeZone: "Eastern")
        let osgoode = SchoolData(name: "Osgoode", city: "Toronto", province: "Ontario", timeZone: "Eastern")
        let ottawaCivil = SchoolData(name: "Ottawa Civil", city: "Ottawa", province: "Ontario", timeZone: "Eastern")
        let ottawaCommon = SchoolData(name: "Ottawa Common", city: "Ottawa", province: "Ontario", timeZone: "Eastern")
        let queens = SchoolData(name: "Queen's", city: "Kingston", province: "Ontario", timeZone: "Eastern")
        let saskatchewan = SchoolData(name: "Saskatchewan", city: "Saskatoon", province: "Saskatchewan", timeZone: "Central")
        let sherbrooke = SchoolData(name: "Sherbrooke", city: "Sherbrooke", province: "Quebec", timeZone: "Eastern")
        let toronto = SchoolData(name: "Toronto", city: "Toronto", province: "Ontario", timeZone: "Eastern")
        let ubc = SchoolData(name: "UBC", city: "Vancouver", province: "British Columbia", timeZone: "Pacific")
        let unb = SchoolData(name: "UNB", city: "Fredericton", province: "New Brunshwick", timeZone: "Pacific")
        let uqam = SchoolData(name: "UQAM", city: "Montréal", province: "Quebec", timeZone: "Eastern")
        let western = SchoolData(name: "Western", city: "London", province: "Ontario", timeZone: "Eastern")
        let windsor = SchoolData(name: "Windsor", city: "Windsor", province: "Ontario", timeZone: "Eastern")
        
        let schools = [alberta, dalhousie, laval, manitoba, mcGill, moncton, montreal, osgoode, ottawaCivil, ottawaCommon, queens, saskatchewan, sherbrooke, toronto, ubc, unb, uqam, western, windsor]
        
        return schools
    }
}

