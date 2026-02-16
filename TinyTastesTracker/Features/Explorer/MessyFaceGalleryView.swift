//
//  MessyFaceGalleryView.swift
//  TinyTastesTracker
//
//  Central gallery for all messy face photos with filtering and sorting
//

import SwiftUI

enum PhotoSortOption: String, CaseIterable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case foodName = "Food Name"
}

struct MessyFaceGalleryView: View {
    @Bindable var appState: AppState
    
    // Derived from appState instead of @Query
    private var logsWithPhotos: [TriedFoodLog] {
        appState.foodLogs.filter { $0.messyFaceImage != nil && $0.isMarkedAsTried == true }
            .sorted { $0.date > $1.date }
    }
    
    // Filter and sort state
    @State private var searchText = ""
    @State private var selectedMealType: MealType?
    @State private var sortOption: PhotoSortOption = .newest
    @State private var showFilters = false
    
    // Photo viewer state
    @State private var selectedLog: TriedFoodLog?
    @State private var showPhotoViewer = false
    
    // New feature states
    @State private var showCollageCreator = false
    @State private var showMemoryCreator = false
    @State private var showTimelineExport = false
    
    // Computed filtered and sorted logs
    private var filteredLogs: [TriedFoodLog] {
        var logs = logsWithPhotos
        
        // Filter by search text
        if !searchText.isEmpty {
            logs = logs.filter { ($0.id ?? "").localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filter by meal type
        if let mealType = selectedMealType {
            logs = logs.filter { $0.meal == mealType }
        }
        
        // Sort
        switch sortOption {
        case .newest:
            logs.sort { $0.date > $1.date }
        case .oldest:
            logs.sort { $0.date < $1.date }
        case .foodName:
            logs.sort { ($0.id ?? "") < ($1.id ?? "") }
        }
        
        return logs
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if logsWithPhotos.isEmpty {
                    emptyStateView
                } else {
                    photoGridView
                }
            }
            .navigationTitle("Messy Face Gallery")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
//                        Button {
//                            showCollageCreator = true
//                        } label: {
//                            Label("Create Collage", systemImage: "square.grid.2x2")
//                        }
//                        .disabled(logsWithPhotos.count < 2)
//                        
//                        Button {
//                            showMemoryCreator = true
//                        } label: {
//                            Label { Text("Create Memory") } icon: { Image("sage.leaf.sprig") }
//                        }
//                        .disabled(logsWithPhotos.count < 3)
//                        
//                        Divider()
                        
                        Button {
                            showTimelineExport = true
                        } label: {
                            Label("Export Timeline", systemImage: "square.and.arrow.up")
                        }
                        .disabled(logsWithPhotos.isEmpty)
                        
                        Divider()
                        
                        Button {
                            showFilters.toggle()
                        } label: {
                            Label(showFilters ? "Hide Filters" : "Show Filters", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(appState.themeColor)
                            .accessibilityLabel("Gallery Options")
                    }
                }
            }
            .sheet(isPresented: $showPhotoViewer) {
                if let log = selectedLog {
                    PhotoViewerSheet(log: log, appState: appState, allLogs: filteredLogs)
                }
            }
            .sheet(isPresented: $showCollageCreator) {
                PhotoCollageView(appState: appState, availablePhotos: logsWithPhotos)
            }
            .sheet(isPresented: $showMemoryCreator) {
                MemoryCreatorView(appState: appState, availablePhotos: logsWithPhotos)
            }
            .sheet(isPresented: $showTimelineExport) {
                TimelineExportView(
                    appState: appState,
                    availablePhotos: logsWithPhotos,
                    profileName: appState.userProfile?.name ?? "Baby"
                )
            }
        }
        .searchable(text: $searchText, prompt: "Search by food name")
    }
    
    // MARK: - Photo Grid View
    
    private var photoGridView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Filter chips
                if showFilters {
                    filterSection
                }
                
                // Photo count
                Text("\(filteredLogs.count) photo\(filteredLogs.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Photo grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(filteredLogs, id: \.id) { log in
                        PhotoThumbnailCard(log: log, appState: appState)
                            .onTapGesture {
                                selectedLog = log
                                showPhotoViewer = true
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sort options
            HStack {
                Text("Sort by:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Picker("Sort", selection: $sortOption) {
                    ForEach(PhotoSortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Meal type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    GalleryFilterChip(
                        title: "All Meals",
                        isSelected: selectedMealType == nil,
                        themeColor: appState.themeColor
                    ) {
                        selectedMealType = nil
                    }
                    
                    ForEach([MealType.breakfast, .lunch, .dinner, .snack], id: \.self) { meal in
                        GalleryFilterChip(
                            title: meal.rawValue.capitalized,
                            isSelected: selectedMealType == meal,
                            themeColor: appState.themeColor
                        ) {
                            selectedMealType = meal
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundStyle(appState.themeColor.opacity(0.5))
            
            Text("No Photos Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start logging foods with photos to see them here!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            NavigationLink(destination: FoodTrackerPage(appState: appState)) {
                Label("Start Tracking Foods", systemImage: "fork.knife")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding()
                    .background(appState.themeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Photo Thumbnail Card

struct PhotoThumbnailCard: View {
    let log: TriedFoodLog
    let appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            if let imageData = log.messyFaceImage,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(log.foodName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(log.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Photo of \(log.foodName) from \(log.date.formatted(date: .abbreviated, time: .omitted))")
        .accessibilityHint("Double tap to view photo")
        .accessibilityAddTraits(.isImage)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Filter Chip

struct GalleryFilterChip: View {
    let title: String
    let isSelected: Bool
    let themeColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? themeColor : Color.gray.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
