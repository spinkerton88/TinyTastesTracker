#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'TinyTastesTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'TinyTastesTracker' }

models_group = project.main_group.find_subpath('TinyTastesTracker/Core/Models', true)

# Remove UserAccount.swift reference if it exists
target.source_build_phase.files_references.each do |ref|
  if ref.path && ref.path.include?('UserAccount.swift')
    puts "Removing reference: #{ref.path}"
    target.source_build_phase.remove_file_reference(ref)
    ref.remove_from_project
  end
end

# Add ParentProfile.swift
parent_profile_file = models_group.new_file('ParentProfile.swift')
if !target.source_build_phase.files_references.include?(parent_profile_file)
    target.add_file_references([parent_profile_file])
    puts "Added ParentProfile.swift"
else
    puts "ParentProfile.swift already exists"
end

project.save
puts "✅ Updated project references for ParentProfile!"
