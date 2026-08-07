import SwiftUI
import PDFKit
import Vision
#if canImport(UIKit)
import UIKit
#endif


struct ProfileSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var documentStorageManager: DocumentStorageManager
    @State private var userFirstName = ""
    @State private var userLastName = ""
    @State private var coparentFirstName = ""
    @State private var coparentLastName = ""
    @State private var children: [UserProfile.Child] = [
        UserProfile.Child(
            birthday: Calendar.current.dateComponents([.year, .month, .day], from: Date())
        )
    ]
    @State private var stateOfResidence = ""
    @State private var country = "United States" // New state for country, default to United States
    @State private var conflictLevel = 1
    @State private var possessionSchedule = ""
    @State private var divorceDecreeURL: URL?
    @State private var divorceDecreeBookmark: Data?
    @State private var divorceDecreeText: String?
    @State private var isExtractingDecree = false
    @State private var decreeParseSummary: String?
    @State private var decreeConfidence: Double?
    @State private var decreeExtractionStats: String?
    @State private var showSaveAlert = false
    @State private var saveSuccess = false
    @State private var saveMessage = ""
    @State private var showValidationAlert = false
    @State private var showDocumentPicker = false
    @State private var showDocumentViewer = false
    @FocusState private var focusedField: String?
    
    // Smart form navigation and validation states
    @State private var fieldValidation: [String: Bool] = [:]
    @State private var completionPercentage: Double = 0.0
    @State private var showValidationHints = false
    @State private var showOnboardingPrompt = false
    
    // Check if this is initial setup or editing existing profile
    private var isInitialSetup: Bool {
        UserDefaults.standard.data(forKey: "userProfile") == nil
    }

    private let states = ["Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"]
    private let countries = ["United States", "Canada", "UK", "Australia", "New Zealand"]
    private let genderOptions = ["M", "F", "Rather not say"]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                headerView
                
                // Onboarding suggestion banner for initial setup
                if isInitialSetup {
                    onboardingSuggestionBanner
                }
                
                // Progress indicator
                progressIndicatorView

                Form {
                    userInfoSection
                    coparentInfoSection
                    childrenSection
                    stateSection
                    countrySection
                    possessionScheduleSection
                    divorceDecreeSection
                    conflictLevelSection
                }
                .scrollContentBackground(.hidden)
                Spacer()
            }
            .background(GCPTheme.canvas)
            .navigationTitle("Family Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(pickerType: .documents) { url in
                    Task {
                        await copyDocumentToAppDirectory(from: url)
                    }
                }
            }
            .sheet(isPresented: $showDocumentViewer) {
                if let url = divorceDecreeURL {
                    DocumentViewer(
                        documentURL: url,
                        documentTitle: "Divorce Decree"
                    )
                } else {
                    Text("No document URL available")
                }
            }
            .alert("Required Fields", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please fill in your first name and the coparent's first name to save the profile.")
            }
            .alert(isPresented: $showSaveAlert) {
                Alert(
                    title: Text(saveSuccess ? "Success" : "Error"),
                    message: Text(saveMessage),
                    dismissButton: .default(Text("OK")) {
                        if saveSuccess {
                            dismiss()
                        }
                    }
                )
            }
            .onAppear {
                loadProfile()
                updateFormValidation()
            }
            .onChange(of: userFirstName) { _, _ in updateFormValidation() }
            .onChange(of: coparentFirstName) { _, _ in updateFormValidation() }
            .onChange(of: children) { _, _ in updateFormValidation() }
            .onChange(of: stateOfResidence) { _, _ in updateFormValidation() }
            .onChange(of: conflictLevel) { _, _ in updateFormValidation() }
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicatorView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Profile Completion")
                    .font(.custom("Avenir-Book", size: 14))
                    .foregroundColor(Color(hex: "388083"))
                Spacer()
                Text("\(Int(completionPercentage))%")
                    .font(.custom("Avenir-Book", size: 14).weight(.semibold))
                    .foregroundColor(Color(hex: "388083"))
            }
            
            ProgressView(value: completionPercentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "388083")))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .background(Color(hex: "C2EDCE").opacity(0.3))
                .cornerRadius(4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
    
    // MARK: - Validation Indicator
    private func validationIndicator(for field: String, isValid: Bool) -> some View {
        Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
            .foregroundColor(isValid ? .green : .gray.opacity(0.5))
            .font(.system(size: 20))
            .animation(.easeInOut(duration: 0.2), value: isValid)
    }

    // MARK: - Subviews
    
    private var onboardingSuggestionBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(hex: "388083"))
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("💬 Easier Setup Available!")
                        .font(Font.custom("Avenir-Book", size: 16).weight(.semibold))
                        .foregroundColor(Color(hex: "388083"))
                    
                    Text("Complete your profile through a friendly chat conversation instead of this form.")
                        .font(Font.custom("Avenir-Book", size: 14))
                        .foregroundColor(Color(hex: "388083").opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            Button(action: {
                // Clear any existing onboarding flags to trigger chat setup
                UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
                showOnboardingPrompt = true
                dismiss()
                
                // Post notification to trigger chat onboarding
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: .startChatOnboarding, object: nil)
                }
            }) {
                Text("Start Chat Setup")
                    .font(Font.custom("Avenir-Book", size: 14).weight(.medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "388083"), Color(hex: "C2EDCE")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Personalize your conversations")
                    .font(GCPTheme.bodyMedium(14))
                    .foregroundStyle(GCPTheme.primary.opacity(0.8))
                Text("Names, kids, and conflict level help Gentler Coparent give better guidance.")
                    .font(GCPTheme.caption(12))
                    .foregroundStyle(GCPTheme.primary.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 8)

            Button(action: {
                if userFirstName.isEmpty || coparentFirstName.isEmpty {
                    showValidationAlert = true
                } else {
                    saveProfile()
                }
            }) {
                Text("Save")
                    .font(GCPTheme.bodyMedium(15))
                    .foregroundStyle(userFirstName.isEmpty || coparentFirstName.isEmpty ? Color.gray : Color.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule()
                            .fill(userFirstName.isEmpty || coparentFirstName.isEmpty
                                  ? Color.gray.opacity(0.25)
                                  : GCPTheme.primary)
                    )
            }
            .disabled(userFirstName.isEmpty || coparentFirstName.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .highPriorityGesture(
            DragGesture(minimumDistance: 10)
                .onEnded { _ in
                    if focusedField != nil {
                        focusedField = nil
                    }
                }
        )
    }

    private var userInfoSection: some View {
        Section(header: Text("Your Information")
                    .font(Font.custom("Avenir-Book", size: 16))
                    .foregroundColor(Color(hex: "388083"))) {
            HStack {
                TextField("First Name", text: $userFirstName)
                    .font(Font.custom("Avenir-Book", size: 16))
                    .frame(height: 50)
                    .focused($focusedField, equals: "userFirstName")
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = "userLastName"
                    }
                validationIndicator(for: "userFirstName", isValid: !userFirstName.isEmpty)
            }
            HStack {
                TextField("Last Name", text: $userLastName)
                    .font(Font.custom("Avenir-Book", size: 16))
                    .frame(height: 50)
                    .focused($focusedField, equals: "userLastName")
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = "coparentFirstName"
                    }
                validationIndicator(for: "userLastName", isValid: !userLastName.isEmpty)
            }
        }
    }

    private var coparentInfoSection: some View {
        Section(header: Text("Coparent Information")
                    .font(Font.custom("Avenir-Book", size: 16))
                    .foregroundColor(Color(hex: "388083"))) {
            HStack {
                TextField("First Name", text: $coparentFirstName)
                    .font(Font.custom("Avenir-Book", size: 16))
                    .frame(height: 50)
                    .focused($focusedField, equals: "coparentFirstName")
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = "coparentLastName"
                    }
                validationIndicator(for: "coparentFirstName", isValid: !coparentFirstName.isEmpty)
            }
            HStack {
                TextField("Last Name", text: $coparentLastName)
                    .font(Font.custom("Avenir-Book", size: 16))
                    .frame(height: 50)
                    .focused($focusedField, equals: "coparentLastName")
                    .submitLabel(.done)
                    .onSubmit {
                        focusedField = nil
                    }
                validationIndicator(for: "coparentLastName", isValid: !coparentLastName.isEmpty)
            }
        }
    }

    private var childrenSection: some View {
        Section(header: HStack {
            Text("Children")
                .font(Font.custom("Avenir-Book", size: 16))
                .foregroundColor(Color(hex: "388083"))
            Text("swipe left to delete")
                .font(Font.custom("Avenir-Book", size: 12))
                .foregroundColor(Color.gray)
            Spacer()
            Button(action: {
                audioManager.triggerHapticFeedback(.success)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    children.insert(UserProfile.Child(
                        firstName: "",
                        lastName: "",
                        birthday: Calendar.current.dateComponents([.year, .month, .day], from: Date()),
                        gender: "Rather not say"
                    ), at: 0)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: "388083"))
                    Text("Add Child")
                        .font(.custom("Avenir-Book", size: 12))
                        .foregroundColor(Color(hex: "388083"))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "C2EDCE").opacity(0.6))
                .cornerRadius(12)
            }
        }) {
            ForEach($children) { $child in
                VStack(alignment: .leading, spacing: 10) {
                    TextField("First Name", text: $child.firstName)
                        .font(Font.custom("Avenir-Book", size: 16))
                        .frame(height: 50)
                        .focused($focusedField, equals: "childFirstName\(child.id.uuidString)")
                        .submitLabel(.next)
                    TextField("Last Name", text: $child.lastName)
                        .font(Font.custom("Avenir-Book", size: 16))
                        .frame(height: 50)
                        .focused($focusedField, equals: "childLastName\(child.id.uuidString)")
                        .submitLabel(.next)
                    DatePicker("Birthday", selection: Binding(
                        get: { Calendar.current.date(from: child.birthday) ?? Date() },
                        set: { newDate in
                            child.birthday = Calendar.current.dateComponents([.year, .month, .day], from: newDate)
                        }
                    ), displayedComponents: .date)
                    .font(Font.custom("Avenir-Book", size: 16))
                    .foregroundColor(Color(hex: "388083"))
                    if let _ = Calendar.current.date(from: child.birthday) {
                        Text("Age: \(child.age)")
                            .font(Font.custom("Avenir-Book", size: 16))
                            .foregroundColor(Color(hex: "388083"))
                            .lineLimit(nil)
                    }
                    Picker("Gender", selection: $child.gender) {
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option)
                                .font(Font.custom("Avenir-Book", size: 16))
                                .tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        audioManager.triggerHapticFeedback(.warning)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if let index = children.firstIndex(where: { $0.id == child.id }) {
                                children.remove(at: index)
                            }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                    .tint(.red)
                }
            }
        }
    }

    private var stateSection: some View {
        Group {
            if country == "United States" {
                Section(header: Text("State of Residence")
                            .font(Font.custom("Avenir-Book", size: 16))
                            .foregroundColor(Color(hex: "388083"))) {
                    Picker("State", selection: $stateOfResidence) {
                        Text("Select a state")
                            .font(Font.custom("Avenir-Book", size: 16))
                            .foregroundColor(Color(hex: "388083"))
                            .tag("")
                        ForEach(states, id: \.self) { state in
                            Text(state)
                                .font(Font.custom("Avenir-Book", size: 16))
                                .tag(state)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
    }

    private var countrySection: some View {
        Section(header: Text("Country of Residence")
                    .font(Font.custom("Avenir-Book", size: 16))
                    .foregroundColor(Color(hex: "388083"))) {
            Picker("Country", selection: $country) {
                Text("Select a country")
                    .font(Font.custom("Avenir-Book", size: 16))
                    .foregroundColor(Color(hex: "388083"))
                    .tag("")
                ForEach(countries, id: \.self) { country in
                    Text(country)
                        .font(Font.custom("Avenir-Book", size: 16))
                        .tag(country)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: country) { _, newCountry in
                // Clear state if country is not United States
                if newCountry != "United States" {
                    stateOfResidence = ""
                }
            }
        }
    }

    private var possessionScheduleSection: some View {
        Section(header: Text("Possession schedule (optional)")
                    .font(Font.custom("Avenir-Book", size: 16))
                    .foregroundColor(Color(hex: "388083"))) {
            TextEditor(text: $possessionSchedule)
                .font(Font.custom("Avenir-Book", size: 16))
                .frame(height: 150)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .gray.opacity(0.2), radius: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .focused($focusedField, equals: "possessionSchedule")
                .submitLabel(.done)
        }
    }

    private var divorceDecreeSection: some View {
        Section {
            Button {
                showDocumentPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(GCPTheme.primary)
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: 8).fill(GCPTheme.mint.opacity(0.6)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upload decree or order")
                            .font(GCPTheme.bodyMedium(15))
                            .foregroundStyle(GCPTheme.primary)
                        Text("PDF or photo — we extract text for better chat guidance")
                            .font(GCPTheme.caption(12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isExtractingDecree {
                        ProgressView()
                    }
                }
            }
            .disabled(isExtractingDecree)
            
            if let url = divorceDecreeURL {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(url.lastPathComponent)
                            .font(GCPTheme.body(14))
                            .foregroundStyle(GCPTheme.primary)
                            .lineLimit(2)
                        if isExtractingDecree {
                            Text("Reading full document (all pages)…")
                                .font(GCPTheme.caption(12))
                                .foregroundStyle(.secondary)
                        } else if let stats = decreeExtractionStats {
                            Text(stats)
                                .font(GCPTheme.caption(12))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if let conf = decreeConfidence {
                            Text("Parsed · \(Int(conf * 100))% confidence")
                                .font(GCPTheme.caption(12))
                                .foregroundStyle(.secondary)
                        } else if let text = divorceDecreeText, !text.isEmpty {
                            Text("\(text.count.formatted()) characters extracted")
                                .font(GCPTheme.caption(12))
                                .foregroundStyle(.secondary)
                        }
                        if let summary = decreeParseSummary, !summary.isEmpty {
                            Text(summary)
                                .font(GCPTheme.caption(12))
                                .foregroundStyle(GCPTheme.primary.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 4)
                    Button {
                        ensureDocumentAccess()
                        showDocumentViewer = true
                    } label: {
                        Image(systemName: "eye")
                            .foregroundStyle(GCPTheme.primary)
                    }
                    Button(role: .destructive) {
                        clearDecree()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        } header: {
            Text("Court order / decree")
        } footer: {
            Text("Optional. Improves schedule, support, and custody-aware answers. Stored on your device; not shared publicly.")
        }
    }

    private var conflictLevelSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Day-to-day conflict")
                        .font(GCPTheme.body(15))
                        .foregroundStyle(GCPTheme.primary)
                    Spacer()
                    Text(conflictLabel(conflictLevel))
                        .font(GCPTheme.caption(12))
                        .foregroundStyle(GCPTheme.primary.opacity(0.75))
                }
                Slider(value: Binding(
                    get: { Double(conflictLevel) },
                    set: { conflictLevel = Int($0.rounded()) }
                ), in: 1...10, step: 1)
                .tint(GCPTheme.primary)
                Text("1 = cooperative · 10 = high conflict. This changes how Gentler Coparent coaches you.")
                    .font(GCPTheme.caption(11))
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Communication climate")
        }
    }
    
    private func conflictLabel(_ level: Int) -> String {
        switch level {
        case 1...3: return "\(level) · Cooperative"
        case 4...6: return "\(level) · Tense"
        default: return "\(level) · High conflict"
        }
    }
    
    private func clearDecree() {
        divorceDecreeURL = nil
        divorceDecreeBookmark = nil
        divorceDecreeText = nil
        decreeParseSummary = nil
        decreeConfidence = nil
        decreeExtractionStats = nil
    }

    // MARK: - Functions

    func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: "userProfile") {
            do {
                let savedProfile = try JSONDecoder().decode(UserProfile.self, from: data)
                userFirstName = savedProfile.userFirstName
                userLastName = savedProfile.userLastName
                coparentFirstName = savedProfile.coparentFirstName
                coparentLastName = savedProfile.coparentLastName
                children = savedProfile.children.isEmpty ? [UserProfile.Child(
                    birthday: Calendar.current.dateComponents([.year, .month, .day], from: Date())
                )] : savedProfile.children
                stateOfResidence = savedProfile.stateOfResidence
                country = savedProfile.country
                conflictLevel = savedProfile.conflictLevel
                possessionSchedule = savedProfile.possessionSchedule ?? ""
                divorceDecreeURL = savedProfile.divorceDecreeURL
                divorceDecreeBookmark = savedProfile.divorceDecreeBookmark
                divorceDecreeText = savedProfile.divorceDecreeText
                
                // Migrate existing document to DocumentStorageManager if not already there
                Task {
                    await migrateExistingDocumentToStorageManager()
                }
                
                // If we have a bookmark but no valid URL, try to restore from bookmark
                if let bookmarkData = savedProfile.divorceDecreeBookmark, savedProfile.divorceDecreeURL == nil {
                    restoreFromSecurityScopedBookmark(bookmarkData)
                }
                
                print("Profile loaded successfully: \(savedProfile)")
            } catch {
                print("Failed to load profile: \(error)")
                children = [UserProfile.Child(
                    birthday: Calendar.current.dateComponents([.year, .month, .day], from: Date())
                )]
            }
        } else {
            print("No saved profile found in UserDefaults.")
            userFirstName = ""
            userLastName = ""
            coparentFirstName = ""
            coparentLastName = ""
            children = [UserProfile.Child(
                birthday: Calendar.current.dateComponents([.year, .month, .day], from: Date())
            )]
            stateOfResidence = ""
            country = "United States"
            conflictLevel = 1
            possessionSchedule = ""
            divorceDecreeURL = nil
            divorceDecreeBookmark = nil
            divorceDecreeText = nil
        }
    }

    func saveProfile() {
        audioManager.triggerHapticFeedback(.success)
        let profile = UserProfile(
            userFirstName: userFirstName,
            userLastName: userLastName,
            coparentFirstName: coparentFirstName,
            coparentLastName: coparentLastName,
            children: children,
            stateOfResidence: stateOfResidence,
            country: country,
            conflictLevel: conflictLevel,
            possessionSchedule: possessionSchedule.isEmpty ? nil : possessionSchedule,
            divorceDecreeURL: divorceDecreeURL,
            divorceDecreeBookmark: divorceDecreeBookmark,
            divorceDecreeText: divorceDecreeText
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(profile)
            UserDefaults.standard.set(data, forKey: "userProfile")
            print("Profile saved successfully: \(profile)")
            
            // Sync to iCloud
            syncProfileToiCloud(profile)
            
            saveSuccess = true
            saveMessage = "Profile saved successfully!"
        } catch {
            print("Failed to save profile: \(error)")
            saveSuccess = false
            saveMessage = "Failed to save profile: \(error.localizedDescription)"
        }
        showSaveAlert = true
    }
    
    // Sync profile to iCloud
    private func syncProfileToiCloud(_ profile: UserProfile) {
        let iCloudSync = iCloudSyncManager.shared
        
        print("🔄 Attempting to sync profile to iCloud...")
        print("Profile details: \(profile.userFirstName), children: \(profile.children.count)")
        
        guard iCloudSync.isiCloudAvailable else {
            print("❌ iCloud not available, profile sync skipped")
            return
        }
        
        print("✅ iCloud is available, proceeding with sync...")
        
        iCloudSync.syncUserProfile(profile) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("✅ Profile synced to iCloud successfully!")
                case .failure(let error):
                    print("❌ Failed to sync profile to iCloud: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Full pipeline: OCR (incl. scanned PDFs) → store text → parse → auto-fill profile fields.
    @MainActor
    func processDecreeDocument(url: URL) async {
        isExtractingDecree = true
        decreeParseSummary = nil
        decreeConfidence = nil
        decreeExtractionStats = nil
        defer { isExtractingDecree = false }
        
        // Full document extraction (all pages)
        let detailed = await DocumentTextExtractor.extractDetailed(from: url)
        let text = detailed?.text
        divorceDecreeText = text
        
        if let detailed {
            var parts: [String] = []
            parts.append("\(detailed.pageCount) page\(detailed.pageCount == 1 ? "" : "s")")
            parts.append("\(detailed.text.count.formatted()) characters")
            if detailed.usedOCR {
                parts.append("OCR on \(detailed.pagesOCR) page\(detailed.pagesOCR == 1 ? "" : "s")")
            } else {
                parts.append("native PDF text")
            }
            if detailed.pagesWithNativeText > 0 && detailed.usedOCR {
                parts.append("\(detailed.pagesWithNativeText) with embedded text")
            }
            decreeExtractionStats = parts.joined(separator: " · ")
        }
        
        guard let text, !text.isEmpty else {
            decreeParseSummary = "Couldn’t read text from this file. Try a clearer photo or a text-based PDF."
            return
        }
        
        let parser = DivorceDecreeParser()
        if let parsed = parser.parseExtractedText(text) {
            decreeConfidence = parsed.parsingConfidence
            applyParsedDecree(parsed)
            decreeParseSummary = buildParseSummary(parsed)
        } else {
            decreeParseSummary = "Full text extracted (\(text.count.formatted()) chars). Save profile so chat can use this context."
        }
    }
    
    private func applyParsedDecree(_ parsed: DivorceDecreeParser.ParsedDivorceDecree) {
        // Fill empty co-parent / user names carefully from petitioner/respondent
        let petitioner = parsed.parties.petitioner?.trimmingCharacters(in: .whitespacesAndNewlines)
        let respondent = parsed.parties.respondent?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Prefer filling blanks only — never overwrite what the user already typed
        if userFirstName.isEmpty, let p = petitioner, let first = p.split(separator: " ").first {
            userFirstName = String(first)
        }
        if coparentFirstName.isEmpty, let r = respondent, let first = r.split(separator: " ").first {
            coparentFirstName = String(first)
        }
        
        // Children: only if user hasn't named kids yet
        let userHasNamedChild = children.contains { !$0.firstName.trimmingCharacters(in: .whitespaces).isEmpty }
        if !userHasNamedChild, !parsed.children.isEmpty {
            children = parsed.children.prefix(6).map { child in
                var comps = DateComponents()
                if let bd = child.birthDate {
                    comps = Calendar.current.dateComponents([.year, .month, .day], from: bd)
                } else {
                    comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                }
                let parts = child.name.split(separator: " ").map(String.init)
                return UserProfile.Child(
                    firstName: parts.first ?? child.name,
                    lastName: parts.count > 1 ? parts.dropFirst().joined(separator: " ") : "",
                    birthday: comps,
                    gender: child.gender ?? "Rather not say"
                )
            }
        }
        
        // Possession schedule from visitation + custody
        if possessionSchedule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            var scheduleBits: [String] = []
            if !parsed.custodyArrangement.details.isEmpty {
                scheduleBits.append(parsed.custodyArrangement.details)
            } else if parsed.custodyArrangement.type != .unknown {
                scheduleBits.append("Custody: \(parsed.custodyArrangement.type.rawValue)")
            }
            if let std = parsed.schedule.standardSchedule { scheduleBits.append(std) }
            if let weekend = parsed.schedule.weekendSchedule { scheduleBits.append("Weekends: \(weekend)") }
            if let exchange = parsed.schedule.exchangeLocation { scheduleBits.append("Exchange: \(exchange)") }
            if let support = parsed.financialTerms.childSupport?.amount {
                let freq = parsed.financialTerms.childSupport?.frequency ?? ""
                scheduleBits.append("Child support: \(support) \(freq)".trimmingCharacters(in: .whitespaces))
            }
            if !scheduleBits.isEmpty {
                possessionSchedule = scheduleBits.joined(separator: "\n")
            }
        }
        
        updateFormValidation()
    }
    
    private func buildParseSummary(_ parsed: DivorceDecreeParser.ParsedDivorceDecree) -> String {
        var parts: [String] = []
        if let p = parsed.parties.petitioner { parts.append("Party: \(p)") }
        if let r = parsed.parties.respondent { parts.append("Other party: \(r)") }
        if !parsed.children.isEmpty {
            let names = parsed.children.map(\.name).joined(separator: ", ")
            parts.append("Children: \(names)")
        }
        if parsed.custodyArrangement.type != .unknown {
            parts.append("Custody: \(parsed.custodyArrangement.type.rawValue)")
        }
        if let amount = parsed.financialTerms.childSupport?.amount {
            parts.append("Support: \(amount)")
        }
        if parts.isEmpty {
            return "Text extracted (\(parsed.rawText.count) chars). Review fields and save."
        }
        return "Auto-filled from document: " + parts.prefix(4).joined(separator: " · ")
    }
    
    // MARK: - Form Validation & Progress
    private func updateFormValidation() {
        // Calculate completion percentage based on required fields
        var completedFields = 0
        let totalRequiredFields = 5 // userFirstName, coparentFirstName, children with names, conflictLevel, country
        
        // Required fields validation
        if !userFirstName.isEmpty {
            completedFields += 1
            fieldValidation["userFirstName"] = true
        } else {
            fieldValidation["userFirstName"] = false
        }
        
        if !coparentFirstName.isEmpty {
            completedFields += 1
            fieldValidation["coparentFirstName"] = true
        } else {
            fieldValidation["coparentFirstName"] = false
        }
        
        // Children validation - at least one child with first name
        let hasValidChild = children.contains { !$0.firstName.isEmpty }
        if hasValidChild {
            completedFields += 1
            fieldValidation["children"] = true
        } else {
            fieldValidation["children"] = false
        }
        
        // Conflict level (always has default)
        completedFields += 1
        fieldValidation["conflictLevel"] = true
        
        // Country (always has default)
        completedFields += 1
        fieldValidation["country"] = true
        
        // Update completion percentage with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            completionPercentage = (Double(completedFields) / Double(totalRequiredFields)) * 100
        }
        
        // Provide smart defaults for children
        if children.isEmpty {
            children = [UserProfile.Child(
                firstName: "",
                lastName: "",
                birthday: Calendar.current.dateComponents([.year, .month, .day], from: Date()),
                gender: "Rather not say"
            )]
        }
        
        // Auto-suggest gender based on name if empty
        for index in children.indices {
            if children[index].gender == "Rather not say" && !children[index].firstName.isEmpty {
                children[index].gender = suggestGender(for: children[index].firstName)
            }
        }
    }
    
    private func suggestGender(for name: String) -> String {
        let lowercaseName = name.lowercased()
        
        // Common male names
        let maleNames = ["james", "john", "robert", "michael", "david", "william", "richard", "joseph", "thomas", "christopher", "charles", "daniel", "matthew", "anthony", "mark", "donald", "steven", "paul", "andrew", "joshua", "kenneth", "kevin", "brian", "george", "timothy", "ronald", "jason", "edward", "jeffrey", "ryan", "jacob", "gary", "nicholas", "eric", "jonathan", "stephen", "larry", "justin", "scott", "brandon", "benjamin", "samuel", "gregory", "alexander", "patrick", "frank", "raymond", "jack", "dennis", "jerry", "tyler", "aaron", "jose", "henry", "adam", "douglas", "nathan", "peter", "zachary", "kyle", "noah", "alan", "ethan", "jeremy", "lionel", "angel", "mike", "oliver", "jose", "kevin", "sean", "bennet", "isaac", "luke", "gabriel", "owen", "dylan", "wyatt", "nathan", "lucas", "miles", "mason", "theo", "julian", "connor", "cole", "santiago"]
        
        // Common female names  
        let femaleNames = ["mary", "patricia", "linda", "barbara", "elizabeth", "jennifer", "maria", "susan", "margaret", "dorothy", "lisa", "nancy", "karen", "betty", "helen", "sandra", "donna", "carol", "ruth", "sharon", "michelle", "laura", "sarah", "kimberly", "deborah", "dorothy", "lisa", "nancy", "karen", "betty", "helen", "sandra", "donna", "carol", "ruth", "sharon", "michelle", "laura", "sarah", "kimberly", "deborah", "amy", "angela", "ashley", "brenda", "emma", "olivia", "cynthia", "marie", "janet", "catherine", "frances", "christine", "samantha", "debra", "rachel", "carolyn", "janet", "virginia", "catherine", "maria", "heather", "diane", "ruth", "julie", "joyce", "victoria", "kelly", "christina", "joan", "evelyn", "lauren", "judith", "megan", "cheryl", "andrea", "hannah", "jacqueline", "martha", "gloria", "sara", "janice", "ann", "kathryn", "abigail", "sophia", "frances", "jean", "alice", "judy", "isabella", "julia", "grace", "amber", "denise", "danielle", "marilyn", "beverly", "charlotte", "marie"]
        
        if maleNames.contains(lowercaseName) {
            return "M"
        } else if femaleNames.contains(lowercaseName) {
            return "F"
        }
        
        return "Rather not say"
    }
    
    // MARK: - Document Management Functions
    private func copyDocumentToAppDirectory(from sourceURL: URL) async {
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            // First, try to create security-scoped bookmark for persistent access across app updates
            let bookmarkData: Data
            if #available(iOS 8.0, *) {
                bookmarkData = try sourceURL.bookmarkData(
                    options: [],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
            } else {
                bookmarkData = try sourceURL.bookmarkData(
                    options: [],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
            }
            
            // Prefer a durable copy in Documents so OCR/chat keep working after relaunch
            let durableURL = await makeDurableCopy(from: sourceURL) ?? sourceURL
            divorceDecreeURL = durableURL
            divorceDecreeBookmark = bookmarkData
            
            await processDecreeDocument(url: durableURL)
            await storeDocumentInManager(url: durableURL)
            
            print("✅ Decree stored and processed")
            
        } catch {
            print("⚠️ Failed to create security-scoped bookmark (\(error)), falling back to copy method")
            await fallbackCopyToAppDirectory(from: sourceURL)
        }
    }
    
    private func makeDurableCopy(from sourceURL: URL) async -> URL? {
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let ext = sourceURL.pathExtension.isEmpty ? "pdf" : sourceURL.pathExtension
            let fileName = "divorce_decree.\(ext)"
            let destinationURL = documentsDirectory.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Durable copy failed: \(error)")
            return nil
        }
    }
    
    private func fallbackCopyToAppDirectory(from sourceURL: URL) async {
        if let destinationURL = await makeDurableCopy(from: sourceURL) {
            divorceDecreeURL = destinationURL
            divorceDecreeBookmark = nil
            await processDecreeDocument(url: destinationURL)
            await storeDocumentInManager(url: destinationURL)
            print("📁 Used fallback copy method")
        } else {
            print("❌ Failed to copy document")
            decreeParseSummary = "Couldn’t import that file. Try again."
        }
    }
    
    // MARK: - Document Access Management
    private func ensureDocumentAccess() {
        // If we have a URL but it might be stale, or if we only have a bookmark, try to restore access
        if let bookmarkData = divorceDecreeBookmark {
            // Check if current URL is accessible, if not try to restore from bookmark
            if let currentURL = divorceDecreeURL {
                let canAccess = currentURL.startAccessingSecurityScopedResource()
                if canAccess {
                    currentURL.stopAccessingSecurityScopedResource()
                    return // URL is still valid
                }
            }
            
            // Current URL is invalid or doesn't exist, restore from bookmark
            restoreFromSecurityScopedBookmark(bookmarkData)
        }
    }
    
    // MARK: - Security-Scoped Bookmark Restoration
    private func restoreFromSecurityScopedBookmark(_ bookmarkData: Data) {
        do {
            var isStale = false
            let restoredURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                print("⚠️ Security-scoped bookmark is stale, attempting to create new one")
                // Bookmark is stale, try to create a new one
                if restoredURL.startAccessingSecurityScopedResource() {
                    defer { restoredURL.stopAccessingSecurityScopedResource() }
                    
                    do {
                        let newBookmarkData = try restoredURL.bookmarkData(
                            options: [],
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )
                        divorceDecreeBookmark = newBookmarkData
                        print("✅ Created fresh security-scoped bookmark")
                    } catch {
                        print("❌ Failed to create fresh bookmark: \(error)")
                    }
                }
            }
            
            // Set the restored URL
            divorceDecreeURL = restoredURL
            print("✅ Successfully restored divorce decree access from security-scoped bookmark")
            
        } catch {
            print("❌ Failed to restore from security-scoped bookmark: \(error)")
            
            // Clear invalid bookmark data
            divorceDecreeBookmark = nil
            divorceDecreeURL = nil
        }
    }
    
    // MARK: - Document Migration
    private func migrateExistingDocumentToStorageManager() async {
        guard let documentURL = divorceDecreeURL else { return }
        
        // Check if already stored in DocumentStorageManager
        if documentStorageManager.getPrimaryDivorceDecree() != nil {
            print("📄 Document already exists in DocumentStorageManager")
            return
        }
        
        await storeDocumentInManager(url: documentURL)
    }
    
    // MARK: - Document Storage Helper
    @MainActor
    private func storeDocumentInManager(url: URL) async {
        print("📄 Attempting to store document in DocumentStorageManager...")
        let success = await documentStorageManager.storeDocument(url: url, type: .divorceDecree)
        if success {
            print("✅ Document successfully stored in DocumentStorageManager for chat integration")
            print("📄 DocumentStorageManager now has \(documentStorageManager.storedDocuments.count) documents")
        } else {
            print("❌ Failed to store document in DocumentStorageManager")
        }
    }
    
}

extension Date {
    static func from(_ components: DateComponents) -> Date? {
        Calendar.current.date(from: components)
    }
}

// Color extension is defined in Extensions.swift

struct ProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSetupView()
    }
}
