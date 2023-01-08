import Vapor
import Foundation
import Queues
import BSON

struct UpdateTonAccountInfoJob: AsyncJob {
    static let encoder = BSONEncoder()
    
    typealias Payload = PayloadData

    func dequeue(_ context: QueueContext, _ payload: PayloadData) async throws {
        guard let account = try await context.tonAccountService.find(payload.account) else {
            throw JobError.tonAccountNotFound
        }
        
        guard account.lastScheduleID == payload.scheduleID else {
            context.logger.info("SKIP BECAUSE OF DIFFERENT sheduleID: \(payload.scheduleID)")
            return
        }
        
        let response: TonAPIResponse.GetInfo = try await context.tonAPI.getInfo(payload.account)
    
        if account.lastUpdate == response.lastUpdate { return }
        
        let update = TonAccountModelUpdate(
            name: response.name,
            lastUpdate: response.lastUpdate,
            balance: response.balance,
            prevBalance: account.balance
        )
        
        let encoded = try Self.encoder.encode(update)
        try await context.application.mongoDB[TonAccountModel.collectionName].updateOne(
            where: ["_id": account._id],
            to: [
                "$set": encoded
            ]
        )
        
        try await context.queue.dispatch(
            TonAccountUpdatedJob.self,
            .init(account: account._id)
        )
    }

    func error(_ context: QueueContext, _ error: Error, _ payload: PayloadData) async throws {
        context.logger.error("failed UpdateTonAccountInfoJob \(payload.account), with error: \(error)")
        return
    }
}

extension UpdateTonAccountInfoJob {
    struct PayloadData: Codable {
        let account: String
        let scheduleID: UUID
    }
    
    enum JobError: Error {
        case tonAccountNotFound
    }
    
    struct TonAccountModelUpdate: Encodable {
        let name: String?
        let lastUpdate: Int
        let balance: Int
        let prevBalance: Int?
    }
}
