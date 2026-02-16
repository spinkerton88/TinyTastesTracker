//
//  HealthManager.swift
//  TinyTastesTracker
//
//  Manages health-related data including pediatric summaries and allergy info
//

import Foundation
import SwiftUI
import Combine

import FirebaseFirestore

@Observable
class HealthManager {
    // MARK: - Properties
    var pediatricianSummaries: [PediatricianSummary] = []
    
    // Dependencies
    private let summaryService = FirestoreService<PediatricianSummary>(collectionName: "pediatrician_summaries")
    private var cancellables = Set<AnyCancellable>()
    private var listenerRegistration: ListenerRegistration?
    
    // MARK: - Data Loading
    
    func loadData(ownerId: String) {
        // Remove existing listener if any
        listenerRegistration?.remove()
        
        // Listen for summaries
        listenerRegistration = summaryService.addListener(forUserId: ownerId) { [weak self] summaries in
            self?.pediatricianSummaries = summaries.sorted(by: { $0.generatedAt > $1.generatedAt })
        }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
    }
    
    // MARK: - CRUD Operations
    
    func saveSummary(_ summary: PediatricianSummary) {
        // Optimistic Update
        var optimisticSummary = summary
        let summaryId = optimisticSummary.id ?? UUID().uuidString
        optimisticSummary.id = summaryId

        // Update local state immediately
        self.pediatricianSummaries.insert(optimisticSummary, at: 0)
        self.pediatricianSummaries.sort(by: { $0.generatedAt > $1.generatedAt })

        // Perform Firestore save
        Task {
            do {
                try await self.summaryService.add(optimisticSummary, withId: summaryId)
            } catch {
                print("Error saving summary: \(error)")
                // Rollback on failure
                await MainActor.run {
                    if let index = self.pediatricianSummaries.firstIndex(where: { $0.id == summaryId }) {
                        self.pediatricianSummaries.remove(at: index)
                    }
                }
            }
        }
    }
    
    func deleteSummary(_ summary: PediatricianSummary) {
        guard let id = summary.id else { return }
        
        // Optimistic Update
        Task { @MainActor in
            if let index = self.pediatricianSummaries.firstIndex(where: { $0.id == id }) {
                let removedItem = self.pediatricianSummaries.remove(at: index)
                
                // Perform Firestore delete (using detached task to avoid blocking)
                Task.detached {
                    do {
                        try await self.summaryService.delete(id: id)
                    } catch {
                        print("Error deleting summary: \(error)")
                        // Rollback on failure
                        await MainActor.run {
                            self.pediatricianSummaries.insert(removedItem, at: index)
                            self.pediatricianSummaries.sort(by: { $0.generatedAt > $1.generatedAt })
                        }
                    }
                }
            }
        }
    }
    
    func updateSummary(_ summary: PediatricianSummary) {
        Task {
            do {
                try await summaryService.update(summary)
            } catch {
                print("Error updating summary: \(error)")
            }
        }
    }
}
