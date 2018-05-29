import Vapor
import Leaf
import Foundation
import Authentication
import Crypto

struct MatchMakingDataWebsiteController: RouteCollection {
    
    func boot(router: Router) throws {
        
        // Web Authentication Route Group ensures that the user must be logged in to use the following routes.
        let authSessionsRoutes = router.grouped(User.authSessionsMiddleware())
        
        // Authentication Middleware to ensure the user is logged in to make sure they don't need to relogin for every page.
        // REQUIRED: import Authentication
        // This allows the user to redirect to the login page if you're not already authenticated.
        let proctectedRoutes = authSessionsRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
        
        // NOTE: Any routes here can always get the authenitcation user by doing the following in their route functions:
        // let user = try request.requiredAuthenticated(User.self) to get the authenticated user
        // You will still need to pass a userID and get the parameter if you want another user.
        
        // CREATE MatchMakingData
        proctectedRoutes.get("users", User.parameter, "matchMakingData","create", use: createMatchMakingDataHandler)
        proctectedRoutes.post("users", User.parameter, "matchMakingData", "create", use: createMatchMakingDataPostHandler)
        
        // EDIT MatchMakingData
        proctectedRoutes.get("users", User.parameter, "matchMakingData", MatchMakingData.parameter, "edit", use: editMatchMakingDataHandler)
        proctectedRoutes.post("users", User.parameter, "matchMakingData", MatchMakingData.parameter, "edit", use: editMatchMakingDataPostHandler)
    }
    
    // CREATE MATCHMAKING DATA
    // router.get("users", User.parameter, "matchMakingData", "create", user: createMatchMakingData)
    func createMatchMakingDataHandler(_ request: Request) throws -> Future<View> {
        return try request.parameters.next(User.self).flatMap(to: View.self) { user in
            
            let fullName = user.getFullName()
            
            let context = CreateMatchMakingDataContext(title: "Create Match Making Data for \(fullName)", user: user, fullName: fullName, schools: SchoolName.getSchools(), provinces: Province.getProvinces(), timeZones: TimeZones.getTimeZones(), orders:["1", "2"], interpreters: ["English", "French", "None"])
            
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
            let context = EditMatchMakingDataContext(title: "Edit Match Making Data for \(fullName)", user: user, matchMakingData: matchMakingData, fullName: fullName, schools: SchoolName.getSchools(), provinces: Province.getProvinces(), timeZones: TimeZones.getTimeZones(), orders:["1", "2"], interpreters: ["English", "French", "None"])
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

struct CreateMatchMakingDataContext: Codable {
    
    let title: String
    let user: User
    let fullName: String
    
    let schools: [SchoolData]
    let provinces: [String]
    let timeZones: [String]
    let orders: [String]
    let interpreters: [String]
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

struct EditMatchMakingDataContext: Codable {
    
    let title: String
    let user: User
    let matchMakingData: MatchMakingData
    let fullName: String
    
    let schools: [SchoolData]
    let provinces: [String]
    let timeZones: [String]
    let orders: [String]
    let interpreters: [String]
    
    let editing = true
}

struct SchoolData: Codable {
    
    let name: String
    let city: String
    let province: String
    let timeZone: String
}
