import SwiftUI

struct SignInGoogleManual: View {
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    var body: some View {
        Button(
            action: processLogin,
            label: { Text("Sign in with Google by web") }
        )
        .frame(height: 40)
        .padding()
    }

    private func processLogin() {
        let signInWithGoogleManager = SignInWithGoogleManager()
        Task {
            do {
                let urlWithCode = try await
                    webAuthenticationSession.authenticate(
                        using: signInWithGoogleManager.authUrl!,
                        callbackURLScheme: signInWithGoogleManager.callbackUrl
                    )

                let tokens = try await signInWithGoogleManager
                    .proccessUrlResult(urlWithCode)
                print("Access Token: \(tokens.accessToken)")
                print("Refresh Token: \(tokens.refreshToken)")
            } catch {
                print(error)
            }
        }
    }
}
