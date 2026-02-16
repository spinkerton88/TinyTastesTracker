import SwiftUI
import Observation

struct NewbornDashboardPage: View {
    @Bindable var appState: AppState
    @State private var viewModel: NewbornDashboardViewModel
    
    // Sheet States
    @State private var showingFeedingSheet = false
    @State private var showingSleepSheet = false
    @State private var showingMedicationSheet = false
    @State private var showingReportImport = false
    
    init(appState: AppState) {
        self.appState = appState
        self._viewModel = State(initialValue: NewbornDashboardViewModel(appState: appState))
    }
    
    var body: some View {
        // Create a Bindable proxy for the ViewModel to pass bindings (e.g. $feedIntervalHours)
        @Bindable var bindableViewModel = viewModel
        
        NavigationStack {
            ZStack {
                // Gradient Background Header
                GradientBackground(color: .pink)
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Custom Header
                        HStack(alignment: .center) {
                            Text("Tracking")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Button {
                                showingReportImport = true
                            } label: {
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.title2)
                                    .foregroundStyle(Color.pink)
                                    .padding(8)
                                    .background(Color.pink.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Import care provider report")
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // MARK: - Baby Status Section
                        BabyStatusSection(
                            appState: appState,
                            formattedCurrentDate: viewModel.formattedCurrentDate,
                            babyStatusIcon: viewModel.babyStatusIcon,
                            babyStatusColor: viewModel.babyStatusColor,
                            babyStatusText: viewModel.babyStatusText,
                            nextFeedTime: viewModel.nextFeedTime,
                            feedIntervalHours: $bindableViewModel.feedIntervalHours,
                            lastFedString: viewModel.lastFedString,
                            lastDiaperString: viewModel.lastDiaperString,
                            formatInterval: viewModel.formatInterval
                        )
                        
                        // MARK: - Action Buttons
                        HStack(spacing: 12) {
                            ActionCapsule(icon: "spoon.serving", label: "Feed", color: .pink) {
                                showingFeedingSheet = true
                            }
                            Menu {
                                Button {
                                    HapticManager.impact()
                                    Task { try? await appState.saveDiaperLog(type: .wet) }
                                    HapticManager.success()
                                } label: {
                                    Label("Wet", systemImage: "drop.fill")
                                }
                                
                                Button {
                                    HapticManager.impact()
                                    Task { try? await appState.saveDiaperLog(type: .dirty) }
                                    HapticManager.success()
                                } label: {
                                    Label("Dirty", systemImage: "tornado")
                                }
                                
                                Button {
                                    HapticManager.impact()
                                    Task { try? await appState.saveDiaperLog(type: .both) }
                                    HapticManager.success()
                                } label: {
                                    Label("Both", systemImage: "drop.triangle.fill")
                                }
                            } label: {
                                VStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "drop.triangle.fill")
                                                .font(.title3)
                                                .foregroundStyle(Color.blue)
                                        )
                                    
                                    Text("Diaper")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                            ActionCapsule(icon: viewModel.isSleeping ? "moon.zzz.fill" : "moon.fill", label: viewModel.isSleeping ? "Wake Up" : "Sleep", color: .indigo) {
                                showingSleepSheet = true
                            }
                            ActionCapsule(icon: "pills.fill", label: "Meds", color: .mint) {
                                showingMedicationSheet = true
                            }
                        }
                        
                        // MARK: - Today's Logs
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today's Logs")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            RecentActivityList(appState: appState)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding()
                }
            }
            .navigationTitle("Dashboard")
            .withSage(context: "User is on Newborn Dashboard. Next feed: \(viewModel.nextFeedTime). Last: \(viewModel.lastFedString) (Fed), \(viewModel.lastDiaperString) (Diaper).", appState: appState)
            .navigationBarHidden(true)
            .onAppear {
                viewModel.updateStatus()
            }
            // Timer is handled internally by ViewModel
            .sheet(isPresented: $showingFeedingSheet) {
                 FeedingSheet(appState: appState)
            }
            .sheet(isPresented: $showingSleepSheet) {
                SleepLogSheet(appState: appState)
            }
            .onChange(of: showingSleepSheet) { _, isPresented in
                if !isPresented {
                    viewModel.updateStatus()
                }
            }
            .sheet(isPresented: $showingMedicationSheet) {
                MedicationSheet(appState: appState)
            }
            .sheet(isPresented: $showingReportImport) {
                ReportImportView(appState: appState, themeColor: .pink)
            }
        }
    }
}

// MARK: - Baby Status Section Component

struct BabyStatusSection: View {
    let appState: AppState
    let formattedCurrentDate: String
    let babyStatusIcon: String
    let babyStatusColor: Color
    let babyStatusText: String
    let nextFeedTime: String
    @Binding var feedIntervalHours: Double
    let lastFedString: String
    let lastDiaperString: String
    let formatInterval: (Double) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Baby Status")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.pink)
                
                Spacer()
                
                Text(formattedCurrentDate)
                    .font(.caption)
                    .padding(6)
                    .background(Color.pink.opacity(0.1))
                    .foregroundStyle(Color.pink)
                    .clipShape(Capsule())
            }
            
            // Status Grid
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    StatusCard(
                        title: "STATUS",
                        icon: babyStatusIcon,
                        iconColor: babyStatusColor,
                        mainText: babyStatusText
                    )
                    
                    NextFeedCard(
                        nextFeedTime: nextFeedTime,
                        feedIntervalHours: $feedIntervalHours,
                        formatInterval: formatInterval
                    )
                }
                
                HStack(spacing: 12) {
                    StatusCard(
                        title: "LAST FED",
                        icon: "spoon.serving",
                        iconColor: .pink,
                        mainText: lastFedString
                    )
                    
                    StatusCard(
                        title: "LAST DIAPER",
                        icon: "drop.triangle.fill",
                        iconColor: .blue,
                        mainText: lastDiaperString
                    )
                }
            }
        }
        .padding()
        .background(Color.pink.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Next Feed Card Component

struct NextFeedCard: View {
    let nextFeedTime: String
    @Binding var feedIntervalHours: Double
    let formatInterval: (Double) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("NEXT FEED")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Menu {
                    ForEach([2.0, 2.5, 3.0, 3.5, 4.0], id: \.self) { interval in
                        Button {
                            feedIntervalHours = interval
                        } label: {
                            HStack {
                                Text(formatInterval(interval))
                                if feedIntervalHours == interval {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(formatInterval(feedIntervalHours))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.pink.opacity(0.1))
                    .foregroundStyle(.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .accessibilityLabel("Feed Interval")
                .accessibilityValue(formatInterval(feedIntervalHours))
                .accessibilityHint("Double tap to change feeding interval")
            }
            
            Text(nextFeedTime)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Next feed at \(nextFeedTime)")
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Subviews

struct StatusCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let mainText: String
    var badgeText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundStyle(iconColor)
                            .font(.caption)
                    )
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Text(mainText)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                if let badge = badgeText {
                    Text(badge)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(mainText)\(badgeText != nil ? ", \(badgeText!)" : "")")
    }
}

struct ActionCapsule: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.impact()
            action()
        }) {
            VStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(color)
                    )
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }
}
