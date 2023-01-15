import Vapor
import Foundation
import Queues
import BSON

struct TonAccountUpdatedJob: AsyncJob {
    typealias Payload = Info

    func dequeue(_ context: QueueContext, _ payload: Info) async throws {
        guard
            let account = try await context.tonAccountService.find(payload.account),
            let balance = account.balance
        else {
            throw JobError.tonAccountNotFound
        }
        
        // TODO: fix this logic, beacuse, if +30 then -30 will be skept (think about transactions count between timeintervals)
        // if less than 0.01 TON, skip scheduling notifications
        if let prevBalance = account.prevBalance, abs(prevBalance - balance) < 10_000_000 {
            context.logger.debug("Skip notifications because small balance change")
            return
        }

        let balanceDecimal = Decimal(balance) / 1_000_000_000
        let balanceFormatted = Formatters.ton.formatSignificant(balanceDecimal)
        let shortAccountName = account.name ?? payload.account.prefix(5) + "..." + payload.account.suffix(5)
        
        let devices = context.application.mongoDB[DeviceModel.collectionName].find(
            [
                "_id": [
                    "$in": account.devices.map(\.uuidString)
                ] as Document,
                "pushToken": ["$exists": true],
                "pushToken.isEnabled": true,
                "pushToken.token": ["$exists": true]
            ],
            as: Device.self
        )

        let url = URL(string: "tonsnow://current/account/\(payload.account)")
        for try await device in devices {
            let alert = PushPayload(
                token: device.pushToken.token,
                title: "Balance updated",
                subtitle: "\(shortAccountName)",
                message: "Current balance: \(balanceFormatted)",
                url: url
            )
            try await context.queue.dispatch(SendPushJob.self, alert)
        }
    }

    func error(_ context: QueueContext, _ error: Error, _ payload: Info) async throws {
        context.logger.error("failed TonAccountUpdatedJob \(payload.account), with error: \(error)")
        return
    }
}

extension TonAccountUpdatedJob {
    struct Info: Codable {
        let account: String
    }
    
    enum JobError: Error {
        case tonAccountNotFound
    }
    
    struct Device: Decodable {
        struct PushToken: Decodable {
            let token: String
            let isEnabled: Bool
        }

        let pushToken: PushToken
    }
}
