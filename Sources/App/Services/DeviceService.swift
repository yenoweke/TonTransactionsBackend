import Vapor
import Meow

struct DeviceService {
    struct Context {
        let meow: MeowDatabase
        let mongo: MongoDatabase
    }
    private let encoder = BSONEncoder()
    private let meow: MeowDatabase
    private let mongo: MongoDatabase
    private let logger = Logger(label: "ton.transcations.DeviceService")
    
    private var devices: MeowCollection<DeviceModel> {
        meow[DeviceModel.self]
    }

    init(context: Context) {
        self.meow = context.meow
        self.mongo = context.mongo
    }
    
    func all() async throws -> [DeviceModel] {
        let devices = try await self.devices.find().drain()
        return devices
    }
    
    func create(deviceID: UUID, signature: String) async throws {
        let reference = Reference<DeviceModel>(unsafeTo: deviceID.uuidString)
        if try await reference.exists(in: self.meow) {
            if let resolved = try await reference.resolveIfPresent(in: self.meow), resolved.signature == signature {
                return
            }
            throw Abort(.badRequest)
        }
        let device = DeviceModel(_id: deviceID.uuidString, signature: signature)
        try await self.devices.insert(device)
    }

    func info(_ deviceID: UUID) async throws -> DeviceModel? {
        let device = try await self.devices.findOne(matching: { (query: QueryMatcher<DeviceModel>) in
            query.$_id == deviceID.uuidString
        })
        return device
    }
    
    func exist(_ deviceID: UUID) async throws -> Bool {
        let count = try await self.devices.count(matching: { (query: QueryMatcher<DeviceModel>) in
            query.$_id == deviceID.uuidString
        })
        return count == 1
    }

    func attach(tonAccount: String, to deviceID: UUID) async throws {
        let reply = try await self.mongo[DeviceModel.collectionName].updateOne(
            where: [
                "_id": deviceID.uuidString,
                "subsribedOnAccounts.4": [
                    "$exists": false
                ] as Document
            ] as Document,
            to: [
                "$addToSet": [
                    "subsribedOnAccounts": tonAccount
                ]
            ]
        )

        self.logger.debug("\(reply)")
        if reply.updatedCount == 0 {
            throw Abort(.notAcceptable)
        }
    }
    
    func detach(tonAccount: String, to deviceID: UUID) async throws {
        try await self.mongo[DeviceModel.collectionName].updateOne(
            where: DeviceModel.find(by: deviceID),
            to: [
                "$pull": [
                    "subsribedOnAccounts": tonAccount
                ]
            ]
        )
    }
    
    func updatePushToken(for deviceID: UUID, pushToken: String) async throws -> DeviceModel {
        let pushToken = DeviceModel.PushToken(token: pushToken, isEnabled: true)
        let pushTokenEncoded = try BSONEncoder().encode(pushToken)
        
        let model = try await self.mongo[DeviceModel.collectionName].findOneAndUpdate(
            where: DeviceModel.find(by: deviceID),
            to: [
                "$set": [
                    "pushToken": pushTokenEncoded
                ]
            ],
            returnValue: .modified
        ).decode(DeviceModel.self)

        if let model = model {
            return model
        }
        else {
            throw Abort(.badRequest)
        }
    }

    func delete(_ deviceID: UUID) async throws {
//        let model = try await DeviceModel.find(deviceID, on: self.db)
//        try await model?.delete(on: self.db)
    }
}

extension DeviceService {
    struct GetAccountResponse: Content {
        let balance: Int
        let status: String
    }
}

struct DeviceServiceFactory {
    var make: ((DeviceService.Context) -> DeviceService)?

    mutating func use(_ make: @escaping ((DeviceService.Context) -> DeviceService)) {
        self.make = make
    }
}

extension Application {
    private struct DeviceServiceFactoryKey: StorageKey {
        typealias Value = DeviceServiceFactory
    }

    var deviceServiceFactory: DeviceServiceFactory {
        get {
            self.storage[DeviceServiceFactoryKey.self] ?? .init()
        }
        set {
            self.storage[DeviceServiceFactoryKey.self] = newValue
        }
    }
}

//extension QueueContext {
//    var deviceService: DeviceService {
//        self.application.deviceServiceFactory.make!(.init(db: self.application.db, eventLoop: self.eventLoop))
//    }
//}

extension Request {
    var deviceService: DeviceService {
        self.application.deviceServiceFactory.make!(.init(meow: self.meow, mongo: self.mongoDB))
    }
}
