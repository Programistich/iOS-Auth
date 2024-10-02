import SwiftUI

struct SignInAppleCustom: View {
    @StateObject var signInWithAppleManager = SignInWithAppleManager()

    var body: some View {
        Button(
            action: signInWithAppleManager.perform,
            label: { Text("Sign In with Apple Custom") }
        )
        .frame(height: 40)
        .padding()
    }
}
