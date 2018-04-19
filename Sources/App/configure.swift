import FluentPostgreSQL
import Vapor
import Leaf

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
    try services.register(LeafProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(DateMiddleware.self) // Adds `Date` header to responses
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Docker command used to create the test database
    // docker run --name laskindb -e POSTGRES_DB=vapor -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=laskinAdmin -p 5432:5432 -d postgres
    
    /// Configure PostgreSQL Database
    var databases = DatabaseConfig()
    
    // fetch environement variables set by Vapor Cloud.  If it's nil return the coalescing values
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "admin"
    let databaseName = Environment.get("DATABASE_DB") ?? "vapor"
    let password = Environment.get("DATABASE_PASSWORD") ?? "laskinAdmin"

    // user properties to create the config
    let databaseConfig = PostgreSQLDatabaseConfig(hostname: hostname,
                                                  port: 5432,
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
    services.register(migrations)
    
    // Configure the rest of your application here:
    // create a CommandConfig with the default configuration
    var commandConfig = CommandConfig.default()
    // Add the revert command with the identifier revert.  This is the string you use to to invoke the command
    commandConfig.use(RevertCommand.self, as: "revert")
    // register the commandConfig as a service
    services.register(commandConfig)

}
