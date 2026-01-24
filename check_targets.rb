#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'TinyTastesTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

def check_file(project, filename)
  file_ref = project.files.find { |f| f.path && f.path.include?(filename) }
  if file_ref
    targets = project.targets.select { |t| t.source_build_phase.files_references.include?(file_ref) }
    puts "#{filename} is in targets: #{targets.map(&:name).join(', ')}"
  else
    puts "#{filename} not found in project"
  end
end

puts "Checking target membership..."
check_file(project, 'UserAccount.swift')
check_file(project, 'UserProfile.swift')
check_file(project, 'SharedModelContainer.swift')
