import Vapor
import Leaf
import Foundation

struct WebsiteController: RouteCollection {
    
    func boot(router: Router) throws {
        
        // set up the main index route
        router.get(use: indexHandler)
        router.get("users", User.parameter, use: userHandler)
        
        // CREATE USER and POST DATA
        router.get("create-user", use: createUserHandler)
        router.post("create-user", use: createUserPostHandler)
        
        // EDIT USER and POST DATA
        router.get("users", User.parameter, "edit", use: editUserHandler)
        router.post("users", User.parameter, "edit", use: editUserPostHandler)
        
        // set up creating UserDetails
        // GET the user details page
        router.get("users", User.parameter, "userDetails-create", use: createUserDetailsHandler)
        
        // POST the data to save
        router.post("users", User.parameter, "userDetails-create", use: createUserDetailsPostHandler)
        
        // GET the edit User Details page
        router.get("users", User.parameter, "userDetails", UserDetails.parameter, "edit", use: editUserDetailsHandler)
        router.post("users", User.parameter, "userDetails", UserDetails.parameter, "edit", use: editUserDetailsPostHandler)

        // CREATE MatchMakingData
        router.get("users", User.parameter, "matchMakingData-create", use: createMatchMakingDataHandler)
        router.post("users", User.parameter, "matchMakingData-create", use: createMatchMakingDataPostHandler)
        
        // EDIT MatchMakingData
        router.get("users", User.parameter, "matchMakingData", MatchMakingData.parameter, "edit", use: editMatchMakingDataHandler)
        router.post("users", User.parameter, "matchMakingData", MatchMakingData.parameter, "edit", use: editMatchMakingDataPostHandler)
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
        
        return try request.parameters.next(User.self).flatMap(to: View.self) { user in
            
            return try flatMap(to: View.self, user.userDetails.query(on: request).first(), user.matchMakingData.query(on: request).first()) { userDetails, matchMakingData in
                
                let context = UserContext(title: "User Information", user: user, fullName: user.getFullName(), userDetails: userDetails, matchMakingData: matchMakingData)
                return try request.leaf().render("user", context)
            }
        }
    }

    // router.get("users", User.parameter, "userDetails-create", use: createUserDetailsHandler)
    // CREATE UserDetails handler
    func createUserDetailsHandler(_ request: Request) throws -> Future<View> {
        return try request.parameters.next(User.self).flatMap(to: View.self) { user in
            let fullName = user.getFullName()
            let context = CreateUserDetailContext(title: "Create User Details for \(fullName)", user: user, fullName: user.getFullName())
            return try request.leaf().render("createUserDetails", context)
        }
    }
    
    //  router.post("users", User.parameter, "userDetails", "create", use: createUserDetailsPostHandler)

    // CREATE UserDetails POST handler
    func createUserDetailsPostHandler(_ request: Request) throws -> Future<Response> {
        
        return try flatMap(to: Response.self, request.parameters.next(User.self), request.content.decode(UserDetailsPostData.self)) { user, data in
            
            let conflictingSchools = data.conflictingSchools.components(separatedBy: ",")
            
            // create the UserDetails
            let userDetails = UserDetails(userID: user.id!,
                                          emailAddress: data.emailAddress,
                                          mobilePhone: data.mobilePhone,
                                          officePhone: data.officePhone,
                                          requiresAccessibility: data.requiresAccessibility,
                                          accessibilityNeeds: data.accessibilityNeeds,
                                          hasDietaryNeeds: data.hasDietaryNeeds,
                                          dietaryNeeds: data.dietaryNeeds,
                                          conflictingSchools: conflictingSchools)
            
            return userDetails.save(on: request).map(to: Response.self) { userDetails in
                
                guard let _ = userDetails.id else {
                    
                    // send the user back to the home page if the userID is wrong
                    return request.redirect(to: "/")
                }
                
                // everything is find so go to the page you just created
                return request.redirect(to: "/users/\(userDetails.userID)")
            }
        }
    }
    
    // Edit UserDetails Handler
    func editUserDetailsHandler(_ request: Request) throws -> Future<View> {
        return try flatMap(to: View.self, request.parameters.next(User.self), request.parameters.next(UserDetails.self)) { user, userDetails in
    
            let context = EditUserDetailsContext(title: "Edit User Details", userDetails:userDetails, user: user, fullName: user.getFullName())
            return try request.leaf().render("createUserDetails", context)
        }
    }
    
