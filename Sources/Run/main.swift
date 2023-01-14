import App
import Vapor
import Foundation

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
let semaphor = DispatchSemaphore(value: 0)
Task {
    try await configure(app)
    semaphor.signal()
}
semaphor.wait()

try app.run()
