import SwiftUI
import AuthenticationServices
import GoogleSignIn

/// Authentication view for sign in/sign up
struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var showingError = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    DesignSystem.Colors.primary.opacity(0.8),
                    DesignSystem.Colors.secondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and branding
                logoSection
                
                Spacer()
                
                // Sign in options
                signInSection
                
                // Skip for now option
                skipSection
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 30)
        }
        .alert("Authentication Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred during sign in")
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                appState.isAuthenticated = true
                appState.currentUser = viewModel.currentUser
            }
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            if error != nil {
                showingError = true
            }
        }
    }
    
    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: 20) {
            // App icon
            Image(systemName: "figure.outdoor.cycle")
                .font(.system(size: 80))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            // App name
            Text("MotoMitra")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Tagline
            Text("Your Motorcycle Companion")
                .font(DesignSystem.Typography.bodyLarge)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            // Hindi tagline
            Text("आपका मोटरसाइकिल साथी")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Sign In Section
    private var signInSection: some View {
        VStack(spacing: 16) {
            // Apple Sign In
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    viewModel.handleAppleSignInRequest(request)
                },
                onCompletion: { result in
                    viewModel.handleAppleSignInCompletion(result)
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Google Sign In
            Button(action: {
                viewModel.signInWithGoogle(presentingViewController: getRootViewController())
            }) {
                HStack(spacing: 12) {
                    Image("google_logo") // Add Google logo to assets
                        .renderingMode(.original)
                        .resizable()
                        .frame(width: 20, height: 20)
                    
                    Text("Sign in with Google")
                        .font(DesignSystem.Typography.bodyLarge)
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .frame(height: 50)
                .background(Color.white)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            
            // Privacy note
            Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Skip Section
    private var skipSection: some View {
        Button(action: {
            viewModel.continueAsGuest()
            appState.isAuthenticated = false
        }) {
            Text("Continue without account")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(.white.opacity(0.9))
                .underline()
        }
    }
    
    // MARK: - Helpers
    private func getRootViewController() -> UIViewController {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            fatalError("Unable to get root view controller")
        }
        return rootViewController
    }
}

/// Authentication view model
@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var errorMessage: String?
    
    @Injected private var authClient: AuthClient
    @Injected private var firestoreClient: FirestoreClient
    
    // MARK: - Apple Sign In
    
    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        // Generate and save nonce for security
        // let nonce = randomNonceString()
        // request.nonce = sha256(nonce)
    }
    
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    await signInWithApple(credential: appleIDCredential)
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authClient.signInWithApple(credential: credential)
            
            // Check if user profile exists
            if let profile = try await firestoreClient.fetch(
                UserProfile.self,
                from: Constants.FirebaseCollection.users,
                id: user.id
            ) {
                currentUser = profile
            } else {
                // Create new profile
                let newProfile = UserProfile(
                    userId: user.id,
                    displayName: user.displayName ?? "Rider",
                    email: user.email,
                    phoneNumber: nil,
                    photoURL: user.photoURL,
                    createdAt: Date(),
                    updatedAt: Date(),
                    preferences: UserPreferences(
                        recordingMode: .auto,
                        defaultVehicleId: nil,
                        mapProvider: .google,
                        notifications: NotificationPreferences(
                            rideReminders: true,
                            serviceReminders: true,
                            documentExpiry: true,
                            roomInvites: true
                        ),
                        privacy: PrivacySettings(
                            shareLocation: false,
                            shareStats: false,
                            publicProfile: false
                        )
                    ),
                    stats: UserStats()
                )
                
                _ = try await firestoreClient.save(
                    newProfile,
                    to: Constants.FirebaseCollection.users,
                    id: user.id
                )
                
                currentUser = newProfile
            }
            
            isAuthenticated = true
            isLoading = false
        } catch {
            errorMessage = "Failed to sign in with Apple: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle(presentingViewController: UIViewController) {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                let user = try await authClient.signInWithGoogle(presentingViewController: presentingViewController)
                
                // Similar profile creation/fetch as Apple Sign In
                // ... (same logic as above)
                
                isAuthenticated = true
                isLoading = false
            } catch {
                errorMessage = "Failed to sign in with Google: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - Guest Mode
    
    func continueAsGuest() {
        // Set up local-only mode
        UserDefaults.standard.set(true, forKey: "isGuestMode")
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKey.hasCompletedOnboarding)
        
        // Create local guest profile
        currentUser = UserProfile(
            userId: "guest_\(UUID().uuidString)",
            displayName: "Guest Rider",
            email: nil,
            phoneNumber: nil,
            photoURL: nil,
            createdAt: Date(),
            updatedAt: Date(),
            preferences: UserPreferences(
                recordingMode: .auto,
                defaultVehicleId: nil,
                mapProvider: .google,
                notifications: NotificationPreferences(
                    rideReminders: true,
                    serviceReminders: true,
                    documentExpiry: true,
                    roomInvites: false
                ),
                privacy: PrivacySettings(
                    shareLocation: false,
                    shareStats: false,
                    publicProfile: false
                )
            ),
            stats: UserStats()
        )
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try authClient.signOut()
            isAuthenticated = false
            currentUser = nil
            
            // Clear local data if needed
            UserDefaults.standard.set(false, forKey: "isGuestMode")
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}