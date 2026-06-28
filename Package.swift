// swift-tools-version: 5.9
import PackageDescription
import Foundation

let packageDir = URL(fileURLWithPath: #file).deletingLastPathComponent().path
let vendor = "\(packageDir)/Sources/CPS2/vendor"

let package = Package(
    name: "PS2Demo",
    targets: [
        .target(
            name: "CPS2",
            path: "Sources/CPS2",
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags([
                    "-D_EE",
                    "-I\(vendor)/gsKit",
                    "-I\(vendor)/ps2sdk/common",
                    "-idirafter", "\(vendor)/ps2sdk/ee",
                ])
            ]
        ),
        .executableTarget(
            name: "PS2Demo",
            dependencies: ["CPS2"],
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
                    "-Xcc", "-D_EE",
                    "-Xcc", "-I\(vendor)/gsKit",
                    "-Xcc", "-I\(vendor)/ps2sdk/common",
                    "-Xcc", "-idirafter", "-Xcc", "\(vendor)/ps2sdk/ee",
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
