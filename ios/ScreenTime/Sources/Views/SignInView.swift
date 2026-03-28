import SwiftUI
import AuthenticationServices

// MARK: - ASWebAuthenticationSession context provider

class OAuthContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let window = scene.windows.first
        else {
            return ASPresentationAnchor()
        }
        return window
    }
}

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isRegistering = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showVerificationAlert = false

    /// Prevent ARC from deallocating the session before it completes.
    @State private var authSession: ASWebAuthenticationSession?
    private let contextProvider = OAuthContextProvider()

    private let backendBaseURL = "http://localhost:3000"

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
            .alert("Verify Your Email", isPresented: $showVerificationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Check your inbox — we've sent a verification link to \(email). Please verify your email to unlock full access.")
            }
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
                    showVerificationAlert = true
                } else {
                    try await authService.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - OAuth

    private func signInWithGoogle() {
        startOAuthFlow(
            urlString: "https://accounts.google.com/o/oauth2/v2/auth?client_id=YOUR_GOOGLE_CLIENT_ID&redirect_uri=com.screentime.app:/oauth2callback&response_type=code&scope=email%20profile",
            provider: "google"
        )
    }

    private func signInWithApple() {
        startOAuthFlow(
            urlString: "https://appleid.apple.com/auth/authorize?client_id=YOUR_APPLE_CLIENT_ID&redirect_uri=com.screentime.app:/oauth2callback&response_type=code&scope=email%20name",
            provider: "apple"
        )
    }

    private func signInWithFacebook() {
        startOAuthFlow(
            urlString: "https://www.facebook.com/v18.0/dialog/oauth?client_id=YOUR_FACEBOOK_APP_ID&redirect_uri=com.screentime.app:/oauth2callback&response_type=code&scope=email,public_profile",
            provider: "facebook"
        )
    }

    private func startOAuthFlow(urlString: String, provider: String) {
        guard let url = URL(string: urlString) else { return }
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "com.screentime.app"
        ) { callbackURL, error in
            if let error {
                DispatchQueue.main.async {
                    self.errorMessage = "OAuth failed: \(error.localizedDescription)"
                }
                return
            }

            guard let callbackURL,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                DispatchQueue.main.async {
                    self.errorMessage = "OAuth failed: no authorization code received."
                }
                return
            }

            self.exchangeOAuthCode(code: code, provider: provider)
        }
        session.presentationContextProvider = contextProvider
        session.prefersEphemeralWebBrowserSession = true
        authSession = session
        session.start()
    }

    private func exchangeOAuthCode(code: String, provider: String) {
        guard let url = URL(string: "\(backendBaseURL)/api/v1/auth/oauth/\(provider)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["code": code]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error {
                    self.errorMessage = "OAuth failed: \(error.localizedDescription)"
                    return
                }

                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let token = json["token"] as? String,
                      let userId = json["userId"] as? String,
                      let email = json["email"] as? String else {
                    self.errorMessage = "OAuth failed: invalid server response."
                    return
                }

                let emailVerified = json["emailVerified"] as? Bool ?? true
                self.authService.oauthSignIn(token: token, userId: userId, email: email, emailVerified: emailVerified)
            }
        }.resume()
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
