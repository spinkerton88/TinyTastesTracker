//
//  PrivacyPolicyView.swift
//  TinyTastesTracker
//
//  Created by Antigravity on 1/12/26.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var privacyPolicyText: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if privacyPolicyText.isEmpty {
                        // Fallback if file can't be loaded
                        privacyPolicySummary
                    } else {
                        Text(privacyPolicyText)
                            .font(.body)
                            .padding()
                    }
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: privacyPolicyURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .onAppear {
                loadPrivacyPolicy()
            }
        }
    }
    
    // MARK: - Privacy Policy Summary (Fallback)
    
    private var privacyPolicySummary: some View {
        VStack(alignment: .leading, spacing: 24) {
            Group {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Last Updated: January 12, 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            Group {
                sectionHeader("What We Collect")
                bulletPoint("Child profile information (name, date of birth, allergens)")
                bulletPoint("Health tracking data (meals, sleep, growth, diapers)")
                bulletPoint("Recipes and meal plans you create")
                bulletPoint("Photos you upload (optional)")
                bulletPoint("AI chat messages (when you use Sage AI)")
            }
            
            Group {
                sectionHeader("How We Store Your Data")
                bulletPoint("Most data is stored locally on your device")
                bulletPoint("Protected by iOS encryption and your device passcode")
                bulletPoint("Included in iCloud/iTunes backups")
                bulletPoint("AI features send data to Google Gemini (questions, photos, child's age)")
            }
            
            Group {
                sectionHeader("Third-Party Services")
                bulletPoint("Google Gemini AI - AI recommendations and food analysis")
                bulletPoint("Open Food Facts - Nutrition data for packaged foods")
                bulletPoint("Apple Reminders - Shopping list sync (optional)")
            }
            
            Group {
                sectionHeader("Your Rights")
                bulletPoint("Access: View all your data in the app")
                bulletPoint("Export: Download your data in JSON or CSV format")
                bulletPoint("Delete: Remove specific data or all data anytime")
                bulletPoint("Control: Choose which features to use")
            }
            
            Group {
                sectionHeader("What We DON'T Do")
                bulletPoint("We don't sell your data")
                bulletPoint("We don't track you across apps or websites")
                bulletPoint("We don't use your data for advertising")
                bulletPoint("We don't collect email, phone, or location")
            }
            
            Group {
                sectionHeader("Children's Privacy (COPPA)")
                bulletPoint("App is designed for parents (18+), not children")
                bulletPoint("Parents provide information about their children")
                bulletPoint("We don't knowingly collect data from children under 13")
                bulletPoint("Parents have full control over their child's data")
            }
            
            Group {
                sectionHeader("GDPR Compliance")
                bulletPoint("Right to access, rectify, erase, and export data")
                bulletPoint("Data minimization - we only collect what's necessary")
                bulletPoint("Transparent data practices")
                bulletPoint("User control over data processing")
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("For the complete privacy policy, visit:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Link("tinytastestracker.com/privacy", destination: privacyPolicyURL)
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Questions or concerns?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Email: privacy@tinytastestracker.com")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.top, 8)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .fontWeight(.bold)
            Text(text)
                .font(.subheadline)
        }
    }
    
    // MARK: - Load Privacy Policy
    
    private func loadPrivacyPolicy() {
        // Try to load from bundle or local file
        if let url = Bundle.main.url(forResource: "PRIVACY_POLICY", withExtension: "md"),
           let content = try? String(contentsOf: url) {
            privacyPolicyText = content
        } else {
            // File not found, use fallback summary
            privacyPolicyText = ""
        }
    }
    
    private var privacyPolicyURL: URL {
        // TODO: Replace with actual hosted URL before App Store submission
        URL(string: "https://tinytastestracker.com/privacy")!
    }
}

#Preview {
    PrivacyPolicyView()
}
