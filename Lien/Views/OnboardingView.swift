import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @ObservedObject var viewModel: LienViewModel
    @State private var currentPage = 0
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var lifeExpectancy = 80
    
    // State for Photo Picker
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    // Calculate total pages
    private let totalPages = 5 // Welcome, Name, Picture, Birthday, Philosophy
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                welcomeView
                    .tag(0)
                
                nameView
                    .tag(1)
                
                // Add Profile Image View
                profileImageView
                    .tag(2)
                
                birthdayView
                    .tag(3)
                
                philosophyView
                    .tag(4)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            navigationButtons
        }
        .padding()
        .background(AppColor.primaryBackground)
        // Add PhotosPicker selection handling
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                // Retrieve selected asset in the form of Data
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }
    
    // MARK: - Page Views
    
    var welcomeView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(AppColor.accent)
            
            Text("Welcome to Lien")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppColor.text)
            
            Text("Your minimalist companion for meaningful relationships.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColor.secondaryText)
                .padding(.horizontal)
            
            Spacer()
            
            Text("Lien helps you stay in touch with the people who matter most in your life.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColor.secondaryText)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    var nameView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("What should we call you?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColor.text)
            
            LienTextField(title: "Your Name", text: $name, placeholder: "Enter your name")
            
            Spacer()
            
            Text("This helps personalize your experience.")
                .font(.caption)
                .foregroundColor(AppColor.secondaryText)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    var profileImageView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Add a Profile Picture?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColor.text)
                .padding(.bottom, 10)
            
            Text("(Optional) This will represent you in the network view.")
                .font(.callout)
                .foregroundColor(AppColor.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // PhotosPicker
            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                Group {
                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppColor.accent, lineWidth: 2))
                    } else {
                        Circle()
                            .fill(AppColor.cardBackground)
                            .frame(width: 150, height: 150)
                            .overlay(
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 70))
                                    .foregroundColor(AppColor.secondaryText)
                            )
                    }
                }
            }
            .buttonStyle(.plain) // Use plain style to make the content tappable
            
            Spacer()
            
            // Button to remove selection if needed
            if selectedImageData != nil {
                Button("Remove Image") {
                    selectedPhotoItem = nil
                    selectedImageData = nil
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
    }
    
    var birthdayView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("When were you born?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColor.text)
            
            DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
            
            Stepper("Life Expectancy: \(lifeExpectancy) years", value: $lifeExpectancy, in: 60...120)
                .padding()
                .background(AppColor.cardBackground)
                .cornerRadius(10)
                .padding(.horizontal)
            
            Spacer()
            
            Text("This helps calculate the time perspective features.")
                .font(.caption)
                .foregroundColor(AppColor.secondaryText)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .background(AppColor.cardBackground)
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    var philosophyView: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("A Different Perspective")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.text)
                
                Image(systemName: "hourglass")
                    .resizable()
                    .frame(width: 50, height: 80)
                    .foregroundColor(AppColor.accent)
                
                Text("Based on your age, you have approximately:")
                    .font(.body)
                    .foregroundColor(AppColor.secondaryText)
                
                VStack(spacing: 16) {
                    TimeInfoCard(
                        title: "Years",
                        value: "\(calculateYearsLeft())",
                        subtitle: "remaining in your life"
                    )
                    
                    TimeInfoCard(
                        title: "Weeks",
                        value: "\(calculateYearsLeft() * 52)",
                        subtitle: "to spend with your loved ones"
                    )
                }
                
                Text("Lien helps you make the most of this time by reminding you to connect with the people who matter.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppColor.secondaryText)
                    .padding(.horizontal)
            }
            .padding()
        }
    }
    
    // MARK: - Navigation Buttons
    
    var navigationButtons: some View {
        HStack {
            if currentPage > 0 {
                Button(action: {
                    withAnimation {
                        currentPage -= 1
                    }
                }) {
                    Text("Previous")
                        .padding()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            Spacer()
            
            Button(action: {
                if currentPage < totalPages - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding()
                }
            }) {
                Text(currentPage < totalPages - 1 ? "Next" : "Get Started")
                    .padding()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(currentPage == 1 && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func calculateYearsLeft() -> Int {
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return max(0, lifeExpectancy - age)
    }
    
    private func completeOnboarding() {
        viewModel.userProfile = UserProfile(name: name, dateOfBirth: birthDate)
        viewModel.userProfile.lifeExpectancy = lifeExpectancy
        // Save image data
        viewModel.userProfile.profileImageData = selectedImageData
        
        viewModel.saveUserProfile()
        viewModel.completeOnboarding()
    }
}

// MARK: - Helper Views

struct TimeInfoCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColor.secondaryText)
            
            Text(value)
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(AppColor.text)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(AppColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColor.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView(viewModel: LienViewModel())
} 