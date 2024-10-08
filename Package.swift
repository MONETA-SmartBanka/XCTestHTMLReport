// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "XCTestHTMLReport",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "xchtmlreport", targets: ["XCTestHTMLReport"]),
        .library(name: "xchtmlreportcore", targets: ["XCTestHTMLReportCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Rainbow.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/tylervick/XCResultKit.git", revision: "6a16ad01ed9c694becd3d361e1ca992674368b83"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.4.3"),
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.15")
    ],
    targets: [
        .executableTarget(
            name: "XCTestHTMLReport",
            dependencies: ["XCTestHTMLReportCore", "ZIPFoundation"],
            resources: [
                .copy("dependencies.zip")
            ]
        ),
        .target(
            name: "XCTestHTMLReportCore",
            dependencies: ["Rainbow", "XCResultKit"],
            exclude: ["HTML"]), // ignore HTML directory resources. They are already imported as static strings.
        .testTarget(
            name: "XCTestHTMLReportTests",
            dependencies: ["XCTestHTMLReport", "SwiftSoup"],
            resources: [
                .process("Resources/TestResults.xcresult"),
                .process("Resources/RetryResults.xcresult"),
                .process("Resources/SanityResults.xcresult"),
            ]
        )
    ]
)
