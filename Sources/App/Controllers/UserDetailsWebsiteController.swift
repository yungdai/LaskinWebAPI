import Vapor
import Leaf
import Foundation
import Authentication
import Crypto

struct UserDetailsWebsiteController: RouteCollection {
    
    func boot(router: Router) throws {

        // Web Authentication Route Group ensures that the user must be logged in to use the following routes.
		
		let tokenAuthMiddleWare = User.tokenAuthMiddleware()
		let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokeAuthGroup = router.grouped(tokenAuthMiddleWare, guardAuthMiddleware)
        
        // Authentication Middleware to ensure the user is logged in to make sure they don't need to relogin for every page.
        // REQUIRED: import Authentication
        // This allows the user to redirect to the login page if you're not already authenticated.
        let proctectedRoutes = tokeAuthGroup.grouped(RedirectMiddleware<User>(path: "/login"))
        
        // NOTE: Any routes here can always get the authenitcation user by doing the following in their route functions:
        // let user = try request.requiredAuthenticated(User.self) to get the authenticated user
        // You will still need to pass a userID and get the parameter if you want another user.
        
        // set up creating UserDetails
        // GET the user details page
        proctectedRoutes.get("users", User.parameter, "userDetails-create", use: createUserDetailsHandler)
        
        // POST the data to save
        proctectedRoutes.post("users", User.parameter, "userDetails-create", use: createUserDetailsPostHandler)
        
        // GET the edit User Details page
        proctectedRoutes.get("users", User.parameter, "userDetails", UserDetails.parameter, "edit", use: editUserDetailsHandler)
        proctectedRoutes.post("users", User.parameter, "userDetails", UserDetails.parameter, "edit", use: editUserDetailsPostHandler)
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
    
}

// This is the first part to creating a Create UserDetail Page
struct CreateUserDetailContext: Codable {
    
    let title: String
    let user: User
    let fullName: String
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

// EDIT UserDetails struct
struct EditUserDetailsContext: Codable {
    
    let title: String
    let userDetails: UserDetails
    let user: User
    let fullName: String
    
    // set editing to true so you can tell the document you're in edit mode
    let editing = true
}

