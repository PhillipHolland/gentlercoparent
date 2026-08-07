import SwiftUI

struct PrivacyPolicyView: View {
    private let sections: [(title: String, body: String)] = [
        ("1. Introduction",
         "Welcome to Gentler Coparent. We are committed to protecting your privacy and the security of your information. This policy explains how we collect, use, disclose, and safeguard information when you use our app and related services."),
        ("2. Information We Collect",
         "We collect information you voluntarily provide—such as profile details, co-parenting context, messages you enter, and documents or screenshots you upload—so we can personalize guidance and improve your experience."),
        ("3. How We Use Information",
         "We use your information to operate Gentler Coparent, personalize responses, provide support, improve the product, and meet legal obligations. Conversations are not used to train public third-party AI products."),
        ("4. Sharing",
         "We do not sell or rent your personal information. Limited sharing may occur with service providers who help us run the product (for example infrastructure or authentication), under confidentiality obligations."),
        ("5. Security",
         "We use industry-standard protections including encrypted transport and access controls. You can also enable an on-device privacy lock (Face ID / Touch ID) in Preferences."),
        ("6. Children’s Privacy",
         "Gentler Coparent is intended for adults 18 and older. We do not knowingly collect personal information from children under 18."),
        ("7. Changes",
         "We may update this policy from time to time. Material changes will be reflected in the app or on our site with an updated effective date."),
        ("8. Contact",
         "Questions about privacy? Email info@gentlercoparent.com.")
    ]
    
    var body: some View {
        SettingsDetailShell(title: "Privacy Policy") {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Gentler Coparent Privacy Policy")
                        .font(GCPTheme.title(18))
                        .foregroundStyle(GCPTheme.primary)
                    
                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        SettingsArticleBlock(section.title, section.body)
                    }
                    
                    Text("By using Gentler Coparent, you acknowledge this privacy policy.")
                        .font(GCPTheme.caption(13))
                        .foregroundStyle(GCPTheme.primary.opacity(0.7))
                        .padding(.top, 4)
                }
                .padding(16)
            }
        }
    }
}
