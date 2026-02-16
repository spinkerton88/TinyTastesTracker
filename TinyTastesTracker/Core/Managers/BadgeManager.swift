//
//  BadgeManager.swift
//  TinyTastesTracker
//
//  Manages logic for unlocking badges based on user activity
//

import Foundation

@MainActor
class BadgeManager {
    static let shared = BadgeManager()
    
    private init() {}
    
    /// Checks and updates badge progress based on AppState logs
    /// Returns the updated list of badges if changes occurred, otherwise returns nil
    func checkBadges(for profile: ChildProfile, appState: AppState) -> [Badge]? {
        guard let badges = profile.badges else { return nil }
        
        var updatedBadges = badges
        var hasChanges = false
        
        // Filter badges by category to optimize checks
        let explorerBadges = updatedBadges.filter { $0.category == .explorer }
        if !explorerBadges.isEmpty {
            if updateExplorerBadges(&updatedBadges, appState: appState) {
                hasChanges = true
            }
        }
        
        let newbornBadges = updatedBadges.filter { $0.category == .newborn }
        if !newbornBadges.isEmpty {
            if updateNewbornBadges(&updatedBadges, appState: appState) {
                hasChanges = true
            }
        }
        
        return hasChanges ? updatedBadges : nil
    }
    
    // MARK: - Explorer Logic
    private func updateExplorerBadges(_ badges: inout [Badge], appState: AppState) -> Bool {
        var hasChanges = false
        let triedFoods = appState.foodLogs // Assuming appState has foodLogs loaded
        let allFoods = appState.recipeManager.allKnownFoods

        // Helper to find food details
        func getFoodItem(for log: TriedFoodLog) -> FoodItem? {
            return allFoods.first { $0.id == log.foodName } // log.foodName is likely the storage key/ID
        }
        
        // Calculate Counts
        let greenVeggiesCount = triedFoods.filter { log in
            guard let item = getFoodItem(for: log) else { return false }
            return item.color == .green && item.category == .vegetables
        }.count
        
        let uniqueFoodsCount = Set(triedFoods.map { $0.foodName }).count
        
        let fruitCount = triedFoods.filter { log in
            guard let item = getFoodItem(for: log) else { return false }
            return item.category == .fruits
        }.count
        
        let proteinCount = triedFoods.filter { log in
            guard let item = getFoodItem(for: log) else { return false }
            return item.category == .proteins
        }.count
        
        // Update Badges
        for i in 0..<badges.count {
            if badges[i].category != .explorer { continue }
            
            var newProgress = badges[i].progress
            
            switch badges[i].type {
            case .greenMachine:
                newProgress = greenVeggiesCount
            case .firstTen:
                newProgress = uniqueFoodsCount
            case .fruitNinja:
                newProgress = fruitCount
            case .proteinPower:
                newProgress = proteinCount
            default:
                break
            }
            
            if updateBadgeStatus(&badges[i], progress: newProgress) {
                hasChanges = true
            }
        }
        
        return hasChanges
    }
    
    // MARK: - Newborn Logic
    private func updateNewbornBadges(_ badges: inout [Badge], appState: AppState) -> Bool {
        var hasChanges = false
        
        // Helper counts from AppState
        let sleepCount = appState.sleepLogs.count
        let nursingCount = appState.nursingLogs.count
        let bottleCount = appState.bottleFeedLogs.count
        let growthCount = appState.growthMeasurements.count
        
        let totalFeedCount = nursingCount + bottleCount
        
        for i in 0..<badges.count {
            if badges[i].category != .newborn { continue }
            
            var newProgress = badges[i].progress
            
            switch badges[i].type {
            case .sleepPro:
                newProgress = sleepCount
            case .milkMonster:
                newProgress = totalFeedCount
            case .growthChart:
                newProgress = growthCount
            default:
                break
            }
            
            if updateBadgeStatus(&badges[i], progress: newProgress) {
                hasChanges = true
            }
        }
        
        return hasChanges
    }
    
    private func updateBadgeStatus(_ badge: inout Badge, progress: Int) -> Bool {
        if badge.progress != progress {
            badge.progress = min(progress, badge.target) // Cap at target for UI
            
            if badge.progress >= badge.target && !badge.isUnlocked {
                badge.isUnlocked = true
                badge.dateUnlocked = Date()
            }
            return true
        }
        return false
    }
}
