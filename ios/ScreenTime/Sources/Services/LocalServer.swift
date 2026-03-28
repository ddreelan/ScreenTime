import Foundation
import Network

/// A lightweight local HTTP server that listens on localhost:48291
/// so Shortcuts can trigger tracking via a background network request
/// without bringing the ScreenTime app to the foreground.
class LocalServer {
    static let shared = LocalServer()
    static let port: UInt16 = 48291

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "LocalServer", qos: .background)

    private init() {}

    func start() {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        guard let listener = try? NWListener(using: params, on: NWEndpoint.Port(rawValue: LocalServer.port)!) else {
            return
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener.start(queue: queue)
        self.listener = listener
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, _ in
            guard let data = data, let request = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            self?.processRequest(request, connection: connection)
        }
    }

    private func processRequest(_ request: String, connection: NWConnection) {
        // Parse the first line e.g. "GET /startApp?bundleID=com.google.ios.youtube HTTP/1.1"
        let firstLine = request.components(separatedBy: "\r\n").first ?? ""
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            respond(connection: connection, status: "400 Bad Request", body: "Bad request")
            return
        }

        let path = parts[1] // e.g. "/startApp?bundleID=com.google.ios.youtube"

        // Parse path and query
        guard let urlComponents = URLComponents(string: "http://localhost\(path)") else {
            respond(connection: connection, status: "400 Bad Request", body: "Invalid path")
            return
        }

        let endpoint = urlComponents.path
        let bundleID = urlComponents.queryItems?.first(where: { $0.name == "bundleID" })?.value

        DispatchQueue.main.async {
            switch endpoint {
            case "/startApp":
                if let bundleID = bundleID {
                    ScreenTimeService.shared.setActiveApp(bundleID: bundleID)
                    if !ScreenTimeService.shared.isTracking {
                        ScreenTimeService.shared.startTracking()
                    }
                }
            case "/stopApp":
                ScreenTimeService.shared.setActiveApp(bundleID: nil)
            default:
                break
            }
        }

        respond(connection: connection, status: "200 OK", body: "OK")
    }

    private func respond(connection: NWConnection, status: String, body: String) {
        let response = "HTTP/1.1 \(status)\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
        let data = Data(response.utf8)
        connection.send(content: data, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
