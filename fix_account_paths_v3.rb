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
# Onboarding group has no path, so it inherits (or stays relative to) parent 'Features' path.
# So we need to include 'Onboarding/' in the file path.
account_setup_file = onboarding_group.new_file('Onboarding/AccountSetupView.swift')
target.add_file_references([account_setup_file])
puts "Re-added AccountSetupView.swift as Onboarding/AccountSetupView.swift"

project.save
puts "✅ Fixed AccountSetupView reference (v3)!"
