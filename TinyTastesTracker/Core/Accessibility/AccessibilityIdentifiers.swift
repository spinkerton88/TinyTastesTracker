//
//  AccessibilityIdentifiers.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/14/26.
//

import Foundation

/// Centralized accessibility identifiers and labels for VoiceOver support
enum AccessibilityIdentifiers {
    
    // MARK: - Onboarding
    
    enum Onboarding {
        static let welcomeTitle = "Welcome to Tiny Tastes Tracker"
        static let welcomeSubtitle = "Your companion from birth to bites"
        static let getStartedButton = "Get Started Button"
        static let skipTourButton = "Skip Tour Button"
        
        static let tourPageIndicator = "Tour Page Indicator"
        static let nextButton = "Next Button"
        static let previousButton = "Previous Button"
        static let doneButton = "Done with Tour Button"
        
        static let profileSetupTitle = "Set Up Your Child's Profile"
        static let babyNameField = "Baby Name Text Field"
        static let birthdateField = "Birth Date Picker"
        static let saveProfileButton = "Save Profile Button"
    }
    
    // MARK: - Navigation
    
    enum Navigation {
        static let tabBar = "Main Tab Bar"
        static let newbornTab = "Newborn Tab"
        static let explorerTab = "Explorer Tab"
        static let toddlerTab = "Toddler Tab"
        static let analysisTab = "Analysis Tab"
        static let settingsTab = "Settings Tab"
        
        static let profileSwitcher = "Profile Switcher"
        static let addProfileButton = "Add New Profile Button"
    }
    
    // MARK: - Sage AI
    
    enum Sage {
        static let sageButton = "Ask Sage AI Assistant"
        static let sageMenuTitle = "Sage Assistant Menu"
        static let closeButton = "Close Sage"
        
        static let sleepPredictionButton = "Predict Sleep Window"
        static let flavorPairingsButton = "Find Flavor Pairings"
        static let recipeButton = "Suggest a Recipe"
        static let pickyEaterButton = "Picky Eater Strategy"
        static let chatButton = "Ask a Question"
        static let voiceChatButton = "Voice Chat"
        
        static let chatInput = "Chat Message Input"
        static let sendButton = "Send Message Button"
        static let voiceRecordButton = "Record Voice Message"
        static let stopRecordingButton = "Stop Recording"
        
        static let loadingIndicator = "Sage is thinking"
        static let resultCard = "Sage Result Card"
        static let saveButton = "Save to Cookbook"
    }
    
    // MARK: - Newborn
    
    enum Newborn {
        static let pageTitle = "Newborn Tracking"
        static let logFeedButton = "Log Feeding"
        static let logSleepButton = "Log Sleep"
        static let logDiaperButton = "Log Diaper Change"
        static let trackGrowthButton = "Track Growth"
        
        static let feedingSheet = "Feeding Log Sheet"
        static let feedingTypeSegment = "Feeding Type Selector"
        static let breastSideSegment = "Breast Side Selector"
        static let durationPicker = "Duration Picker"
        static let volumeField = "Volume Text Field"
        static let notesField = "Notes Text Field"
        static let saveFeedingButton = "Save Feeding Log"
        
        static let sleepSheet = "Sleep Log Sheet"
        static let sleepStartPicker = "Sleep Start Time"
        static let sleepEndPicker = "Sleep End Time"
        static let sleepQualityPicker = "Sleep Quality Picker"
        static let saveSleepButton = "Save Sleep Log"
        
        static let growthSheet = "Growth Tracking Sheet"
        static let weightField = "Weight Text Field"
        static let heightField = "Height Text Field"
        static let headCircumferenceField = "Head Circumference Text Field"
        static let saveGrowthButton = "Save Growth Measurement"
    }
    
    // MARK: - Explorer (Food Tracking)
    
    enum Explorer {
        static let pageTitle = "Food Explorer"
        static let searchField = "Search Foods"
        static let filterButton = "Filter Foods"
        static let categoryPicker = "Food Category Picker"
        
        static let foodCard = "Food Card"
        static let foodName = "Food Name"
        static let allergenWarning = "Allergen Warning"
        static let nutritionInfo = "Nutrition Information"
        static let logFoodButton = "Log This Food"
        
