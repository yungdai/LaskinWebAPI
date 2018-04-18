import Routing
import Vapor

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!  It's me, Laskin."
    }

    let usersController = UsersController()
    try router.register(collection: usersController)
    
    let userDetailsController = UserDetailsController()
    try router.register(collection: userDetailsController)
    
    let matchMakingDataController = MatchMakingDataController()
    try router.register(collection: matchMakingDataController)
}
