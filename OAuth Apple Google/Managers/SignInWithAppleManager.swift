import AuthenticationServices
import CryptoKit
import Foundation

class SignInWithAppleManager:
    NSObject,
    ObservableObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {

    static let clientId = "com.flipperdevices.oleksii.PoCAuth"
    static let teamId = "SXH69675TZ"

    static let keyId = "5DU3PHCV9H"
    static var keyData: String {
        ProcessInfo.processInfo.environment["APPLE_KEY_DATA"]!
    }

    func perform() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return getRootScene()?.windows.first ?? UIWindow()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task {
            do {
                try await Self.proccessASAuthorization(authorization)
            } catch {
                print(error)
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Self.proccessErrorAuthorization(error)
    }

    static func proccessASAuthorization(_ authorization: ASAuthorization) async throws {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            let userIdentifier = appleIDCredential.user
            UserDefaults.standard.set(userIdentifier, forKey: "uuid")

            let code = String(data: appleIDCredential.authorizationCode!, encoding: .utf8)!
            let tokens = try await processGetToken(code: code)
            print("Access token \(tokens.accessToken)")
            print("Refresh token \(tokens.refreshToken)")

        case let passwordCredential as ASPasswordCredential:
            let username = passwordCredential.user
            let password = passwordCredential.password
            print("User \(username)")
            print("Password \(password)")
        default: ()
        }
    }

    static func processGetToken(code: String) async throws -> AppleTokenResponse {
        return try await getTokens(
            code: code,
            clientSecret: try getClientSecret()
        )
    }

    static func getClientSecret() throws -> String {
        let keyData = Data(base64Encoded: keyData)!
        let privateKey = try P256.Signing.PrivateKey(derRepresentation: keyData)

        let header: [String: Any] = [
            "alg": "ES256",
            "kid": Self.keyId,
            "typ": "JWT"
        ]

        let now = Date()
        let exp = now.addingTimeInterval(180 * 24 * 60 * 60) // 180 days

        let payload: [String: Any] = [
            "iss": Self.teamId,
            "iat": Int(now.timeIntervalSince1970),
            "exp": Int(exp.timeIntervalSince1970),
            "aud": "https://appleid.apple.com",
            "sub": Self.clientId
        ]

        let headerData = try JSONSerialization.data(withJSONObject: header, options: [])
        let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [])

        let headerBase64 = headerData.base64URLEncodedString()
        let payloadBase64 = payloadData.base64URLEncodedString()
        let signingInput = "\(headerBase64).\(payloadBase64)"

        let signature = try privateKey.signature(for: Data(signingInput.utf8))
        let signatureBase64 = signature.rawRepresentation.base64URLEncodedString()
        let jwt = "\(signingInput).\(signatureBase64)"
        return jwt
    }

    static func getTokens(code: String, clientSecret: String) async throws -> AppleTokenResponse {
        let url = URL(string: "https://appleid.apple.com/auth/token")!
        let body = "client_id=\(Self.clientId)&client_secret=\(clientSecret)&code=\(code)&grant_type=authorization_code"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let error = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppleError.invalidResponse(error: error)
        }

        return try JSONDecoder().decode(AppleTokenResponse.self, from: data)
    }

    static func proccessErrorAuthorization(_ error: Error) {
        print("Error \(error.localizedDescription)")
    }

    static func isAlreadySignedIn() async throws -> Bool {
        guard let uid = UserDefaults.standard.string(forKey: "uuid") else {
            return false
        }
        
        return try await ASAuthorizationAppleIDProvider()
            .credentialState(forUserID: uid) == .authorized
    }
}

enum AppleError: Error {
    case invalidResponse(error: String)
}

struct AppleTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let idToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
    }
}


extension Data {
    func base64URLEncodedString() -> String {
        var base64 = self.base64EncodedString()
        base64 = base64.replacingOccurrences(of: "+", with: "-")
        base64 = base64.replacingOccurrences(of: "/", with: "_")
        base64 = base64.replacingOccurrences(of: "=", with: "")
        return base64
    }
}
