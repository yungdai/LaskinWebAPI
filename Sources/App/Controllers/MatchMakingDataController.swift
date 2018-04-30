import Vapor
import Fluent

struct MatchMakingDataController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let matchMakingDataRoutes = router.grouped("api","matchMakingData")

        matchMakingDataRoutes.get(use: getAllHandler)
        matchMakingDataRoutes.get(MatchMakingData.parameter, use: getHandler)

        matchMakingDataRoutes.get("search", use: searchHandler)
        
        // Added to allow only authenticated users for these routes
        // use tokenAuthMiddleWare() to make sure that you're authenticated to use these routes
        let tokenAuthMiddleWare = User.tokenAuthMiddleware()
        let tokenAuthGroup = matchMakingDataRoutes.grouped(tokenAuthMiddleWare)
        
        // moving the routes for create, update, and delete down to this group
        // ensure that ONLY authenticated users can be allowed to use the routes
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.put(MatchMakingData.parameter, use: updateHandler)
        tokenAuthGroup.delete(MatchMakingData.parameter, use: deleteHandler)
    }

    // CREATE
    func createHandler(_ request: Request) throws -> Future<MatchMakingData> {
        
        return try request.content.decode(MatchMakingCreateData.self).flatMap(to: MatchMakingData.self) { data in

            // check to make sure the user is authenticated
            let user = try request.requireAuthenticated(User.self)
            
            let matchMakingData = MatchMakingData(userID: try user.requireID(), school: data.school,
                                                  city: data.city, province: data.province,
                                                  timeZone: data.timeZone, needsInterpreter: data.needsInterpreter,
                                                  interpreterType: data.interpreterType, order: data.order,
                                                  additionalNotes: data.additionalNotes)
            
            return matchMakingData.save(on: request)
        }
    }
    
    // GET ALL
    func getAllHandler(_ request: Request) throws -> Future<[MatchMakingData]> {
        return MatchMakingData.query(on: request).all()
    }
    
    // GET by api/users/#id
    func getHandler(_ request: Request) throws -> Future<MatchMakingData> {
        return try request.parameters.next(MatchMakingData.self)
    }
    
    // UPDATE
    func updateHandler(_ request: Request) throws -> Future<MatchMakingData> {
        
        // extract the users from the users from user ID at api/user/#user/userDetails/#id
        return try flatMap(to: MatchMakingData.self, request.parameters.next(MatchMakingData.self), request.content.decode(MatchMakingData.self)) { data, updatedData in
            
            // update the found user with the updated model and then save
            data.userID = try request.requireAuthenticated(User.self).requireID()
            data.school = updatedData.school
            data.city = updatedData.city
            data.province = updatedData.province
            data.timeZone = updatedData.timeZone
            data.needsInterpreter = updatedData.needsInterpreter
            data.interpreterType = updatedData.interpreterType
            data.order = updatedData.order
            data.additionalNotes = updatedData.additionalNotes

            return data.save(on: request)
        }
    }
    
    // DELETE
    func deleteHandler(_ request: Request) throws -> Future<HTTPStatus> {
        
        // extract user form address param
        return try request.parameters.next(MatchMakingData.self).flatMap(to: HTTPStatus.self) { data in
            
            return data.delete(on: request).transform(to: HTTPStatus.noContent)
        }
    }
    
    // SEARCH
    func searchHandler(_ request: Request) throws -> Future<[MatchMakingData]> {
        
        // retrieve the search term from the URL query string.  You can do this with any Codable object by calling request.query.decode(_:).  If there is a failure it will throw a 400 Bad Request Error
        guard let searchTerm = request.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        
        return try MatchMakingData.query(on: request).group(.or) { or in
            
            try or.filter(\.school == searchTerm)
            try or.filter(\.city == searchTerm)
            try or.filter(\.province == searchTerm)
            try or.filter(\.interpreterType == searchTerm)
            try or.filter(\.additionalNotes == searchTerm)
            }.all()
    }
}

struct MatchMakingCreateData: Content {
    
    let school: String
    let city: String
    let province: String
    let timeZone: Int
    let needsInterpreter: Bool
    let interpreterType: String
    let order: Int
    let additionalNotes: String
}

