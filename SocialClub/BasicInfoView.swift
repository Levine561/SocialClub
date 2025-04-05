import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// Extension for dismissing keyboard
#if canImport(UIKit)
extension View {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct BasicInfoView: View {
    // MARK: - State Variables
    @State private var name: String = ""
    @State private var dateOfBirth: String = "" // expected format: MM/DD/YYYY
    @State private var selectedGender: Int? = nil // 0 = Male, 1 = Female, 2 = Other
    @State private var errorMessage: String = ""
    @State private var showingAlert: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var navigateToInterests: Bool = false
    @State private var progress: Double = 0.0
    @FocusState private var nameFieldIsFocused: Bool
    @FocusState private var dobFieldIsFocused: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Main Scrollable Content
            ScrollView {
                VStack(spacing: 20) {

                    ProgressView(value: progress, total: 1.0)
                        .tint(Color(red: 55/255.0, green: 119/255.0, blue: 1.0))
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal)
                        .padding(.top, 24)

                    // Title
                    Text("Tell us about you")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 4)

                    // Name Field
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hi, my name is ______.")
                            .foregroundColor(.secondary)
                        TextField("Name", text: $name)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .disableAutocorrection(true)
                            .autocapitalization(.words)
                            .focused($nameFieldIsFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                nameFieldIsFocused = false
                                dobFieldIsFocused = false
                            }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // Date of Birth Field (auto-formatted MM/DD/YYYY)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("I was born on ______.")
                            .foregroundColor(.secondary)
                        TextField("MM/DD/YYYY", text: $dateOfBirth)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .keyboardType(.numberPad)
                            .focused($dobFieldIsFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                nameFieldIsFocused = false
                                dobFieldIsFocused = false
                            }
                            .onChange(of: dateOfBirth) { newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                var result = ""
                                for (index, char) in filtered.enumerated() {
                                    // Insert slashes after 2nd and 4th digit
                                    if index == 2 || index == 4 {
                                        result.append("/")
                                    }
                                    result.append(char)
                                }
                                // Limit to 10 characters total
                                if result.count > 10 {
                                    result = String(result.prefix(10))
                                }
                                // Update if changed
                                if result != newValue {
                                    self.dateOfBirth = result
                                }
                            }
                    }
                    .padding(.horizontal)

                    // Gender Selection (Chips/Pills style)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("I identify as a ______.")
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            genderChip(title: "Male", tag: 0)
                            genderChip(title: "Female", tag: 1)
                            genderChip(title: "Other", tag: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .background(Color(UIColor.systemBackground))
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"),
                      message: Text(errorMessage),
                      dismissButton: .default(Text("OK")))
            }
            .onAppear {
                subscribeToKeyboardEvents()
                progress = 0.2
            }
            .onDisappear { NotificationCenter.default.removeObserver(self) }
            // Dismiss keyboard when tapping outside inputs
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
                nameFieldIsFocused = false
                dobFieldIsFocused = false
            }

            VStack {
                Spacer()
                Button(action: {
                    continueAction()
                    dismissKeyboard()
                    nameFieldIsFocused = false
                    dobFieldIsFocused = false
                }) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor((name.isEmpty || dateOfBirth.isEmpty || selectedGender == nil) ? Color(red: 142/255, green: 142/255, blue: 147/255) : Color(red: 255/255, green: 255/255, blue: 255/255))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((name.isEmpty || dateOfBirth.isEmpty || selectedGender == nil) ? Color(red: 236/255, green: 236/255, blue: 236/255) : Color(red: 55/255, green: 119/255, blue: 1.0))
                        .cornerRadius(8)
                }
                .disabled(name.isEmpty || dateOfBirth.isEmpty || selectedGender == nil)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }

            NavigationLink(destination: InterestsView().navigationBarBackButtonHidden(true), isActive: $navigateToInterests) {
                EmptyView()
            }
            .animation(nil, value: navigateToInterests)
            .hidden()
        }
    }

    // MARK: - Gender Chip Helper
    private func genderChip(title: String, tag: Int) -> some View {
        Button(action: {
            selectedGender = tag
            dismissKeyboard()
            nameFieldIsFocused = false
            dobFieldIsFocused = false
        }) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(selectedGender == tag ? Color.black : (colorScheme == .dark ? Color.white : Color(red: 50/255.0, green: 50/255.0, blue: 50/255.0)))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(selectedGender == tag ? Color(red: 215/255.0, green: 228/255.0, blue: 255/255.0) : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(selectedGender == tag ? Color.clear : Color(red: 209/255.0, green: 209/255.0, blue: 209/255.0), lineWidth: 1)
                )
        }
    }

    // MARK: - Continue Action
    func continueAction() {
        // Validate fields
        guard !name.isEmpty, !dateOfBirth.isEmpty, selectedGender != nil else {
            errorMessage = "Please fill in all fields."
            showingAlert = true
            return
        }
        // Validate date format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        guard let dobDate = dateFormatter.date(from: dateOfBirth) else {
            errorMessage = "Please enter a valid date in MM/DD/YYYY format."
            showingAlert = true
            dateOfBirth = ""
            return
        }
        // Check age
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dobDate, to: Date())
        if let age = ageComponents.year, age < 18 {
            errorMessage = "You must be at least 18 years old."
            showingAlert = true
            dateOfBirth = ""
            return
        }
        // Store the information in the backend
        storeUserInformation(name: name, dateOfBirth: dateOfBirth, gender: selectedGender!)
    }

    // MARK: - Store Info in Firestore
    func storeUserInformation(name: String, dateOfBirth: String, gender: Int) {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User not authenticated."
            showingAlert = true
            return
        }

        // Update the Firebase Auth user's displayName
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        changeRequest.commitChanges { error in
            if let error = error {
                errorMessage = "Error updating profile: \(error.localizedDescription)"
                showingAlert = true
                return
            }

            // After successful profile update, save the name to Firestore
            let db = Firestore.firestore()
            let userInfo: [String: Any] = [
                "name": name,
                "timestamp": FieldValue.serverTimestamp()
            ]

            db.collection("users").document(user.uid).setData(userInfo) { err in
                if let err = err {
                    errorMessage = "Error saving information: \(err.localizedDescription)"
                    showingAlert = true
                } else {
                    // Save gender and dateOfBirth locally
                    UserDefaults.standard.set(gender, forKey: "gender")
                    UserDefaults.standard.set(dateOfBirth, forKey: "dateOfBirth")
                    // Navigate to next screen if desired without slide animation
                    DispatchQueue.main.async {
                        navigateToInterests = true
                    }
                }
            }
        }
    }

    // MARK: - Keyboard Handling
    func subscribeToKeyboardEvents() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                               object: nil,
                                               queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height - safeAreaBottomInset()
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification,
                                               object: nil,
                                               queue: .main) { _ in
            keyboardHeight = 0
        }
    }

    func safeAreaBottomInset() -> CGFloat {
        let window = UIApplication.shared.windows.first
        return window?.safeAreaInsets.bottom ?? 0
    }
}

struct BasicInfoView_Previews: PreviewProvider {
    static var previews: some View {
        BasicInfoView()
    }
}