    // Edit UserDetails Post Handler
    func editUserDetailsPostHandler(_ request: Request) throws -> Future<Response> {
        
        // retrieve the paramater for the UserData, and decode the post data
        return try flatMap(to: Response.self, request.parameters.next(User.self), request.parameters.next(UserDetails.self), request.content.decode(UserDetailsPostData.self)) { user, userDetails, data in

            userDetails.emailAddress = data.emailAddress
            userDetails.mobilePhone = data.mobilePhone
            userDetails.officePhone = data.officePhone
            userDetails.requiresAccessibility = data.requiresAccessibility
            userDetails.accessibilityNeeds = data.accessibilityNeeds
            userDetails.hasDietaryNeeds = data.hasDietaryNeeds
            userDetails.dietaryNeeds = data.dietaryNeeds
            
            let conflictingSchools = data.conflictingSchools.components(separatedBy: ",")
            userDetails.conflictingSchools = conflictingSchools
        
            userDetails.userID = user.id!
            
            return userDetails.save(on: request).map(to: Response.self) { userDetails in
                guard let _ = userDetails.id else {
                    return request.redirect(to: "/")
                }
                
                return request.redirect(to: "/users/\(userDetails.userID)")
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
            let user = User(firstName: data.firstName, lastName: data.lastName, userType: data.userType, privileges: data.privileges)
            
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
    
    // CREATE MATCHMAKING DATA
    // router.get("users", User.parameter, "matchMakingData", "create", user: createMatchMakingData)
    func createMatchMakingDataHandler(_ request: Request) throws -> Future<View> {
        return try request.parameters.next(User.self).flatMap(to: View.self) { user in
            
            let fullName = user.getFullName()
            let context = CreateMatchMakingDataContext(title: "Create Match Making Data for \(fullName)", user: user, fullName: fullName, provinces: Province.getProvinces(), timeZones: TimeZones.getTimeZones(), orders:["1", "2"], interpreters: ["English", "French", "None"])
            return try request.leaf().render("createMatchMakingData", context)
        }
    }
    
    func createMatchMakingDataPostHandler(_ request: Request) throws -> Future<Response> {
        
        return try flatMap(to: Response.self, request.parameters.next(User.self), request.content.decode(MatchMakingDataPostData.self)) { user, data in

            let matchMakingData = MatchMakingData(userID: user.id!, school: data.school, city: data.city, province:data.province, timeZone: TimeZones.timeZoneValue(by: data.timeZone), needsInterpreter: data.needsInterpreter, interpreterType: data.interpreterType, order: Int(data.order) ?? 0, additionalNotes: data.additionalNotes)
            
            return matchMakingData.save(on: request).map(to: Response.self) { matchMakingData in
             
                guard let _ = matchMakingData.id else {
                    // something wrong happened, go home
                    return request.redirect(to: "/")
                }
                // success
                return request.redirect(to: "/users/\(matchMakingData.userID)")
            }
        }
    }
    
    // EDIT MatchMakingData
    func editMatchMakingDataHandler(_ request: Request) throws -> Future<View> {
        return try flatMap(to: View.self, request.parameters.next(User.self), request.parameters.next(MatchMakingData.self)) { user, matchMakingData in
            
            let fullName = user.getFullName()
            let context = EditMatchMakingDataContext(title: "Edit Match Making Data for \(fullName)", user: user, matchMakingData: matchMakingData, fullName: fullName, provinces: Province.getProvinces(), timeZones: TimeZones.getTimeZones(), orders:["1", "2"], interpreters: ["English", "French", "None"])
            return try request.leaf().render("createMatchMakingData", context)
        }
    }
    
    // EDIT MatchMakingData Post Handler
    func editMatchMakingDataPostHandler(_ request: Request) throws -> Future<Response> {
        
        // retrieve the parameter for the MatchMakingData and decode the post data
        return try flatMap(to: Response.self, request.parameters.next(User.self), request.parameters.next(MatchMakingData.self),request.content.decode(MatchMakingDataPostData.self)) { user, matchMakingData, updatedData in
            
            matchMakingData.school = updatedData.school
            matchMakingData.city = updatedData.city
            matchMakingData.province = updatedData.province
            matchMakingData.timeZone = TimeZones.timeZoneValue(by: updatedData.timeZone)
            matchMakingData.needsInterpreter = updatedData.needsInterpreter
            matchMakingData.interpreterType = updatedData.interpreterType
            matchMakingData.order = Int(updatedData.order) ?? 0
            matchMakingData.additionalNotes = updatedData.additionalNotes
            
            return matchMakingData.save(on: request).map(to: Response.self) { matchMakingData in
                
                // failure
                guard let _ = matchMakingData.id else {
                    return request.redirect(to: "/")
                }
                
                // success
                return request.redirect(to: "/users/\(matchMakingData.userID)")
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

// create a struct for the objects in the index.leaf page
struct IndexContext: Codable {
    
    let title: String
    let users: [User]?
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

// This is the first part to creating a Create UserDetail Page
struct CreateUserDetailContext: Codable {
    
    let title: String
    let user: User
    let fullName: String
}

struct CreateMatchMakingDataContext: Codable {
    
    let title: String
    let user: User
    let fullName: String
    
    let provinces: [String]
    let timeZones: [String]
    let orders: [String]
    let interpreters: [String]
}

// This is the struct for posting a new UserDetailsData object for creating UserDetails
struct UserDetailsPostData: Content {
    
    // let vapor know the data is from generated page
    static var defaultMediaType = MediaType.urlEncodedForm
    
    let emailAddress: String
    let mobilePhone: String
    let officePhone: String
    let requiresAccessibility: Bool
    let accessibilityNeeds: String
    let hasDietaryNeeds: Bool
    let dietaryNeeds: String
    let conflictingSchools: String
}

struct UserPostData: Content {
    
    static var defaultMediaType = MediaType.urlEncodedForm
    
    let firstName: String
    let lastName: String
    let userType: String
    let privileges: String
}

struct MatchMakingDataPostData: Content {
    
    static var defaultMediaType = MediaType.urlEncodedForm
    
    let school: String
    let city: String
    let province: String
    let timeZone: String
    let needsInterpreter: Bool
    let interpreterType: String
    let order: String
    let additionalNotes: String
}

// EDIT UserDetails struct
struct EditUserDetailsContext: Codable {
    
    let title: String
    let userDetails: UserDetails
    let user: User
    let fullName: String
    
    // set editing to true so you can tell the document you're in edit mode
    let editing = true
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

struct EditMatchMakingDataContext: Codable {
    
    let title: String
    let user: User
    let matchMakingData: MatchMakingData
    let fullName: String

    let provinces: [String]
    let timeZones: [String]
    let orders: [String]
    let interpreters: [String]
    
    let editing = true
}

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

