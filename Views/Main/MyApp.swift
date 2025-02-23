import SwiftUI

@main
struct MyApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    init() {
        registerCustomFont()
    }

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                TabView()
                    .preferredColorScheme(.dark)
                    .statusBarHidden(true)
            } else {
                OnboardingView()
                    .preferredColorScheme(.dark)
                    .statusBarHidden(true)
            }
        }
    }

    func registerCustomFont() {
        guard let fontURL = Bundle.main.url(forResource: "Glass_TTY_VT220", withExtension: "ttf") else {
            print("Font file not found")
            return
        }

        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
            print("Failed to register font: \(error?.takeRetainedValue().localizedDescription ?? "Unknown error")")
        }
    }
}

