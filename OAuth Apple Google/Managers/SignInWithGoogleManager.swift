import Foundation
import CommonCrypto
import GoogleSignIn
import GoogleSignInSwift

class SignInWithGoogleManager {
    static let clientId = "1048024315407-igb4dfom1tjkmi28d6am74ok7vubg88s.apps.googleusercontent.com"
    let callbackUrl = "com.googleusercontent.apps.1048024315407-igb4dfom1tjkmi28d6am74ok7vubg88s"
    private var redirectUrl: String { callbackUrl + "://" }
    private let scopes = "profile"

    private let codeVerifier: String

    init() {
        self.codeVerifier = Self.generateCodeVerifier()
    }

    var authUrl: URL? {
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        return URL(string:
            "https://accounts.google.com/o/oauth2/v2/auth" +
            "?client_id=\(Self.clientId)" +
            "&redirect_uri=\(redirectUrl)" +
            "&response_type=code" +
            "&scope=\(scopes)" +
            "&code_challenge=\(codeChallenge)" +
            "&code_challenge_method=S256" +
            "&prompt=consent"
        )
    }

    func proccessUrlResult(_ url: URL) async throws -> GoogleTokenResponse {
        let queryItems = URLComponents(string: url.absoluteString)?.queryItems
        let code = queryItems?.filter({ $0.name == "code" }).first?.value

        let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = getBody(code: code!).data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let error = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoogleError.invalidResponse(error: error)
        }

        return try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
    }

    private func getBody(code: String) -> String {
        "client_id=\(Self.clientId)&" +
        "code=\(code)&" +
        "grant_type=authorization_code&" +
        "code_verifier=\(codeVerifier)&" +
        "redirect_uri=\(redirectUrl)"
    }

    private static func generateCodeVerifier() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<128).map { _ in characters.randomElement()! })
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }

        var sha256 = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &sha256)
        }

        let hashData = Data(sha256)
        return hashData.base64EncodedString().replacingOccurrences(of: "+", with: "-")
                                              .replacingOccurrences(of: "/", with: "_")
                                              .replacingOccurrences(of: "=", with: "")
    }

    static func isAlreadySignedIn() async throws -> Bool {
        // try await GIDSignIn.sharedInstance.restorePreviousSignIn()
        return true
    }
}

enum GoogleError: Error {
    case invalidResponse(error: String)
}

struct GoogleTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expires_in: Int
    let token_type: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expires_in = "expires_in"
        case token_type = "token_type"
    }
}
