import SwiftUI

struct Level3View: View {
    @StateObject private var viewModel = Level3ViewModel()
    @Binding var selectedLevel: Int
    
    var body: some View {
        SharedLevelView(viewModel: viewModel, selectedLevel: $selectedLevel)
    }
}
