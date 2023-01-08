import Vapor
import Meow
import Queues

struct TonAccountService {
    struct Context {
        let meow: MeowDatabase
        let mongo: MongoDatabase
    }
    
    private let meow: MeowDatabase
    private let mongo: MongoDatabase
    private let logger = Logger(label: "ton.transcations.TonAccountService")
    
    private var tonAccounts: MeowCollection<TonAccountModel> {
        meow[TonAccountModel.self]
    }
    
    init(context: Context) {
        self.meow = context.meow
        self.mongo = context.mongo
    }
    
    func findOrCreate(_ id: String) async throws -> TonAccountModel {
        if let existing = try await find(id) {
            return existing
        }
        return try await create(id)
    }
    
    func find(_ id: String) async throws -> TonAccountModel? {
        try await tonAccounts.findOne(matching: { $0.$_id == id })
    }
    
    func create(_ id: String) async throws -> TonAccountModel {
        let tonAccount = TonAccountModel(_id: id, lastScheduledDate: Date(timeIntervalSince1970: 0), devices: [])
        try await self.tonAccounts.insert(tonAccount)
        return tonAccount
    }
    
    func attach(deviceID: UUID, to id: String) async throws {
        try await self.mongo[TonAccountModel.collectionName].updateOne(
            where: ["_id": id],
            to: [
                "$addToSet": [
                    "devices": deviceID.uuidString
                ]
            ]
        )
    }
    
    func detach(deviceID: UUID, to id: String) async throws {
        try await self.mongo[TonAccountModel.collectionName].updateOne(
            where: ["_id": id],
            to: [
                "$pull": [
                    "devices": deviceID.uuidString
                ]
            ]
        )
    }
}

struct TonAccountServiceFactory {
    var make: ((TonAccountService.Context) -> TonAccountService)?

    mutating func use(_ make: @escaping ((TonAccountService.Context) -> TonAccountService)) {
        self.make = make
    }
}

extension Application {
    private struct TonAccountServiceFactoryKey: StorageKey {
        typealias Value = TonAccountServiceFactory
    }

    var tonAccountServiceFactory: TonAccountServiceFactory {
        get {
            self.storage[TonAccountServiceFactoryKey.self] ?? .init()
        }
        set {
            self.storage[TonAccountServiceFactoryKey.self] = newValue
        }
    }
}

extension QueueContext {
    var tonAccountService: TonAccountService {
        self.application.tonAccountServiceFactory.make!(.init(meow: self.application.meow, mongo: self.application.mongoDB))
    }
}

extension Request {
    var tonAccountService: TonAccountService {
        self.application.tonAccountServiceFactory.make!(.init(meow: self.meow, mongo: self.mongoDB))
    }
}
