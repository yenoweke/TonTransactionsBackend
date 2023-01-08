import Vapor
import Meow

private enum CustomHeaders {
    static let signature = "X-TT-Signature"
}

struct CheckSignatureMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let id: Reference<DeviceModel> = try request.parameters.require("deviceID")
        let device = try await id.resolve(in: request.meow)
        if let signature = request.headers.first(name: CustomHeaders.signature), device.signature == signature {
            return try await next.respond(to: request)
        }
        throw Abort(.forbidden)
    }
}
