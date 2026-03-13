import SwiftUI

struct Level6View: View {
    @StateObject private var viewModel = Level6ViewModel()
    @Binding var selectedLevel: Int
    
    var body: some View {
        SharedLevelView(viewModel: viewModel, selectedLevel: $selectedLevel)
    }
}
