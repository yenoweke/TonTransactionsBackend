import Meow
import Foundation

struct TonAccountModel: Model {
    @Field var _id: String
    @Field var name: String?
    @Field var lastUpdate: Int?
    @Field var balance: Int?
    @Field var prevBalance: Int?
    @Field var lastScheduledDate: Date
    @Field var lastScheduleID: UUID?
    @Field var devices: [UUID]

    // @Timestamp(key: "created_at", on: .create, format: .unix)
    // var createdAt: Date?

    // @Timestamp(key: "updated_at", on: .update, format: .unix)
    // var updatedAt: Date?
}
