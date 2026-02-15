"""
Minimal wrapper for RunPod worker-comfyui
Only transforms successful output to extract r2_url
All error handling is preserved from the original worker
"""

import runpod
from runpod_worker_comfyui.rp_handler import handler as original_handler


def handler(event):
    """
    Wrapper that calls original handler and transforms successful output

    Args:
        event: RunPod event

    Returns:
        Original response for errors, transformed response for success
    """
    # Call the original handler - it handles all the complexity
    result = original_handler(event)

    # Only transform successful results
    if isinstance(result, dict) and "error" not in result:
        # Check if we have outputs with r2_url
        if "output" in result and isinstance(result["output"], dict):
            outputs = result["output"].get("outputs", {})

            # Search for r2_url in any node output
            for node_id, node_output in outputs.items():
                if "r2_url" in node_output:
                    r2_url = node_output["r2_url"]

                    # Handle character array format
                    if isinstance(r2_url, list) and len(r2_url) > 0:
                        if all(isinstance(c, str) and len(c) == 1 for c in r2_url):
                            # Join character array
                            url = ''.join(r2_url)
                        else:
                            # Normal list
                            url = r2_url[0]
                    elif isinstance(r2_url, str):
                        url = r2_url
                    else:
                        # Fallback to original output
                        return result

                    # Return transformed output
                    return {
                        "video": url
                    }

    # Return original result (errors, or no r2_url found)
    return result


# Start the RunPod serverless handler
if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
