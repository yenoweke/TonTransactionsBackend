import Vapor
import Meow
import Queues

struct TonAPI {
    struct Context {
        let db: MeowDatabase
        let client: Client
        let token: String = Environment.get("TT_TON_API_KEY")!
    }

    private let token: String
    
    private let baseUrl = "https://tonapi.io"
    private let db: MeowDatabase
    private let client: Client
    private let logger = Logger(label: "ton.transcations.TonAPI")
    
    init(context: Context) {
        self.db = context.db
        self.client = context.client
        self.token = context.token
    }
    
    func getAccount(_ account: String) async throws -> GetAccountResponse {
        let uri = URI(string: baseUrl + "/v1/blockchain/getAccount?account=" + account)
        let response = try await client.get(uri, beforeSend: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: token)
        })
        return try response.content.decode(GetAccountResponse.self)
    }

    func getInfo(_ account: String) async throws -> TonAPIResponse.GetInfo {
        let uri = URI(string: baseUrl + "/v1/account/getInfo?account=" + account)
        let response = try await client.get(uri, beforeSend: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: token)
        })
        return try response.content.decode(TonAPIResponse.GetInfo.self)
    }
}

extension TonAPI {
    struct GetAccountResponse: Content {
        let balance: Int
        let status: String
    }
}

struct TonAPIFactory {
    var make: ((TonAPI.Context) -> TonAPI)?

    mutating func use(_ make: @escaping ((TonAPI.Context) -> TonAPI)) {
        self.make = make
    }
}

extension Application {
    private struct TonAPIFactoryKey: StorageKey {
        typealias Value = TonAPIFactory
    }

    var tonAPIFactory: TonAPIFactory {
        get {
            self.storage[TonAPIFactoryKey.self] ?? .init()
        }
        set {
            self.storage[TonAPIFactoryKey.self] = newValue
        }
    }

//    var tonAPI: TonAPI {
//        self.tonAPIFactory.make!(.init(db: self.db, client: self.client, eventLoop: self.eventLoop))
//    }
}

extension QueueContext {
    var tonAPI: TonAPI {
        self.application.tonAPIFactory.make!(.init(db: self.application.meow, client: self.application.client))
    }
}

extension Request {
    var tonAPI: TonAPI {
        self.application.tonAPIFactory.make!(.init(db: self.meow, client: self.client))
    }
}
