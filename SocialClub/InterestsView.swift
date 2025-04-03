import SwiftUI

@available(iOS 16.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? UIScreen.main.bounds.width
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(width: size.width, height: size.height))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct InterestsView: View {
    // Tracks selected interests
    @State private var selectedInterests: Set<String> = []
    // Controls navigation to the next screen
    @State private var shouldNavigate = false
    // Controls navigation to the Basics Info page
    @State private var goToBasicsInfo = false
    // Progress state variable
    @State private var progress: Double = 0.2
    
    // Access to presentationMode (if needed)
    @Environment(\.presentationMode) var presentationMode
    
    // Example categories and interests with emojis added to descriptions
    private let interestsByCategory: [String: [String]] = [
        "Lifestyle": [
            "Food 🍔", "Coffee ☕️", "Wellness ⚖️", "Fitness 🏋️", "Travel ✈️", "Mindfulness 🧠", "Yoga 🧘", "Healthy Eating 🥗"
        ],
        "Entertainment": [
            "Music 🎵", "Movies 🎬", "Concerts 🎤", "Nightlife 🌃", "Sports ⚽️", "Gaming 🎮", "Theater 🎭", "Comedy 😂"
        ],
        "Outdoors": [
            "Hiking 🥾", "Camping ⛺️", "Nature Trails 🌲", "Outdoor Activities 🏞", "Picnics 🧺", "Biking 🚴", "Running 🏃"
        ],
        "Culture": [
            "Arts 🎨", "Festivals 🎉", "History & Culture 🏛", "LGBTQ events 🏳️‍🌈", "Professional Networking 🤝", "Volunteering 🙌", "Museums 🖼", "Poetry ✍️"
        ]
    ]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                ProgressView(value: progress, total: 1.0)
                    .tint(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                    .padding(.top, 24)

                // Title
                Text("What Interests You?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                
                // Subtitle
                Text("Select at least 5 of your interests.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Scrollable list of categories and their chips
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(Array(interestsByCategory.keys.sorted().enumerated()), id: \.offset) { index, category in
                            if index > 0 {
                                Divider()
                                    .background(Color.gray)
                                    .padding(.horizontal, 16)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                // Category header
                                Text(category)
                                    .font(.headline)
                                    .padding(.horizontal, 16)
                                
                                // Horizontal scroll view of chips in a row
                                FlowLayout(spacing: 12) {
                                    let items = interestsByCategory[category] ?? []
                                    ForEach(items, id: \.self) { interest in
                                        Button(action: {
                                            toggleInterest(interest)
                                        }) {
                                            HStack(spacing: 8) {
                                                if let spaceIndex = interest.lastIndex(of: " ") {
                                                    Text(String(interest[interest.index(after: spaceIndex)...]))
                                                    Text(String(interest[..<spaceIndex]))
                                                        .font(.system(size: 16, weight: .medium))
                                                } else {
                                                    Text(interest)
                                                        .font(.system(size: 16, weight: .medium))
                                                }
                                            }
                                            .lineLimit(1)
                                            .fixedSize()
                                            .foregroundColor(selectedInterests.contains(interest) ? .white : Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 12)
                                            .background(selectedInterests.contains(interest) ? Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0) : Color.clear)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.top, 16) // Increased vertical padding below the chip rows
                    .padding(.bottom, 80) // Added bottom padding to allow scrolling down
                }
                
                // Continue Button
                Button(action: {
                    UserDefaults.standard.set(Array(selectedInterests), forKey: "selectedInterests")
                    shouldNavigate = true
                }) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 17/255.0, green: 80/255.0, blue: 95/255.0))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .disabled(selectedInterests.count < 5)
                .opacity(selectedInterests.count < 5 ? 0.5 : 1.0)
                
                // NavigationLink to UsernameView
                NavigationLink(destination: UsernameView().navigationBarBackButtonHidden(true), isActive: $shouldNavigate) {
                    EmptyView()
                }
                .hidden()
                
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.linear(duration: 1.0)) {
                    progress = 0.4
                }
            }
        }
    }
    
    // Toggle an interest in the selection set
    private func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
}

struct InterestsView_Previews: PreviewProvider {
    static var previews: some View {
        InterestsView()
    }
}
