import Vapor
import Queues
import BSON

struct AccountUpdatesSchedulerJob: AsyncScheduledJob {

    func run(context: QueueContext) async throws {
        let date = Date(timeIntervalSinceNow: -60)
        
        let accounts = try await context.application.mongoDB[TonAccountModel.collectionName].find(
            [
                "lastScheduledDate": [
                    "$lte": date
                ]
            ])
            .sort(["lastScheduledDate": 1])
            .project(["_id": 1, "balance": 1])
            .limit(5)
            .decode(TonAccount.self)
            .drain()

        let scheduleID = UUID()
        let accountsToUpdate: [String] = accounts.map(\._id)

        try await context.application.mongoDB[TonAccountModel.collectionName].updateMany(
            where: [
                "_id": ["$in": accountsToUpdate]
            ],
            to: [
                "$set": [
                    "lastScheduledDate": Date(),
                    "lastScheduleID": scheduleID.uuidString
                ] as Document
            ]
        )

        for account in accounts {
            context.logger.debug("scheduled UpdateTonAccountInfoJob \(account._id)")
            try await context.queue.dispatch(
                UpdateTonAccountInfoJob.self,
                .init(account: account._id, scheduleID: scheduleID)
            )
        }
    }
}

extension AccountUpdatesSchedulerJob {
    struct TonAccount: Decodable {
        let _id: String
        let balance: Int?
    }
}
