import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    // MARK: - State Variables
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showingAlert = false
    
    // Controls navigation to BasicInfoView
    @State private var navigateToBasicInfo = false
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 12) { // Changed spacing from 20 to 24
                    // MARK: - Title
                    Text("Create your account")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.bottom, 24)
                    
                    // MARK: - Text Fields
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .accessibility(label: Text("Email"))
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .accessibility(label: Text("Password"))
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .accessibility(label: Text("Confirm Password"))
                    }
                    .padding(.horizontal, 16)
                    
                    // MARK: - Sign Up Button
                    Button(action: {
                        guard isValidEmail(email) else {
                            errorMessage = "Please enter a valid email address."
                            showingAlert = true
                            return
                        }
                        
                        // Validate matching passwords
                        guard password == confirmPassword else {
                            errorMessage = "Passwords do not match."
                            showingAlert = true
                            return
                        }
                        
                        // Create user with Firebase
                        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                            if let error = error {
                                errorMessage = error.localizedDescription
                                showingAlert = true
                                return
                            }
                            
                            // Navigate on the main thread to ensure UI updates correctly
                            DispatchQueue.main.async {
                                navigateToBasicInfo = true
                            }
                        }
                    }) {
                        Text("Sign Up")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0)) // Hex #11505F
                            .cornerRadius(8)
                    }
                    .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                    .opacity((email.isEmpty || password.isEmpty || confirmPassword.isEmpty) ? 0.5 : 1.0)
                    .padding(.horizontal, 16)
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("Registration Error"),
                              message: Text(errorMessage),
                              dismissButton: .default(Text("OK")))
                    }
                    
                    Spacer()
                    
                    // MARK: - Back to Login Link
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                        
                        NavigationLink(destination: LoginView().navigationBarBackButtonHidden(true)) {
                            Text("Login")
                                .foregroundColor(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.footnote)
                    .padding(.bottom, 16)
                }
                .padding(.top, 40) // Changed padding from 80 to 40
                
                // Hidden NavigationLink triggered by navigateToBasicInfo
                NavigationLink(
                    destination: BasicInfoView().navigationBarBackButtonHidden(true),
                    isActive: $navigateToBasicInfo
                ) {
                    EmptyView()
                }
            }
            .onTapGesture {
                self.hideKeyboard()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
