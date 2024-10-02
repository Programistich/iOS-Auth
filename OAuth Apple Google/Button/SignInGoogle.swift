import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

struct SignInGoogle: View {
    var body: some View {
        GoogleSignInButton(
            scheme: .light,
            style: .wide,
            state: .normal
        ) {
            let shared =  GIDSignIn.sharedInstance
            shared.configuration = GIDConfiguration(
                clientID: SignInWithGoogleManager.clientId
            )
            shared.signIn(
                withPresenting: getRootViewController()!
            ) { signInResult, error in
                guard let user = signInResult?.user else { return }

                print("Access Token: \(user.accessToken.tokenString)")
                print("Refresh Token: \(user.refreshToken.tokenString)")
              }
        }
        .frame(height: 40)
        .padding()
    }
}

#Preview {
    let allScheme = GoogleSignInButtonColorScheme.allCases
    let allStyles = GoogleSignInButtonStyle.allCases
    let allState = GoogleSignInButtonState.allCases

    var allPairs: [GoogleSignInDesign] {
            allScheme.flatMap { scheme in
                allStyles.flatMap { style in
                    allState.map { state in
                        GoogleSignInDesign(
                            scheme: scheme,
                            style: style,
                            state: state
                        )
                    }
                }
            }
        }

    List(allPairs, id: \.self) { pair in
        GoogleSignInButton(
            scheme: pair.scheme,
            style: pair.style,
            state: pair.state
        ){}
    }
}

struct GoogleSignInDesign: Hashable {
    let scheme: GoogleSignInButtonColorScheme
    let style: GoogleSignInButtonStyle
    let state: GoogleSignInButtonState
}
