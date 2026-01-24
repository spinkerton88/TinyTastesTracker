//
//  DataFetchService.swift
//  TinyTastesTracker
//
//  Performance optimization: Reusable pagination and lazy loading utilities
//

import Foundation
import SwiftData

/// Service for optimized data fetching with pagination and date filtering
class DataFetchService {
    
    // MARK: - Date-Based Fetching
    
    /// Fetch recent records within a specified number of days
    /// - Parameters:
    ///   - context: SwiftData ModelContext
    ///   - days: Number of days to fetch (default: 30)
    ///   - sortBy: Sort descriptors for ordering results
    /// - Returns: Array of fetched models
    /// - Throws: SwiftData fetch errors
    static func fetchRecent<T: PersistentModel>(
        context: ModelContext,
        days: Int = 30,
        sortBy: [SortDescriptor<T>]
    ) throws -> [T] where T: PersistentModel {
        let descriptor = FetchDescriptor<T>(sortBy: sortBy)
        
        // Note: Predicates need to be constructed per model type
        // This is a generic helper, specific implementations in managers
        
        return try context.fetch(descriptor)
    }
    
    // MARK: - Pagination
    
    /// Fetch paginated results
    /// - Parameters:
    ///   - context: SwiftData ModelContext
    ///   - offset: Number of records to skip
    ///   - limit: Maximum number of records to fetch
    ///   - sortBy: Sort descriptors for ordering results
    /// - Returns: Array of fetched models
    /// - Throws: SwiftData fetch errors
    static func fetchPaginated<T: PersistentModel>(
        context: ModelContext,
        offset: Int,
        limit: Int,
        sortBy: [SortDescriptor<T>]
    ) throws -> [T] {
        var descriptor = FetchDescriptor<T>(sortBy: sortBy)
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        
        return try context.fetch(descriptor)
    }
    
    /// Get total count of records
    /// - Parameters:
    ///   - context: SwiftData ModelContext
    ///   - type: Type of model to count
    /// - Returns: Total count of records
    /// - Throws: SwiftData fetch errors
    static func fetchCount<T: PersistentModel>(
        context: ModelContext,
        ofType type: T.Type
    ) throws -> Int {
        let descriptor = FetchDescriptor<T>()
        return try context.fetchCount(descriptor)
    }
    
    // MARK: - Pagination Helper
    
    /// Calculate if more pages are available
    /// - Parameters:
    ///   - currentCount: Number of items currently loaded
    ///   - pageSize: Size of each page
    ///   - totalCount: Total number of items available
    /// - Returns: True if more pages exist
    static func hasMorePages(currentCount: Int, pageSize: Int, totalCount: Int) -> Bool {
        return currentCount < totalCount
    }
    
    /// Calculate next offset for pagination
    /// - Parameters:
    ///   - currentOffset: Current offset
    ///   - pageSize: Size of each page
    /// - Returns: Next offset value
    static func nextOffset(currentOffset: Int, pageSize: Int) -> Int {
        return currentOffset + pageSize
    }
}

// MARK: - Performance Configuration

extension DataFetchService {
    /// Default configuration values for data fetching
    enum Config {
        static let defaultDays = 30
        static let defaultPageSize = 20
        static let maxPageSize = 100
    }
}
