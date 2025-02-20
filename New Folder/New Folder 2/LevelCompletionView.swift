import SwiftUI

struct LevelCompletionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLevel: Int
    
    @State private var trigger: Int = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                TTYColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    ZStack {
                        PlayerView()
                            .ignoresSafeArea()
                            .edgesIgnoringSafeArea(.all)
                            .offset(y: 10)
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.black.opacity(0.6))
                                .offset(y: 10)
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.green, lineWidth: 2)
                                .fill(.ultraThinMaterial)
                                .offset(y: 10)
                            
                            VStack(spacing: 20) {
                                Text("LEVEL \(selectedLevel) COMPLETE")
                                    .font(.custom("Glass_TTY_VT220", size: 24))
                                    .foregroundColor(TTYColors.text)
                                    .padding(.top, 30)
                                
                                HStack(spacing: 15) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 32))
                                        .shadow(color: .green, radius: 3, x: 0, y: 0)
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 32))
                                        .shadow(color: .green, radius: 3, x: 0, y: 0)
                                    Image(systemName: "star")
                                        .foregroundColor(.green)
                                        .font(.system(size: 32))
                                        .shadow(color: .green, radius: 3, x: 0, y: 0)
                                }
                                
                                VStack(spacing: 10) {
                                    Text("Good job!")
                                        .font(.custom("Glass_TTY_VT220", size: 20))
                                        .foregroundColor(TTYColors.text)
                                    
                                    Text("you can try to get better stats")
                                        .font(.custom("Glass_TTY_VT220", size: 20))
                                        .foregroundColor(TTYColors.text)
                                    
                                    Text("or proceed to the next challenge.")
                                        .font(.custom("Glass_TTY_VT220", size: 20))
                                        .foregroundColor(TTYColors.text)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding()
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("STATUS: OK")
                            .foregroundColor(TTYColors.text)
                        Text("COMMAND COUNT: 2 - (Best: )")
                            .foregroundColor(TTYColors.text)
                        Text("TIME: \(String(format: "%.2f", Double.random(in: 0.1...0.5)))s - (Best: )")
                            .foregroundColor(TTYColors.text)
                    }
                    .font(.custom("Glass_TTY_VT220", size: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(30)
                    
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("RESTART")
                                .font(.custom("Glass_TTY_VT220", size: 18))
                                .foregroundColor(TTYColors.background)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(TTYColors.text)
                                .cornerRadius(5)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if selectedLevel < 6 {
                                selectedLevel += 1
                            }
                            dismiss()
                        }) {
                            Text("NEXT LEVEL >")
                                .font(.custom("Glass_TTY_VT220", size: 18))
                                .foregroundColor(TTYColors.background)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(TTYColors.text)
                                .cornerRadius(5)
                        }
                        .disabled(selectedLevel >= 6)
                        .opacity(selectedLevel >= 6 ? 0.5 : 1)
                    }
                    .padding(30)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("EXIT") {
                        dismiss()
                    }
                    .font(.custom("Glass_TTY_VT220", size: 16))
                    .foregroundColor(TTYColors.text)
                }
            }
            .onAppear() {
                trigger += 1
            }
            .confettiCannon(trigger: $trigger, num: 40, colors: [.blue, .red, .yellow, .pink, .purple, .orange])
        }
    }
}
