import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    
    try app.register(collection: DeviceController())
    try app.register(collection: DeviceTokenController())
    try app.register(collection: DeviceWatchAccountController())
    
    if app.environment == .development {
        try app.register(collection: DebugController())
    }
    
    
}
