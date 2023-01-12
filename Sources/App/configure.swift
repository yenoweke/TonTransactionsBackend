import Vapor
import APNS
import JWTKit
import QueuesMongoDriver

public func configure(_ app: Application) async throws {

//    app.logger.logLevel = .debug
    
    let mongoUser = Environment.get("TT_MONGODB_AUTH_USERNAME")!
    let mongoPassword = Environment.get("TT_MONGODB_AUTH_PASSWORD")!
    let mongoHost = Environment.get("TT_MONGODB_HOST")!
    let mongoDatabase = Environment.get("TT_MONGODB_DATABASE")!
    
    try await app.initializeMongoDB(connectionString: "mongodb://\(mongoUser):\(mongoPassword)@\(mongoHost)/\(mongoDatabase)")
    try await app.queues.setupMongo(using: app.mongoDB)
    app.queues.use(.mongodb(app.mongoDB))

    app.queues.schedule(AccountUpdatesSchedulerJob()).everySecond()

    app.queues.add(SendPushJob())
    app.queues.add(UpdateTonAccountInfoJob())
    app.queues.add(TonAccountUpdatedJob())

    app.queues.configuration.workerCount = 5
    try app.queues.startInProcessJobs(on: .default)
    try app.queues.startScheduledJobs()

    app.tonAPIFactory.use(TonAPI.init)
    app.deviceServiceFactory.use(DeviceService.init)
    app.tonAccountServiceFactory.use(TonAccountService.init)

    let pathToAPNSKey = Environment.get("TT_APNS_KEY_PATH")!
    let apnsKeyIdentifier = Environment.get("TT_APNS_KEY_IDENTIFIER")!
    let apnsTeamIdentifier = Environment.get("TT_APNS_TEAM_IDENTIFIER")!
    let apnsTopic = Environment.get("TT_APNS_TOPIC")!
    
    app.apns.configuration = try .init(
        authenticationMethod: .jwt(
            key: .private(filePath: pathToAPNSKey),
            keyIdentifier: JWKIdentifier(string: apnsKeyIdentifier),
            teamIdentifier: apnsTeamIdentifier
        ),
        topic: apnsTopic,
        environment: app.environment == .production ? .production : .sandbox
    )

    // register routes
    try routes(app)
}
