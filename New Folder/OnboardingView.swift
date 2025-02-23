import SwiftUI
import AVKit

struct OnboardingView: View {
    @State private var username: String = ""
    @State private var startCommand: String = ""
    @State private var errorMessage: String? = nil
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    private func containerWidth(_ geometry: GeometryProxy) -> CGFloat {
        let baseWidth = min(geometry.size.width - 80, 500)
        return baseWidth
    }
    
    private func validateUsername() -> Bool {
        if username.isEmpty {
            errorMessage = "Trying to be mysterious, are we? Still, we need a name to start!"
            return false
        }
        if username.count > 12 {
            errorMessage = "Whoa! That's a novel, not a username. Keep it under 12 characters, please."
            return false
        }
        if !username.allSatisfy({ $0.isASCII }) {
            errorMessage = "Hold on, is that an emoji? Only ASCII characters allowed!"
            return false
        }
        return true
    }
    
    private func validateStartCommand() -> Bool {
        let validStartCommands = ["Start", "start", "'Start'"]
        if !validStartCommands.contains(startCommand) {
            errorMessage = "Wait... you can't even type the starting command correctly? Try again, this time with 'Start'."
            return false
        }
        return true
    }
    
    private func validateInput() {
        if validateUsername() && validateStartCommand() {
            UserDefaults.standard.set(username, forKey: "username")
            hasSeenOnboarding = true
            errorMessage = nil
        }
    }
    
    var body: some View {
        ZStack {
            PlayerView()
                .ignoresSafeArea()
                .edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    
                    VStack(spacing: 25) {
                        Text("Welcome to\nthe Terminal-tor")
                            .font(.custom("Glass_TTY_VT220", size: geometry.size.width < 400 ? 24 : 32))
                            .foregroundColor(TTYColors.text)
                            .multilineTextAlignment(.center)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter username:")
                                .font(.custom("Glass_TTY_VT220", size: 18))
                                .foregroundColor(TTYColors.text)
                            
                            TextField(">", text: $username)
                                .font(.custom("Glass_TTY_VT220", size: 20))
                                .foregroundColor(TTYColors.text)
                                .disableAutocorrection(true)
                                .padding(10)
                                .onChange(of: username) { _, newValue in
                                    if newValue.count > 12 {
                                        username = String(newValue.prefix(12))
                                        errorMessage = "Username must be 12 characters or less"
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.black.opacity(0.4))
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type 'Start' to begin:")
                                .font(.custom("Glass_TTY_VT220", size: 18))
                                .foregroundColor(TTYColors.text)
                            
                            TextField(">", text: $startCommand)
                                .font(.custom("Glass_TTY_VT220", size: 20))
                                .foregroundColor(TTYColors.text)
                                .disableAutocorrection(true)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.black.opacity(0.4))
                                )
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.custom("Glass_TTY_VT220", size: 16))
                                .foregroundColor(TTYColors.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: validateInput) {
                            Text("Validate")
                                .font(.custom("Glass_TTY_VT220", size: 20))
                                .foregroundColor(TTYColors.text)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(30)
                    .frame(width: containerWidth(geometry))
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.black.opacity(0.6))
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.ultraThinMaterial)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(TTYColors.text, lineWidth: 2)
                    )
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}


class PlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupVideo()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupVideo()
    }
    
    private func setupVideo() {
        guard let path = Bundle.main.path(forResource: "videohack", ofType: "mov"),
              let player = AVQueuePlayer() as AVQueuePlayer? else { return }
        
        let item = AVPlayerItem(url: URL(fileURLWithPath: path))
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        
        playerLooper = AVPlayerLooper(player: player, templateItem: item)
        player.isMuted = true
        player.play()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct PlayerView: UIViewRepresentable {
    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView()
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {}
}
