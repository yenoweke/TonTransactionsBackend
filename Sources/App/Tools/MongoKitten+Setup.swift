import Foundation
import Vapor
import MongoKitten
import Meow

extension Request {
    public var mongoDB: MongoDatabase {
        return application.mongoDB
    }
    
    public var meow: MeowDatabase {
        return MeowDatabase(mongoDB)
    }
    
    public func meow<M: ReadableModel>(_ type: M.Type) -> MeowCollection<M> {
        return meow[type]
    }
}

private struct MongoDBStorageKey: StorageKey {
    typealias Value = MongoDatabase
}

extension Application {
    public var mongoDB: MongoDatabase {
        get {
            storage[MongoDBStorageKey.self]!
        }
        set {
            storage[MongoDBStorageKey.self] = newValue
        }
    }

    public var meow: MeowDatabase {
        MeowDatabase(mongoDB)
    }
    
    public func initializeMongoDB(connectionString: String) async throws {
        var connectionSettings = try ConnectionSettings(connectionString)
        connectionSettings.authenticationSource = "admin"
        self.mongoDB = try await MongoDatabase.connect(to: connectionSettings)
    }
}
