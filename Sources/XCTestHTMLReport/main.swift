import Foundation
import XCTestHTMLReportCore
import ZIPFoundation

print("XCTestHTMLReport \(version)")

var command = Command()
var help = BlockArgument("h", "", required: false, helpMessage: "Print usage and available options") {
    print(command.usage)
    exit(EXIT_SUCCESS)
}
var verbose = BlockArgument("v", "", required: false, helpMessage: "Provide additional logs") {
    Logger.verbose = true
}
var junitEnabled = false
var junit = BlockArgument("j", "junit", required: false, helpMessage: "Provide JUnit XML output") {
    junitEnabled = true
}
var includeRunDestinationInfo = true
var runDestinationInfo = BlockArgument("e", "exclude-run-destination-info", required: false, helpMessage: "Removes the run destination information from the generated junit report") {
    includeRunDestinationInfo = false
}
var result = ValueArgument(.path, "r", "resultBundlePath", required: true, allowsMultiple: true, helpMessage: "Path to a result bundle (allows multiple)")
var renderingMode = Summary.RenderingMode.linking
var inlineAssets = BlockArgument("i", "inlineAssets", required: false, helpMessage: "Inline all assets in the resulting html-file, making it heavier, but more portable") {
    renderingMode = .inline
}
var downsizeImagesEnabled = false
var downsizeImages = BlockArgument("z", "downsize-images", required: false, helpMessage: "Downsize image screenshots") {
    downsizeImagesEnabled = true
}
var deleteUnattachedFilesEnabled = false
var deleteUnattachedFiles = BlockArgument("d", "delete-unattached", required: false, helpMessage: "Delete unattached files from bundle, reducing bundle size") {
    deleteUnattachedFilesEnabled = true
}


command.arguments = [help,
                     verbose,
                     junit,
                     runDestinationInfo,
                     downsizeImages,
                     deleteUnattachedFiles,
                     result,
                     inlineAssets]

if !command.isValid {
    print(command.usage)
    exit(EXIT_FAILURE)
}

let summary = Summary(resultPaths: result.values, renderingMode: renderingMode, downsizeImagesEnabled: downsizeImagesEnabled)

Logger.step("Building HTML..")
let html = summary.generatedHtmlReport()

do {
    let root = result.values.first!
        .dropLastPathComponent()
    let path = root
        .addPathComponent("index.html")
    Logger.substep("Writing report to \(path)")

    try html.write(toFile: path, atomically: false, encoding: .utf8)
    Logger.substep("Copying dependencies to \(root)")
    let dependenciesURL = Bundle.module.url(forResource: "dependencies", withExtension: "zip")!
    try FileManager.default.unzipItem(at: dependenciesURL, to: URL(fileURLWithPath: root, isDirectory: true))
    Logger.success("\nReport successfully created at \(path)")
}
catch let e {
    Logger.error("An error has occured while creating the report. Error: \(e)")
}

if junitEnabled {
    Logger.step("Building JUnit..")
    let junitXml = summary.generatedJunitReport(includeRunDestinationInfo: includeRunDestinationInfo)
    do {
        let path = "\(result.values.first!)/report.junit"
        Logger.substep("Writing JUnit report to \(path)")

        try junitXml.write(toFile: path, atomically: false, encoding: .utf8)
        Logger.success("\nJUnit report successfully created at \(path)")
    }
    catch let e {
        Logger.error("An error has occured while creating the JUnit report. Error: \(e)")
    }
}

if deleteUnattachedFilesEnabled && renderingMode == .linking {
    summary.deleteUnattachedFiles()
}

exit(EXIT_SUCCESS)
