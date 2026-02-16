#!/usr/bin/env python3

import os
import sys
import json
import subprocess
import shutil

def get_xcresult_json(xcresult_path, id=None):
    cmd = ["xcrun", "xcresulttool", "get", "object", "--legacy", "--path", xcresult_path, "--format", "json"]
    if id:
        cmd.extend(["--id", id])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error getting json for id {id}: {result.stderr}")
        return None
    return json.loads(result.stdout)

def save_attachment(xcresult_path, attachment_id, filename):
    cmd = ["xcrun", "xcresulttool", "export", "object", "--legacy", "--path", xcresult_path, "--id", attachment_id, "--output-path", filename, "--type", "file"]
    subprocess.run(cmd, check=True)

def traverse_ids(xcresult_path, obj):
    # This is a generic traverser to look for attachments in the complex xcresult JSON structure
    if isinstance(obj, dict):
        type_info = obj.get("_type", {}).get("_name")
        print(f"Visiting type: {type_info}") 

        if "attachments" in obj:
             print(f"Found object with attachments! Type: {type_info}")

        # Check if this object is an attachment
        if type_info == "ActionTestAttachment":
            name = obj.get("name", {}).get("_value", "Unknown")
            payload_ref = obj.get("payloadRef", {}).get("id", {}).get("_value")
            
            if name and payload_ref:
                # We found an attachment!
                # We sanitize the name for filename
                clean_name = "".join(c for c in name if c.isalnum() or c in (' ', '_', '-')).strip()
                clean_name = clean_name.replace(" ", "_")
                
                # Check if it looks like one of our snapshots
                # Our snapshots are named like "01_Dashboard", "Snapshot: 01_Dashboard", etc.
                # or just the name we gave XCTAttachment
                
                print(f"Found attachment: {name} (ID: {payload_ref})")
                
                output_folder = "Screenshots"
                if not os.path.exists(output_folder):
                    os.makedirs(output_folder)
                
                filename = os.path.join(output_folder, f"{clean_name}.png")
                save_attachment(xcresult_path, payload_ref, filename)
                print(f"Saved to {filename}")
                return

        if type_info == "ActionTestMetadata" or "summaryRef" in obj:
            ref = obj.get("summaryRef", {}).get("id", {}).get("_value")
            if ref:
                print(f"Follow reference: {ref}")
                ref_json = get_xcresult_json(xcresult_path, ref)
                traverse_ids(xcresult_path, ref_json)

        # Recursion
        for key, value in obj.items():
            traverse_ids(xcresult_path, value)
            
    elif isinstance(obj, list):
        for item in obj:
            traverse_ids(xcresult_path, item)

def find_attachments_in_actions(xcresult_path, action_record):
    # We need to dig into the tests references
    # But recursively traversing the whole action record JSON might be easier first
    # The 'get' command on root returns the ActionsInvocationRecord
    # We might need to fetch detailed test results if they are references
    
    # 1. Look for 'actions' -> 'actionResult' -> 'testsRef'
    actions = action_record.get("actions", {}).get("_values", [])
    for action in actions:
        result = action.get("actionResult", {})
        tests_ref = result.get("testsRef", {}).get("id", {}).get("_value")
        
        if tests_ref:
            print(f"Fetching test details for ref: {tests_ref}")
            tests_json = get_xcresult_json(xcresult_path, tests_ref)
            if tests_json:
                print(f"Tests JSON Keys: {tests_json.keys()}")
                print(f"Tests JSON Type: {tests_json.get('_type', {}).get('_name')}")
                # Now we need to recurse down to find summaries -> tests -> subtests...
                # Or just brute force traverse the JSON we got back
                traverse_ids(xcresult_path, tests_json)

def main():
    if len(sys.argv) < 2:
        print("Usage: extract_screenshots.py <path_to_xcresult>")
        sys.exit(1)

    xcresult_path = sys.argv[1]
    if not os.path.exists(xcresult_path):
        print(f"Path does not exist: {xcresult_path}")
        sys.exit(1)

    print(f"Processing: {xcresult_path}")
    
    # Get root record
    root_json = get_xcresult_json(xcresult_path)
    if not root_json:
        print("Failed to get root json")
        sys.exit(1)
        
    find_attachments_in_actions(xcresult_path, root_json)
    print("Done!")

if __name__ == "__main__":
    main()
