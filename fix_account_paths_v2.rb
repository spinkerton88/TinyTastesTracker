#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'TinyTastesTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'TinyTastesTracker' }

onboarding_group = project.main_group.find_subpath('TinyTastesTracker/Features/Onboarding', true)

# Remove AccountSetupView.swift reference
target.source_build_phase.files_references.each do |ref|
  if ref.path.include?('AccountSetupView.swift')
    puts "Removing reference: #{ref.path}"
    target.source_build_phase.remove_file_reference(ref)
    ref.remove_from_project
  end
end

# Re-add AccountSetupView.swift
# Since onboarding_group has empty path (virtual), we need to specify path relative to project root (or parent group with path)
# The file is at TinyTastesTracker/Features/Onboarding/AccountSetupView.swift
# We will use that path.
account_setup_file = onboarding_group.new_file('TinyTastesTracker/Features/Onboarding/AccountSetupView.swift')
target.add_file_references([account_setup_file])
puts "Re-added AccountSetupView.swift with full path"

project.save
puts "✅ Fixed AccountSetupView reference!"
