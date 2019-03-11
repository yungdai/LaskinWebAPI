@testable import App
import Vapor
import XCTest
import FluentPostgreSQL


final class UserTests: XCTestCase {
    
    
    
    func testUserCanBeRetievedFromAPI() throws {
        
        // set the arguments the Application should execute
        let revertEnvironmentArgs = ["vapor", "revert", "--all", "-y"]
        
        // set up the services, configuration and testing environment
        var revertConfig = Config.default()
        var revertServices = Services.default()
        var revertEnv = Environment.testing
        
        // set the argements in the environment
        revertEnv.arguments = revertEnvironmentArgs
        
        // set up the application as earlier in the test.  This creates a different Application object that exectutes the revert command.
        try App.configure(&revertConfig, &revertEnv, &revertServices)
        
        let revertApp = try Application(
            config: revertConfig,
            environment: revertEnv,
            services: revertServices)
        
        try App.boot(revertApp)
        
        // call asynchRun() which starts the application and execute the revert command
        try revertApp.asyncRun().wait()
        
        // repeat the process again to the run the migration.  This setups up the database on a separate connection, similiar to how Vapor does it.
        let migrateEnvironmentArgs = ["vapor", "migrate", "-y"]
        var migrateConfig = Config.default()
        var migrateServices = Services.default()
        var migrateEnv = Environment.testing
        migrateEnv.arguments = migrateEnvironmentArgs
        
        try App.configure(&migrateConfig, &migrateEnv, &migrateServices)
        
        let migrateApp = try Application(config: migrateConfig,
                                         environment: migrateEnv,
                                         services: migrateServices)
        
        try App.boot(migrateApp)
        try migrateApp.asyncRun().wait()
        
        //  Definde some expected values
        let expectedFirstName = "Yung"
        let expectedLastName = "Dai"
        let expectedUsername = "admin"
        let expectedUserType = UserType.administrator
        let expectedPriviledges = AppPrivileges.admin
        
        // Create an Application as in the main.swift.  It creates an Application Object but doesn't start running the applicaiton.  This helps to make sure we are using the testing evironment when testing with the Applicaiton object
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        try App.configure(&config, &env, &services)
        
        let app = try Application(config: config,
                                  environment: env,
                                  services: services)
        try App.boot(app)
        
        // Create a database connection to perform database operations.  Using wait() for the future to return.
        let conn = try app.newConnection(to: .psql).wait()
        
        // Create a couple of users and save them to the database
        let user = User(firstName: expectedFirstName, lastName: expectedLastName, userType: expectedUserType, privileges: expectedPriviledges, password: "admin", userName: expectedUsername)
        
        // save the test user
        let savedUser = try user.save(on: conn).wait()
        
        
        _ = try User(firstName: "Tim", lastName: "Moseley", userType: .administrator, privileges: .admin, password: "password", userName: "Tim")
        
        // create a responsder type that responds to requests
        let responder = try app.make(Responder.self)
        
        // send a get HTTP request to /api/users the endpoint for getting all the users.  A request object wraps the HTTPRequest so there's a worker to exectue it.  Sinc ethis is a test you can force unwrap variables to simplify the code.
        let request = HTTPRequest(method: .GET, url: URL(string: "/api/users")!)
        let wrappedRequest = Request(http: request, using: app)
        
        // Send the request and get the response
        let response = try responder.respond(to: wrappedRequest).wait()
        
        // Decode the reponse data into an array of users
        let data = response.http.body.data
        let users = try JSONDecoder().decode([User].self, from: data!)
        
        // Ensure there are the corect number of users
        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].firstName, expectedFirstName)
        XCTAssertEqual(users[0].lastName, expectedLastName)
        XCTAssertEqual(users[0].userType, expectedUserType.rawValue)
        XCTAssertEqual(users[0].privileges, expectedPriviledges.rawValue)
        XCTAssertEqual(users[0].userName, expectedUsername)
        XCTAssertEqual(users[0].id, savedUser.id)
        
        // close the connection to the database once the test has finished
        conn.close()
        
    }
}
