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
    @FocusState private var nameFieldIsFocused: Bool
    @FocusState private var dobFieldIsFocused: Bool

    var body: some View {
        ZStack {
            // Main Scrollable Content
            ScrollView {
                VStack(spacing: 20) {

                    // Title
                    Text("Tell us about you")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 40)

                    // Name Field
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hi, my name is ______.")
                            .foregroundColor(.secondary)
                        TextField("First name", text: $name)
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

                    // Continue Button
                    Button(action: {
                        continueAction()
                        dismissKeyboard()
                        nameFieldIsFocused = false
                        dobFieldIsFocused = false
                    }) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                            .cornerRadius(8)
                    }
                    .disabled(name.isEmpty || dateOfBirth.isEmpty || selectedGender == nil)
                    .opacity((name.isEmpty || dateOfBirth.isEmpty || selectedGender == nil) ? 0.5 : 1.0)
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Spacer()
                }
                // Extra bottom padding so content isn’t hidden behind the button
                .padding(.bottom, 80)
            }
            .background(Color(UIColor.systemBackground))
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"),
                      message: Text(errorMessage),
                      dismissButton: .default(Text("OK")))
            }
            .onAppear { subscribeToKeyboardEvents() }
            .onDisappear { NotificationCenter.default.removeObserver(self) }
            // Dismiss keyboard when tapping outside inputs
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
                nameFieldIsFocused = false
                dobFieldIsFocused = false
            }

            NavigationLink(destination: InterestsView(), isActive: $navigateToInterests) {
                EmptyView()
            }
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
                .foregroundColor(selectedGender == tag ? .white : Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(selectedGender == tag ? Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0) : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0), lineWidth: 1)
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

        let db = Firestore.firestore()
        let userInfo: [String: Any] = [
            "name": name,
            "dateOfBirth": dateOfBirth,
            "gender": gender,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(user.uid).setData(userInfo) { err in
            if let err = err {
                errorMessage = "Error saving information: \(err.localizedDescription)"
                showingAlert = true
            } else {
                // Navigate to next screen if desired
                DispatchQueue.main.async {
                    navigateToInterests = true
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
