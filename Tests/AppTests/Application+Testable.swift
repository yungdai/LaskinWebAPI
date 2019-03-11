import Vapor
import App
import FluentPostgreSQL

extension Application {
    
    /// Used to create a testable environment
    static func testable(envArgs: [String]? = nil) throws -> Application {
        
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        
        if let environmentArgs = envArgs {
            env.arguments = environmentArgs
        }
        
        try App.configure(&config, &env, &services)
        let app = try Application(
            config: config,
            environment: env,
            services: services)
        
        try App.boot(app)
        return app
    }
    
    // Used to reset the testable evironment
    static func reset() throws {
        
        let revertEnvironment = ["vapor", "revert", "--all", "-y"]
        try Application.testable(envArgs: revertEnvironment)
        .asyncRun()
        .wait()
        
        let migrateEnvironment = ["vapor", "migrate", "-y"]
        try Application.testable(envArgs: migrateEnvironment)
        .asyncRun()
        .wait()
    }
    
    
    /// Used to send a reqeust to a path and returns a Response. Allowing for generic Content to be provided
    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: T? = nil) throws -> Response where T: Content {
        
        // create a responder, request and wrapped request
        let responder = try self.make(Responder.self)
        
        let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
        
        let wrappedRequest = Request(http: request, using: self)
        
        // if the test contains a body, encode the body into the request's content
        if let body = body {
            try wrappedRequest.content.encode(body)
        }
        
        // send the request and return the reponse
        return try responder.respond(to: wrappedRequest).wait()
    }
    
    /// Use to send a request to a path without a body
    func sendRequest(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init()) throws -> Response {
        
        // create an EmptyContent
        let emptyContent: EmptyContent? = nil
        
        // use the method created pervios to send the request
        return try sendRequest(to: path, method: method, headers: headers, body: emptyContent)
    }
    
    /// Use to send a request to a path and accepts a generic Content type.
    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders, data: T) throws where T: Content {
        
        // send the reuqest and ignore the reponse
        _ = try self.sendRequest(to: path, method: method, headers: headers, body: data)
    }
}

struct EmptyContent: Content {}
