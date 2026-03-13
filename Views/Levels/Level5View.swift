import SwiftUI

struct Level5View: View {
    @StateObject private var viewModel = Level5ViewModel()
    @Binding var selectedLevel: Int
    
    var body: some View {
        SharedLevelView(viewModel: viewModel, selectedLevel: $selectedLevel)
    }
}
