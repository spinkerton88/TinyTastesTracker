//
//  BadgeManager.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/3/26.
//

import Foundation
import SwiftData

class BadgeManager {
    static let shared = BadgeManager()
    
    private init() {}
    
    func refreshBadges(for profile: UserProfile, context: ModelContext) {
        guard let badges = profile.badges else { return }
        
        let explorerBadges = badges.filter { $0.category == .explorer }
        if !explorerBadges.isEmpty {
            updateExplorerBadges(explorerBadges, for: profile, context: context)
        }
        
        let newbornBadges = badges.filter { $0.category == .newborn }
        if !newbornBadges.isEmpty {
            updateNewbornBadges(newbornBadges, for: profile, context: context)
        }
        
        // Save changes if any
        try? context.save()
    }
    
    // MARK: - Explorer Logic
    private func updateExplorerBadges(_ badges: [Badge], for profile: UserProfile, context: ModelContext) {
        // Fetch all tried foods (id is the food ID string)
        let triedFoodsDescriptor = FetchDescriptor<TriedFoodLog>()
        guard let allTriedFoods = try? context.fetch(triedFoodsDescriptor) else { return }
        
        // Helper to find food details
        func getFoodItem(for log: TriedFoodLog) -> FoodItem? {
            return Constants.allFoods.first { $0.id == log.id }
        }
        
        let greenVeggiesCount = allTriedFoods.filter { log in
            guard let item = getFoodItem(for: log) else { return false }
            return item.color == .green && item.category == .vegetables
        }.count
        
        // Count unique IDs
        let uniqueFoodsCount = Set(allTriedFoods.map { $0.id }).count
        
        let fruitCount = allTriedFoods.filter { log in
            guard let item = getFoodItem(for: log) else { return false }
            return item.category == .fruits
        }.count
        
        let proteinCount = allTriedFoods.filter { log in
            guard let item = getFoodItem(for: log) else { return false }
            return item.category == .proteins
        }.count
        
        for badge in badges {
            var newProgress = badge.progress
            
            switch badge.type {
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
            
            updateBadgeStatus(badge, progress: newProgress)
        }
    }
    
    // MARK: - Newborn Logic
    private func updateNewbornBadges(_ badges: [Badge], for profile: UserProfile, context: ModelContext) {
        // Fetch specific log types
        let sleepDescriptor = FetchDescriptor<SleepLog>()
        let nursingDescriptor = FetchDescriptor<NursingLog>()
        let bottleDescriptor = FetchDescriptor<BottleFeedLog>()
        let growthDescriptor = FetchDescriptor<GrowthMeasurement>()
        
        let sleepCount = (try? context.fetch(sleepDescriptor))?.count ?? 0
        let nursingCount = (try? context.fetch(nursingDescriptor))?.count ?? 0
        let bottleCount = (try? context.fetch(bottleDescriptor))?.count ?? 0
        let growthCount = (try? context.fetch(growthDescriptor))?.count ?? 0
        
        let totalFeedCount = nursingCount + bottleCount
        
        for badge in badges {
            var newProgress = badge.progress
            
            switch badge.type {
            case .sleepPro:
                newProgress = sleepCount
            case .milkMonster:
                newProgress = totalFeedCount
            case .growthChart:
                newProgress = growthCount
            default:
                break
            }
            
            updateBadgeStatus(badge, progress: newProgress)
        }
    }
    
    private func updateBadgeStatus(_ badge: Badge, progress: Int) {
        if badge.progress != progress {
            badge.progress = min(progress, badge.target) // Cap at target for UI
            
            if badge.progress >= badge.target && !badge.isUnlocked {
                badge.isUnlocked = true
                badge.dateUnlocked = Date()
            }
        }
    }
}
