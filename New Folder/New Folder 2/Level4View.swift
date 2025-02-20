import SwiftUI

struct Level4View: View {
    @Binding var selectedLevel: Int
    @State private var showCompletion = false
    
    var body: some View {
        VStack {
            // Your level content here
            
            Button("Complete Level") {
                showCompletion = true
            }
        }
        .sheet(isPresented: $showCompletion) {
            LevelCompletionView(selectedLevel: $selectedLevel)
        }
    }
}
