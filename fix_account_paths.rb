#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'TinyTastesTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'TinyTastesTracker' }

models_group = project.main_group.find_subpath('TinyTastesTracker/Core/Models', true)
onboarding_group = project.main_group.find_subpath('TinyTastesTracker/Features/Onboarding', true)

# Remove all references to the files we added (to be safe)
target.source_build_phase.files_references.each do |ref|
  if ref.path.include?('UserAccount.swift') || ref.path.include?('AccountSetupView.swift')
    puts "Removing reference: #{ref.path}"
    target.source_build_phase.remove_file_reference(ref)
    ref.remove_from_project
  end
end

# Re-add UserAccount.swift - Try with just filename if group handles path
# Check if group has a path
puts "Models group path: #{models_group.path}"
# If group path is relative to project, we generally want to add the file relative to the group
# But 'new_file' behavior depends on group source tree.
# We will assume group is backed by folder.
user_account_file = models_group.new_file('UserAccount.swift') 
target.add_file_references([user_account_file])
puts "Re-added UserAccount.swift as UserAccount.swift"

# Re-add AccountSetupView.swift
puts "Onboarding group path: #{onboarding_group.path}"
account_setup_file = onboarding_group.new_file('AccountSetupView.swift')
target.add_file_references([account_setup_file])
puts "Re-added AccountSetupView.swift as AccountSetupView.swift"

project.save
puts "✅ Fixed file references!"
