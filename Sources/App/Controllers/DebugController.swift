import Vapor

struct DebugController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let debug = routes.grouped("debug")
        debug.get("device_list", use: self.deviceList)
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
            message: "xxxx",
            url: nil
        )
        try await req.queue.dispatch(SendPushJob.self, alert)
        return .ok
    }
    
    func deviceList(req: Request) async throws -> DeviceList.Response {
        let models = try await req.deviceService.all()
        let items: [DeviceList.Response.Item] = models.compactMap { deviceModel in
            UUID(uuidString: deviceModel._id).map {
                DeviceList.Response.Item(deviceID: $0, subsribedOn: deviceModel.subsribedOnAccounts ?? [])
            }
        }
        return DeviceList.Response(items: items)
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
    
    enum DeviceList {
        struct Response: Content {
            struct Item: Content {
                let deviceID: UUID
                let subsribedOn: [String]
            }
            
            let items: [Item]
        }
    }
}
