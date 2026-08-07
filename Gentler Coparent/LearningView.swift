import SwiftUI

struct LearningView: View {
    @Environment(\.dismiss) var dismiss
    
    let learningTitles = [
        "A Comprehensive Guide for Protecting Yourself and Your Children",
        "Maintaining Your Well-being for Your Children's Sake",
        "Enhancing Communication and Understanding",
        "Blended Family Dynamics in Co-parenting",
        "Coping with Major Life Changes in Co-parenting",
        "The Unique Challenges of the Adolescent Years",
        "Co-parenting with a Special Needs Child",
        "Embracing Technology for the Modern Family",
        "Co-Parenting Finances: Best Practices",
        "Special Occasions in Co-parenting",
        "Communication Strategies for High-Conflict Co-parenting",
        "The Impact of Parental Conflict on Children",
        "Creating a Child-Centric Parenting Plan",
        "Introducing a New Romantic Partner in Coparenting",
        "Balancing Parenting and Personal Healing Post-Divorce",
        "Co-Parenting After Domestic Violence",
        "Identifying Harassing and Abusive Correspondence",
        "Gentler Coparent Can Transform Your Communication",
        "Navigating Legal Complexities in Coparenting",
        "Weathering the Storm in High-Conflict Coparenting",
        "Gentler Coparent vs. Our Family Wizard Tone Generator",
        "Is Your Co-Parent a Narcissist"
    ]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Learning")
                    .font(GCPTheme.title(22))
                    .foregroundStyle(GCPTheme.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                List {
                    ForEach(learningTitles, id: \.self) { title in
                        NavigationLink(destination: destinationView(for: title)
                            .navigationBarBackButtonHidden(true) // Hide back button
                            .navigationBarHidden(true) // Hide navigation bar entirely
                        ) {
                            HStack {
                                Image(systemName: "book.circle")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Color(hex: "388083"))
                                Text(title)
                                    .font(Font.custom("Avenir-Book", size: 16))
                                    .foregroundColor(Color(hex: "388083"))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color(hex: "388083").opacity(0.5))
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color(hex: "F6F6F2"))
                .cornerRadius(12)
                .padding(.horizontal, 10)

                Spacer()
            }
            .background(Color(hex: "BADFE7"))
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(Font.custom("Avenir-Book", size: 16))
                            .foregroundColor(Color(hex: "388083"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .shadow(color: .gray.opacity(0.2), radius: 2)
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 10)
                }
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for title: String) -> some View {
        switch title {
        case "A Comprehensive Guide for Protecting Yourself and Your Children":
            ComprehensiveGuideView()
        case "Maintaining Your Well-being for Your Children's Sake":
            MaintainingWellbeingView()
        case "Enhancing Communication and Understanding":
            EnhancingCommunicationView()
        case "Blended Family Dynamics in Co-parenting":
            BlendedFamilyDynamicsView()
        case "Coping with Major Life Changes in Co-parenting":
            CopingWithChangesView()
        case "The Unique Challenges of the Adolescent Years":
            AdolescentChallengesView()
        case "Co-parenting with a Special Needs Child":
            SpecialNeedsCoparentingView()
        case "Embracing Technology for the Modern Family":
            EmbracingTechnologyView()
        case "Co-Parenting Finances: Best Practices":
            CoparentingFinancesView()
        case "Special Occasions in Co-parenting":
            SpecialOccasionsView()
        case "Communication Strategies for High-Conflict Co-parenting":
            HighConflictStrategiesView()
        case "The Impact of Parental Conflict on Children":
            ParentalConflictImpactView()
        case "Creating a Child-Centric Parenting Plan":
            ChildCentricPlanView()
        case "Introducing a New Romantic Partner in Coparenting":
            NewPartnerIntroductionView()
        case "Balancing Parenting and Personal Healing Post-Divorce":
            BalancingHealingView()
        case "Co-Parenting After Domestic Violence":
            DomesticViolenceCoparentingView()
        case "Identifying Harassing and Abusive Correspondence":
            HarassingCorrespondenceView()
        case "Gentler Coparent Can Transform Your Communication":
            TransformCommunicationView()
        case "Navigating Legal Complexities in Coparenting":
            LegalComplexitiesView()
        case "Weathering the Storm in High-Conflict Coparenting":
            WeatheringStormView()
        case "Gentler Coparent vs. Our Family Wizard Tone Generator":
            GentlerVsWizardView()
        case "Is Your Co-Parent a Narcissist":
            NarcissistCoparentView()
        default:
            Text("View not found")
        }
    }
}

struct LearningView_Previews: PreviewProvider {
    static var previews: some View {
        LearningView()
    }
}
