#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'TinyTastesTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'TinyTastesTracker' }

# Find or create the groups
models_group = project.main_group.find_subpath('TinyTastesTracker/Core/Models', true)
onboarding_group = project.main_group.find_subpath('TinyTastesTracker/Features/Onboarding', true)

# Add UserAccount.swift
user_account_file = models_group.new_file('TinyTastesTracker/Core/Models/UserAccount.swift')
if !target.source_build_phase.files_references.include?(user_account_file)
    target.add_file_references([user_account_file])
    puts "Added UserAccount.swift"
else
    puts "UserAccount.swift already exists"
end

# Add AccountSetupView.swift
account_setup_file = onboarding_group.new_file('TinyTastesTracker/Features/Onboarding/AccountSetupView.swift')
if !target.source_build_phase.files_references.include?(account_setup_file)
    target.add_file_references([account_setup_file])
    puts "Added AccountSetupView.swift"
else
    puts "AccountSetupView.swift already exists"
end

# Save the project
project.save

puts "✅ Added files to Xcode project successfully!"
