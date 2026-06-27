// swift-tools-version: 5.9
import PackageDescription
import Foundation

let packageDir = URL(fileURLWithPath: #file).deletingLastPathComponent().path

let package = Package(
    name: "PS2Demo",
    targets: [
        .executableTarget(
            name: "PS2Demo",
            path: "Sources/PS2Demo",
            exclude: ["symbols"],
            swiftSettings: [
                .enableExperimentalFeature("Embedded"),
                .enableExperimentalFeature("Extern"),
                .unsafeFlags([
                    "-wmo",
                    "-Xfrontend", "-disable-reflection-metadata",
                    "-Xfrontend", "-disable-objc-interop",
                    "-Xfrontend", "-disable-stack-protector",
                ])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "--no-entry",
                    "-Xlinker", "--allow-undefined-file=\(packageDir)/Sources/PS2Demo/symbols",
                ])
            ]
        )
    ]
)
