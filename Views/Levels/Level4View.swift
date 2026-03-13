import SwiftUI

struct Level4View: View {
    @StateObject private var viewModel = Level4ViewModel()
    @Binding var selectedLevel: Int
    
    var body: some View {
        SharedLevelView(viewModel: viewModel, selectedLevel: $selectedLevel)
    }
}
