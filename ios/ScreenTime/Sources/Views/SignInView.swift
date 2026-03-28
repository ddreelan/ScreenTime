import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isRegistering = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("ScreenTime")
                            .font(.largeTitle.bold())
                        Text("Take control of your time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 16) {
                        if isRegistering {
                            TextField("Name", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.name)
                                .autocorrectionDisabled()
                        }

                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(isRegistering ? .newPassword : .password)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: submit) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isRegistering ? "Create Account" : "Sign In")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isLoading)

                        Button(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Register") {
                            withAnimation {
                                isRegistering.toggle()
                                errorMessage = nil
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal, 24)

                    // OAuth Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                        Text("or").foregroundColor(.secondary).font(.caption)
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.horizontal, 24)

                    // OAuth Buttons
                    VStack(spacing: 12) {
                        OAuthButton(
                            title: "Continue with Google",
                            systemImage: "globe",
                            backgroundColor: .white,
                            foregroundColor: .black,
                            action: signInWithGoogle
                        )

                        OAuthButton(
                            title: "Continue with Apple",
                            systemImage: "apple.logo",
                            backgroundColor: .black,
                            foregroundColor: .white,
                            action: signInWithApple
                        )

                        OAuthButton(
                            title: "Continue with Facebook",
                            systemImage: "person.crop.square.fill",
                            backgroundColor: Color(red: 0.23, green: 0.35, blue: 0.60),
                            foregroundColor: .white,
                            action: signInWithFacebook
                        )
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Actions

    private func submit() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                if isRegistering {
                    try await authService.register(email: email, password: password, name: name)
                } else {
                    try await authService.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - OAuth Stubs

    private func signInWithGoogle() {
        // TODO: Replace YOUR_GOOGLE_CLIENT_ID with real client ID
        // Uses ASWebAuthenticationSession to open:
        // https://accounts.google.com/o/oauth2/v2/auth?client_id=YOUR_GOOGLE_CLIENT_ID&redirect_uri=com.screentime.app:/oauth2callback&response_type=code&scope=email%20profile
        startOAuthFlow(
            urlString: "https://accounts.google.com/o/oauth2/v2/auth?client_id=YOUR_GOOGLE_CLIENT_ID&redirect_uri=com.screentime.app:/oauth2callback&response_type=code&scope=email%20profile"
        )
    }

    private func signInWithApple() {
        // TODO: Replace with real Apple Sign In configuration
        // Uses ASWebAuthenticationSession for Apple OAuth
        startOAuthFlow(
            urlString: "https://appleid.apple.com/auth/authorize?client_id=YOUR_APPLE_CLIENT_ID&redirect_uri=com.screentime.app:/oauth2callback&response_type=code&scope=email%20name"
        )
    }

    private func signInWithFacebook() {
        // TODO: Replace YOUR_FACEBOOK_APP_ID with real app ID
        startOAuthFlow(
            urlString: "https://www.facebook.com/v18.0/dialog/oauth?client_id=YOUR_FACEBOOK_APP_ID&redirect_uri=com.screentime.app:/oauth2callback&response_type=code&scope=email,public_profile"
        )
    }

    private func startOAuthFlow(urlString: String) {
        // TODO: Implement full OAuth flow with ASWebAuthenticationSession
        // 1. Open URL with ASWebAuthenticationSession
        // 2. Handle callback with authorization code
        // 3. Exchange code for token via backend /api/v1/auth/oauth/{provider}
        // 4. Set authService.isAuthenticated = true on success
        guard let url = URL(string: urlString) else { return }
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "com.screentime.app"
        ) { callbackURL, error in
            // TODO: Parse the authorization code from callbackURL
            // TODO: Send code to backend for token exchange
            if let error {
                DispatchQueue.main.async {
                    self.errorMessage = "OAuth failed: \(error.localizedDescription)"
                }
            }
        }
        session.prefersEphemeralWebBrowserSession = true
        // TODO: Set presentationContextProvider and call session.start()
    }
}

// MARK: - OAuth Button

struct OAuthButton: View {
    let title: String
    let systemImage: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.body)
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
