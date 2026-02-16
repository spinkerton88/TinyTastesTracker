#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'TinyTastesTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'TinyTastesTracker' }

puts "Compile Sources for #{target.name}:"
target.source_build_phase.files_references.each do |ref|
  if ref.path && ref.path.include?('ParentProfile.swift')
    puts "FOUND: #{ref.path}"
  end
end
puts "Scan complete."
