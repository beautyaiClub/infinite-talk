#!/usr/bin/env python3
"""
Patch script to add r2_url detection to RunPod worker handler
"""

# Read the original handler
with open('/handler.py', 'r') as f:
    lines = f.readlines()

# Find the insertion point: after "outputs = prompt_history.get("outputs", {})"
insertion_index = None
for i, line in enumerate(lines):
    if 'outputs = prompt_history.get("outputs", {})' in line:
        insertion_index = i + 1
        break

if insertion_index is None:
    print("ERROR: Could not find insertion point in handler.py")
    exit(1)

# Code to insert
new_code = '''
        # Check for r2_url in outputs and return it directly
        for node_id, node_output in outputs.items():
            if "r2_url" in node_output:
                r2_url = node_output["r2_url"]
                print(f"worker-comfyui - Found r2_url in node {node_id}")

                # Handle character array format (ComfyUI bug)
                if isinstance(r2_url, list) and len(r2_url) > 0:
                    if all(isinstance(c, str) and len(c) == 1 for c in r2_url):
                        # Join character array into full URL
                        video_url = ''.join(r2_url)
                        print(f"worker-comfyui - Joined character array into URL: {video_url}")
                    else:
                        # Normal list with full string
                        video_url = r2_url[0]
                elif isinstance(r2_url, str):
                    video_url = r2_url
                else:
                    video_url = str(r2_url)

                print(f"worker-comfyui - Returning video URL: {video_url}")
                return {"video": video_url}

'''

# Insert the new code
lines.insert(insertion_index, new_code)

# Write back
with open('/handler.py', 'w') as f:
    f.writelines(lines)

print("=== Handler patched successfully ===")
