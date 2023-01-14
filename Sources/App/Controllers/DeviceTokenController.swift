import Vapor

struct DeviceTokenController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes
            .grouped("device")
            .grouped(CheckSignatureMiddleware())
            .group(":deviceID") { route in
                route.post("push_token", use: self.subscribe)
                route.post("push_disabled", use: self.pushDisabled)
            }
    }
    

    func subscribe(req: Request) async throws -> HTTPStatus {
        guard let deviceID: UUID = req.parameters.get("deviceID") else {
            throw Abort(.notFound)
        }

        let request = try req.content.decode(Subscribe.Request.self)
        try await req.deviceService.updatePushToken(
            for: deviceID,
            pushToken: request.token
        )
        return .ok
    }
    
    func pushDisabled(req: Request) async throws -> HTTPStatus {
        guard let deviceID: UUID = req.parameters.get("deviceID") else {
            throw Abort(.notFound)
        }
        try await req.deviceService.disablePushToken(for: deviceID)
        return .ok
    }
}

extension DeviceTokenController {
    enum Subscribe {
        struct Request: Content {
            let token: String
        }
    }
}
