import SwiftUI

struct Level1View: View {
    @StateObject private var viewModel = Level1ViewModel()
    @Binding var selectedLevel: Int
    
    var body: some View {
        SharedLevelView(viewModel: viewModel, selectedLevel: $selectedLevel)
    }
}
