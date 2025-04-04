import SwiftUI
import FirebaseAuth
import FirebaseFirestore

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct LoginView: View {
    // MARK: - State
    @State private var emailOrUsername = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var showErrorAlert: Bool = false
    @State private var navigateToExplore = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Main container with tap gesture to dismiss keyboard
                Group {
                    // MARK: - Logo & Tagline
                    VStack(spacing: 4) {
                        Image(colorScheme == .dark ? "Darkmodelogo" : "SocialClubLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 400, height: 80, alignment: .center)
                    }
                    
                    // MARK: - Text Fields
                    VStack(spacing: 24) {
                        // Username Field
                        TextField("Email", text: $emailOrUsername)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .accessibility(label: Text("Email"))
                            .frame(height: 44)
                        
                        // Password Field
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .accessibility(label: Text("Password"))
                            .frame(height: 44)
                    }
                    .padding(.horizontal, 16)
                    
                    // MARK: - Login Button
                    Button(action: {
                        let trimmedInput = emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedInput.contains("@") {
                            Auth.auth().signIn(withEmail: trimmedInput, password: password) { authResult, error in
                                if let error = error {
                                    errorMessage = error.localizedDescription
                                    showErrorAlert = true
                                    return
                                }
                                print("Login successful!")
                                navigateToExplore = true
                            }
                        } else {
                            errorMessage = "Please enter a valid email address."
                            showErrorAlert = true
                        }
                    }) {
                        Text("Login")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor((emailOrUsername.isEmpty || password.isEmpty) ? Color(red: 142/255.0, green: 142/255.0, blue: 147/255.0) : Color.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background((emailOrUsername.isEmpty || password.isEmpty) ? Color(red: 236/255.0, green: 236/255.0, blue: 236/255.0) : Color(red: 255/255.0, green: 49/255.0, blue: 95/255.0))
                    .cornerRadius(8)
                    .frame(height: 48)
                    .padding(.horizontal, 16)
                    .disabled(emailOrUsername.isEmpty || password.isEmpty)
                    
                    // MARK: - Forgot Password
                    Button(action: {
                        // Forgot password logic
                    }) {
                        Text("Forgot password")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                    
                    Spacer()
                    
                    // MARK: - Sign Up Link
                    HStack {
                        Text("Don’t have an account?")
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: SignUpView())
                        }) {
                            Text("Sign up")
                                .foregroundColor(Color(red: 255/255.0, green: 49/255.0, blue: 95/255.0))
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.footnote)
                    .padding(.bottom, 0)
                }
                
                NavigationLink(
                    destination: ExploreView().navigationBarBackButtonHidden(true),
                    isActive: $navigateToExplore,
                    label: {
                        EmptyView()
                    }
                ).animation(nil, value: navigateToExplore)
                .hidden()
            }
            .onTapGesture {
                self.hideKeyboard()
            }
            .padding(.top, 40) // extra top padding
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // anchor to the top
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Login Error"),
                  message: Text(errorMessage ?? "An unknown error occurred."),
                  dismissButton: .default(Text("OK")))
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
