import SwiftUI

@main
struct MyApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            @State var tmp: Int = 2
            if hasSeenOnboarding {
                //TabView()
                Level5View(selectedLevel: $tmp)
                    .preferredColorScheme(.dark)
            } else {
                OnboardingView()
            }
        }
    }
}
