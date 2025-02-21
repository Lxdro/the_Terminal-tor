import SwiftUI

@main
struct MyApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            @State var tmp: Int = 1
            if hasSeenOnboarding {
                //TabView()
                Level6View(selectedLevel: $tmp)
                    .preferredColorScheme(.dark)
            } else {
                OnboardingView()
            }
        }
    }
}
