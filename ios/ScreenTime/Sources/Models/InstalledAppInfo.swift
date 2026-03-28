import Foundation

struct InstalledAppInfo: Identifiable, Hashable {
    let id: String        // bundle identifier
    let name: String
    let urlScheme: String // used with canOpenURL to detect installation
    let sfSymbol: String  // SF Symbol for icon display
    let category: String
}
