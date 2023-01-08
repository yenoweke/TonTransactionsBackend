import Vapor

struct DeviceController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let device = routes.grouped("device")
        device.post("create", use: self.create)
        device.grouped(CheckSignatureMiddleware()).group(":deviceID") { route in
            route.get(use: self.deviceInfo)
        }
    }
    
    func create(req: Request) async throws -> HTTPStatus {
        let content = try req.content.decode(Create.Request.self)
        try await req.deviceService.create(
            deviceID: content.deviceID,
            signature: content.signature
        )
        return .created
    }

    func deviceInfo(req: Request) async throws -> DeviceInfo.Item {
        guard
            let deviceID: UUID = req.parameters.get("deviceID"),
            let deviceModel = try await req.deviceService.info(deviceID)
        else {
            throw Abort(.notFound)
        }

        return try DeviceInfo.Item(model: deviceModel)
    }
}

extension DeviceController {
    enum Create {
        struct Request: Content {
            let deviceID: UUID
            let signature: String
        }
    }
    enum DeviceInfo {
        struct Item: Content {
            let id: UUID
            let subsribedOn: [String]

            init(model: DeviceModel) throws {
                if let uuid = UUID(uuidString: model._id){
                    self.id = uuid
                }
                else {
                    throw Abort(.internalServerError, reason: "Device Id is not UUID")
                }
                self.subsribedOn = model.subsribedOnAccounts ?? []
            }
        }
    }
    
    enum List {
        struct Response: Content {
            let items: [DeviceInfo.Item]
        }
    }
}