        static let reactionPicker = "Reaction Rating Picker"
        static let foodNotesField = "Food Notes"
        static let saveFoodLogButton = "Save Food Log"
        
        static let rainbowProgress = "Rainbow Progress Chart"
        static let nutritionBalance = "Nutrition Balance Chart"
    }
    
    // MARK: - Toddler
    
    enum Toddler {
        static let pageTitle = "Toddler Features"
        static let mealPlanTab = "Meal Plan Tab"
        static let recipesTab = "Recipes Tab"
        
        static let generateMealPlanButton = "Generate Meal Plan"
        static let mealPlanCard = "Meal Plan Card"
        static let addToShoppingListButton = "Add to Shopping List"
        
        static let recipeCard = "Recipe Card"
        static let recipeTitle = "Recipe Title"
        static let ingredientsList = "Ingredients List"
        static let instructionsList = "Instructions List"
        static let scanRecipeButton = "Scan Recipe with Camera"
        static let saveRecipeButton = "Save Recipe"
    }
    
    // MARK: - Analysis
    
    enum Analysis {
        static let pageTitle = "Analysis Dashboard"
        static let growthChart = "Growth Chart"
        static let sleepChart = "Sleep Patterns Chart"
        static let foodVarietyChart = "Food Variety Chart"
        static let nutritionChart = "Nutrition Balance Chart"
        
        static let dateRangePicker = "Date Range Picker"
        static let exportButton = "Export Data"
        static let shareButton = "Share Report"
    }
    
    // MARK: - Settings
    
    enum Settings {
        static let pageTitle = "Settings"
        static let profileSection = "Profile Settings"
        static let dataSection = "Data Management"
        static let privacySection = "Privacy Settings"
        static let aboutSection = "About"
        
        static let editProfileButton = "Edit Profile"
        static let allergiesButton = "Known Allergies"
        static let milestonesButton = "Milestones"
        static let badgesButton = "Badges"
        
        static let exportDataButton = "Export Data"
        static let importDataButton = "Import Data"
        static let deleteDataButton = "Delete All Data"
        
        static let privacyPolicyButton = "Privacy Policy"
        static let dataHandlingButton = "Data Handling"
        static let deleteAccountButton = "Delete Account"
    }
    
    // MARK: - Common
    
    enum Common {
        static let closeButton = "Close"
        static let cancelButton = "Cancel"
        static let saveButton = "Save"
        static let deleteButton = "Delete"
        static let editButton = "Edit"
        static let doneButton = "Done"
        static let backButton = "Back"
        static let nextButton = "Next"
        
        static let loadingIndicator = "Loading"
        static let errorAlert = "Error Alert"
        static let successAlert = "Success Alert"
        
        static let datePicker = "Date Picker"
        static let timePicker = "Time Picker"
        static let searchField = "Search"
    }
}

// MARK: - Accessibility Labels

extension AccessibilityIdentifiers {
    
    /// Generate a descriptive label for a reaction rating
    static func reactionLabel(for rating: Int) -> String {
        switch rating {
        case 1: return "Strongly disliked, 1 out of 5 stars"
        case 2: return "Disliked, 2 out of 5 stars"
        case 3: return "Neutral reaction, 3 out of 5 stars"
        case 4: return "Liked, 4 out of 5 stars"
        case 5: return "Loved, 5 out of 5 stars"
        default: return "Not rated"
        }
    }
    
    /// Generate a descriptive label for sleep quality
    static func sleepQualityLabel(for quality: String) -> String {
        switch quality.lowercased() {
        case "poor": return "Poor sleep quality"
        case "fair": return "Fair sleep quality"
        case "good": return "Good sleep quality"
        case "excellent": return "Excellent sleep quality"
        default: return "Sleep quality: \(quality)"
        }
    }
    
    /// Generate a descriptive label for feeding type
    static func feedingTypeLabel(for type: String) -> String {
        switch type.lowercased() {
        case "breast": return "Breastfeeding"
        case "bottle": return "Bottle feeding"
        case "solid": return "Solid food"
        default: return "Feeding type: \(type)"
        }
    }
    
    /// Generate a descriptive hint for a button action
    static func actionHint(for action: String) -> String {
        "Double tap to \(action)"
    }
}
