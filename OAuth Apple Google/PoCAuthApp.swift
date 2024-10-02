import SwiftUI

@main
struct PoCAuthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 20) {
                SignInApple()
                SignInAppleCustom()
                SignInGoogle()
                SignInGoogleManual()
            }
        }
    }
}

func getRootScene() -> UIWindowScene? {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    else { return nil }
    return windowScene
}

func getRootViewController() -> UIViewController? {
    guard let windowScene = getRootScene(), let viewController = windowScene.windows.first?.rootViewController
    else { return nil }
    return viewController
}
