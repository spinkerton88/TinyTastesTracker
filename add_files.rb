#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'TinyTastesTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'TinyTastesTracker' }

# Find or create the groups
daycare_group = project.main_group.find_subpath('TinyTastesTracker/Features/Daycare', true)
services_group = project.main_group.find_subpath('TinyTastesTracker/Core/Services', true)

# Add ReportImportView.swift
report_import_file = daycare_group.new_file('TinyTastesTracker/Features/Daycare/ReportImportView.swift')
target.add_file_references([report_import_file])

# Add DaycareReportParser.swift
parser_file = services_group.new_file('TinyTastesTracker/Core/Services/DaycareReportParser.swift')
target.add_file_references([parser_file])

# Save the project
project.save

puts "✅ Added files to Xcode project successfully!"
