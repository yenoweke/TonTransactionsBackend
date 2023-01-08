import Vapor

struct DeviceWatchAccountController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes
            .grouped("device")
            .grouped(CheckSignatureMiddleware())
            .group(":deviceID") { route in
                
                route.post("watch_account", use: self.subsribe)
                route.delete("watch_account", use: self.unsubsribe)
                route.get("watch_account", use: self.list)
                
            }
    }
    
    func subsribe(req: Request) async throws -> HTTPStatus {
        guard let deviceID: UUID = req.parameters.get("deviceID") else {
            throw Abort(.notFound)
        }

        let watchAccountRequest = try req.content.decode(WatchAccount.Request.self)
        let tonAccount = try await req.tonAccountService.findOrCreate(watchAccountRequest.account)
        try await req.deviceService.attach(tonAccount: tonAccount._id, to: deviceID)
        try await req.tonAccountService.attach(deviceID: deviceID, to: tonAccount._id)
        return .ok
    }
    
    func unsubsribe(req: Request) async throws -> HTTPStatus {
        guard let deviceID: UUID = req.parameters.get("deviceID") else {
            throw Abort(.notFound)
        }
        let watchAccountRequest = try req.content.decode(WatchAccount.Request.self)
        try await req.deviceService.detach(tonAccount: watchAccountRequest.account, to: deviceID)
        try await req.tonAccountService.detach(deviceID: deviceID, to: watchAccountRequest.account)
        return .ok
    }
    
    func list(req: Request) async throws -> WatchAccount.List {
        guard
            let deviceID: UUID = req.parameters.get("deviceID"),
            let device = try await req.deviceService.info(deviceID)
        else {
            throw Abort(.notFound)
        }
        let items  = (device.subsribedOnAccounts ?? []).map(WatchAccount.List.Item.init)
        return WatchAccount.List(items: items)
    }
}

extension DeviceWatchAccountController {
    enum WatchAccount {
        struct Request: Content {
            let account: String
        }

        struct List: Content {
            struct Item: Content {
                let account: String
            }

            let items: [Item]
        }
    }

}
