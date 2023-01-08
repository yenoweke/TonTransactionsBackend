import Foundation
import MongoKitten
import Meow

struct DeviceModel: Model {
    @Field var _id: String
    @Field var signature: String
    @Field var pushToken: PushToken?
    @Field var subsribedOnAccounts: [String]?
    
    static func find(by identifier: UUID) -> Document {
        ["_id": identifier.uuidString]
    }
}

extension DeviceModel {
    struct PushToken: Codable {
        var token: String?
        var isEnabled: Bool
    }
}
