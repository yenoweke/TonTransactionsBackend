import Vapor

struct DebugController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let debug = routes.grouped("debug")
        debug.post("update_account", use: self.updateAccount)
        
        debug.group(":deviceID") { route in
            route.get("push", use: self.push)
        }
    }
    
    func push(req: Request) async throws -> HTTPStatus {
        guard
            let deviceID: UUID = req.parameters.get("deviceID"),
            let token = try await req.deviceService.info(deviceID)?.pushToken?.token
        else {
            throw Abort(.notFound)
        }
        
        let alert = PushPayload(
            token: token,
            title: "AONTHER One message",
            message: "xxxx"
        )
        try await req.queue.dispatch(SendPushJob.self, alert)
        return .ok
    }
    
    func updateAccount(req: Request) async throws -> HTTPStatus {
        let content = try req.content.decode(UpdateAccount.Request.self)
        
        let scheduleID = UUID()
        try await req.mongoDB[TonAccountModel.collectionName].updateOne(
            where: ["_id": content.account],
            to: [
                "$set": ["lastScheduleID": scheduleID.uuidString]
            ]
        )
        
        try await req.queue.dispatch(
            UpdateTonAccountInfoJob.self,
            .init(
                account: content.account,
                scheduleID: scheduleID
            )
        )
        return .ok
    }
}

extension DebugController {
    enum UpdateAccount {
        struct Request: Content {
            let account: String
        }
    }
}
