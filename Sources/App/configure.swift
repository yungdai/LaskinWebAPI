import FluentPostgreSQL
import Vapor
import Leaf
import Authentication

/// Called before your application initializes.
///
/// https://docs.vapor.codes/3.0/getting-started/structure/#configureswift
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())
    // Added for Leaf Support
    try services.register(LeafProvider())
    // Added for Authentication Support
    try services.register(AuthenticationProvider())

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
//    middlewares.use(DateMiddleware.self) // Adds `Date` header to responses
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    
    // This middleware adds sessions to the application
    middlewares.use(SessionsMiddleware.self)
    
    // Register all the middleware
    services.register(middlewares)

    // Docker command used to create the test database
    // docker run --name laskindb -e POSTGRES_DB=vapor -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=laskinAdmin -p 5432:5432 -d postgres
    
    /// Configure PostgreSQL Database
    var databases = DatabasesConfig()
    
    // fetch environement variables set by Vapor Cloud.  If it's nil return the coalescing values
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"

    
    
   
    // allow for testing the database
    let databaseName: String
    let databasePort: Int
    let username: String
    let password: String
    // if we are running the testing environment set the database and port to the testing database name and port values
    if env == .testing {
        databaseName = "vapor-test"
        databasePort = 5433
        username = "vapor"
        password = "password"
    } else {
        databaseName = Environment.get("DATABASE_DB") ?? "vapor"
        databasePort = 5432
        username = Environment.get("DATABASE_USER") ?? "admin"
        password = Environment.get("DATABASE_PASSWORD") ?? "laskinAdmin"
    }

    // user properties to create the config
    let databaseConfig = PostgreSQLDatabaseConfig(hostname: hostname,
                                                  port: databasePort,
                                                  username: username,
                                                  database: databaseName,
                                                  password: password)
    
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: UserDetails.self, database: .psql)
    migrations.add(model: MatchMakingData.self, database: .psql)
    
    // Add Token for Authentication
    migrations.add(model: Token.self, database: .psql)
	
	// Add an AdminUser so that app executes the migration a the next time the app is launched
	migrations.add(migration: AdminUser.self, database: .psql)
    
    services.register(migrations)
    
    // Configure the rest of your application here:
    // create a CommandConfig with the default configuration
    var commandConfig = CommandConfig.default()
    // Add the revert command with the identifier revert.  This is the string you use to to invoke the command
    commandConfig.useFluentCommands()
    // register the commandConfig as a service
    services.register(commandConfig)
    
    // ADDED FOR AUTHENTICATION:
    // Make sure the user database is to use the User.Public Database by default
    User.Public.defaultDatabase = .psql

    // For Authentication, the router must happen AFTER the migrations.
    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // Configure the rest of the application here
    config.prefer(DictionaryKeyedCache.self, for: KeyedCache.self)
}
