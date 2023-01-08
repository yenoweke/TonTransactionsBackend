import Foundation

enum TonAPIResponse {
    struct GetInfo: Codable {
        let address: Address
        let balance: Int
        let icon: String?
        let interfaces: [String]?
        let isScam: Bool
        let lastUpdate: Int
        let memoRequired: Bool
        let name: String?
        let status: String

        enum CodingKeys: String, CodingKey {
            case address, balance, icon, interfaces
            case isScam = "is_scam"
            case lastUpdate = "last_update"
            case memoRequired = "memo_required"
            case name, status
        }
    }
    
    struct Address: Codable {
        let bounceable, nonBounceable, raw: String

        enum CodingKeys: String, CodingKey {
            case bounceable
            case nonBounceable = "non_bounceable"
            case raw
        }
    }

}
