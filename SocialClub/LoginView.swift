import SwiftUI
import FirebaseAuth

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

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Main container with tap gesture to dismiss keyboard
                Group {
                    // MARK: - Logo & Tagline
                    VStack(spacing: 4) {
                        Image("SocialClubLogo") // Replace with your actual logo asset name
                            .resizable()
                            .scaledToFit()
                            .frame(width: 400, height: 80, alignment: .center)
                    }
                    
                    // MARK: - Text Fields
                    VStack(spacing: 24) {
                        // Username Field
                        TextField("Email or Username", text: $emailOrUsername)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .accessibility(label: Text("Email or Username"))
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
                        Auth.auth().signIn(withEmail: emailOrUsername, password: password) { authResult, error in
                            if let error = error {
                                errorMessage = error.localizedDescription
                                showErrorAlert = true
                                return
                            }
                            
                            print("Login successful!")
                            navigateToExplore = true
                        }
                    }) {
                        Text("Login")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0)) // Hex #11505F
                            .cornerRadius(8)
                            .frame(height: 48)
                    }
                    .disabled(emailOrUsername.isEmpty || password.isEmpty)
                    .opacity((emailOrUsername.isEmpty || password.isEmpty) ? 0.5 : 1.0)
                    .padding(.horizontal, 16)
                    
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
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .foregroundColor(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.footnote)
                    .padding(.bottom, 16)
                }
                
                NavigationLink(
                    destination: ExploreView(),
                    isActive: $navigateToExplore,
                    label: {
                        EmptyView()
                    }
                ).hidden()
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
