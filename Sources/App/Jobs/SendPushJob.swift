import Vapor
import Foundation
import Queues
import APNSwift

struct PushPayload: Codable {
    let token: String
    let title: String
    let subtitle: String?
    let message: String?
    
    internal init(token: String, title: String, subtitle: String? = nil, message: String? = nil) {
        self.token = token
        self.title = title
        self.subtitle = subtitle
        self.message = message
    }

}

struct SendPushJob: AsyncJob {
    typealias Payload = PushPayload

    func dequeue(_ context: QueueContext, _ payload: Payload) async throws {
        // TODO: make batch tokens to send with same payload

        let alert = APNSwiftAlert(title: payload.title, subtitle: payload.subtitle, body: payload.message)
        return try await context.application.apns.send(alert, to: payload.token).get()
    }

    func error(_ context: QueueContext, _ error: Error, _ payload: Payload) async throws {
        // If you don't want to handle errors you can simply return a future. You can also omit this function entirely.
        context.logger.error("failed SendPushJob \(payload.subtitle ?? "")")
        context.logger.error("failed SendPushJob \(error)")
        return
    }
}
