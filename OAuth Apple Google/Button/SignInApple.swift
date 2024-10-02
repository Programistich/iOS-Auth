import AuthenticationServices
import Foundation
import SwiftUI

struct SignInApple: View {
    var body: some View {
        ZStack {
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        Task {
                            do {
                                try await SignInWithAppleManager.proccessASAuthorization(authorization)
                            } catch {
                                print(error)
                            }
                        }
                    case .failure(let error):
                        SignInWithAppleManager
                            .proccessErrorAuthorization(error)
                    }
                }
            )
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 40)
            .padding()
        }
    }
}

#Preview {
    VStack {
        SignInWithAppleButton(
            .signIn,
            onRequest: { _ in },
            onCompletion: { _ in })
        .frame(height: 40)
        .signInWithAppleButtonStyle(.whiteOutline)
        SignInWithAppleButton(
            .continue,
            onRequest: { _ in },
            onCompletion: { _ in })
        .frame(height: 40)
        .signInWithAppleButtonStyle(.whiteOutline)
        SignInWithAppleButton(
            .signUp,
            onRequest: { _ in},
            onCompletion: { _ in })
        .frame(height: 40)
        .signInWithAppleButtonStyle(.whiteOutline)

        SignInWithAppleButton(
            .signIn,
            onRequest: { _ in },
            onCompletion: { _ in })
        .frame(height: 40)
        .signInWithAppleButtonStyle(.white)
        SignInWithAppleButton(
            .continue,
            onRequest: { _ in },
            onCompletion: { _ in })
        .frame(height: 40)
        .signInWithAppleButtonStyle(.white)
        SignInWithAppleButton(
            .signUp,
            onRequest: { _ in},
            onCompletion: { _ in })
        .frame(height: 40)
        .signInWithAppleButtonStyle(.white)

        SignInWithAppleButton(
            .signIn,
            onRequest: { _ in },
            onCompletion: { _ in })
        .frame(height: 40)
        .signInWithAppleButtonStyle(.black)
        SignInWithAppleButton(
            .continue,
            onRequest: { _ in },
            onCompletion: { _ in })
        .frame(height: 40)
        .signInWithAppleButtonStyle(.black)
        SignInWithAppleButton(
            .signUp,
            onRequest: { _ in},
            onCompletion: { _ in })
        .frame(height: 40)
        .signInWithAppleButtonStyle(.black)
    }
    .padding()
}
