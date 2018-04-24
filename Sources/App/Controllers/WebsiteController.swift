import Vapor
import Leaf
import Foundation

struct WebsiteController: RouteCollection {
    
    func boot(router: Router) throws {
        
        // set up the main index route
        router.get(use: indexHandler)
        router.get("users", User.parameter, use: userHandler)
        
        // set up creating User Details
        // GET the user details page
        router.get("users", User.parameter, "userDetails", "create", use: createUserDetailsHandler)
        
        // POST the data to save
        router.post("users", User.parameter, "userDetails", "create", use: createUserDetailsPostHandler)
        
        // GET the edit User Details page
        router.get("users", User.parameter, "userDetails", UserDetails.parameter, "edit", use: editUserDetailsHandler)
        router.post("users", User.parameter, "userDetails", UserDetails.parameter, "edit", use: editUserDetailsPostHandler)
        
        
        // CREATE USER and POST DATA
        router.get("create-user", use: createUserHandler)
        router.post("create-user", use: createUserPostHandler)
        
        // EDIT USER and POST DATA
        router.get("users", User.parameter, "edit", use: editUserHandler)
        router.post("users", User.parameter, "edit", use: editUserPostHandler)
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
    
    // router.get("users", User.parameter, "userDetails", "create", use: createUserDetailsHandler)
    // CREATE UserDetails handler
    func createUserDetailsHandler(_ request: Request) throws -> Future<View> {
        
        return try request.parameters.next(User.self).flatMap(to: View.self) { user in
            
            let context = CreateUserDetailContext(title: "Create User Details for \(user.firstName) \(user.lastName)", user: user, fullName: user.getFullName())
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
