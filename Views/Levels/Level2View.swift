import SwiftUI

struct Level2View: View {
    @StateObject private var viewModel = Level2ViewModel()
    @Binding var selectedLevel: Int
    
    var body: some View {
        SharedLevelView(viewModel: viewModel, selectedLevel: $selectedLevel)
    }
}
