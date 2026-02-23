// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LeaveWorkReminder",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "LeaveWorkReminder",
            path: "LeaveWorkReminder",
            exclude: ["App/Info.plist"]
        ),
        .testTarget(
            name: "LeaveWorkReminderTests",
            dependencies: ["LeaveWorkReminder"],
            path: "LeaveWorkReminderTests"
        )
    ]
)
