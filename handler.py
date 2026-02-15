"""
Custom RunPod Handler for ComfyUI with R2 Video URL Output
Extracts r2_url from ComfyUI workflow and returns it in the desired format
"""

import runpod
import requests
import time
import json

COMFY_API = "http://127.0.0.1:8188"


def queue_prompt(workflow):
    """
    Submit workflow to ComfyUI API

    Args:
        workflow: ComfyUI workflow dict

    Returns:
        prompt_id: The ID of the queued prompt
    """
    try:
        response = requests.post(
            f"{COMFY_API}/prompt",
            json={"prompt": workflow},
            timeout=30
        )
        response.raise_for_status()
        result = response.json()

        # Check if ComfyUI returned an error
        if "error" in result:
            error_info = result["error"]
            raise RuntimeError(f"ComfyUI error: {error_info.get('message', str(error_info))}")

        # Check if prompt_id exists
        if "prompt_id" not in result:
            raise RuntimeError(f"No prompt_id in response: {result}")

        return result["prompt_id"]
    except requests.exceptions.RequestException as e:
        raise RuntimeError(f"Failed to connect to ComfyUI: {str(e)}")
    except Exception as e:
        raise RuntimeError(f"Failed to queue prompt: {str(e)}")


def wait_for_completion(prompt_id, timeout=600):
    """
    Wait for ComfyUI workflow to complete

    Args:
        prompt_id: The prompt ID to wait for
        timeout: Maximum wait time in seconds

    Returns:
        history: The execution history for this prompt
    """
    start_time = time.time()

    while True:
        if time.time() - start_time > timeout:
            raise TimeoutError(f"Workflow execution timeout after {timeout}s")

        try:
            response = requests.get(
                f"{COMFY_API}/history/{prompt_id}",
                timeout=10
            )
            response.raise_for_status()
            history = response.json()

            if prompt_id in history:
                # Check if execution completed
                prompt_history = history[prompt_id]
                if "outputs" in prompt_history:
                    return prompt_history

        except Exception as e:
            print(f"Error checking history: {e}")

        time.sleep(1)


def extract_r2_url(history):
    """
    Extract r2_url from ComfyUI execution history

    Args:
        history: ComfyUI execution history

    Returns:
        r2_url: The R2 video URL, or None if not found
    """
    if "outputs" not in history:
        print("ERROR: No 'outputs' in history")
        return None

    print(f"DEBUG: History outputs keys: {list(history['outputs'].keys())}")

    for node_id, node_output in history["outputs"].items():
        print(f"DEBUG: Node {node_id} output keys: {list(node_output.keys())}")
        print(f"DEBUG: Node {node_id} output: {node_output}")

        # Check for r2_url in node output
        if "r2_url" in node_output:
            r2_url = node_output["r2_url"]
            print(f"DEBUG: Found r2_url, type: {type(r2_url)}, value: {r2_url}")
            # Handle both string and list formats
            if isinstance(r2_url, list) and len(r2_url) > 0:
                print(f"DEBUG: Returning first element of list: {r2_url[0]}")
                return r2_url[0]
            elif isinstance(r2_url, str):
                print(f"DEBUG: Returning string: {r2_url}")
                return r2_url

    print("ERROR: No r2_url found in any node output")
    return None


def handler(event):
    """
    Main RunPod handler function

    Args:
        event: RunPod event containing input workflow

    Returns:
        dict: Response with video URL or error
    """
    try:
        # Validate input
        if "input" not in event:
            print("ERROR: Missing 'input' in event")
            return {
                "error": "Missing 'input' in event"
            }

        if "workflow" not in event["input"]:
            print("ERROR: Missing 'workflow' in input")
            return {
                "error": "Missing 'workflow' in input"
            }

        workflow = event["input"]["workflow"]

        print(f"Received workflow with {len(workflow)} nodes")

        # 1. Submit workflow to ComfyUI
        print("Submitting workflow to ComfyUI...")
        try:
            prompt_id = queue_prompt(workflow)
            print(f"Workflow queued with prompt_id: {prompt_id}")
        except RuntimeError as e:
            error_msg = str(e)
            print(f"ERROR: Failed to queue workflow: {error_msg}")
            return {
                "error": "Failed to queue workflow",
                "details": error_msg
            }

        # 2. Wait for execution to complete
        print("Waiting for workflow execution...")
        try:
            history = wait_for_completion(prompt_id)
            print("Workflow execution completed")
        except TimeoutError as e:
            print(f"ERROR: Workflow timeout: {str(e)}")
            return {
                "error": "Workflow execution timeout",
                "details": str(e)
            }
        except Exception as e:
            print(f"ERROR: Workflow execution failed: {str(e)}")
            return {
                "error": "Workflow execution failed",
                "details": str(e)
            }

        # 3. Extract r2_url from history
        r2_url = extract_r2_url(history)

        if not r2_url:
            print("ERROR: No r2_url found in workflow output")
            return {
                "error": "No r2_url found in workflow output",
                "details": "Make sure BeautyAI_UploadVideoToR2 node is in the workflow"
            }

        print(f"Successfully extracted R2 URL: {r2_url}")

        # 4. Return in the desired format
        return {
            "video": r2_url
        }

    except Exception as e:
        # Catch-all for any unexpected errors
        error_msg = str(e)
        print(f"CRITICAL ERROR: Unexpected exception: {error_msg}")
        import traceback
        traceback.print_exc()
        return {
            "error": "Unexpected error",
            "details": error_msg
        }


# Start the RunPod serverless handler
if __name__ == "__main__":
    print("Starting custom RunPod handler for ComfyUI...")
    print(f"ComfyUI API endpoint: {COMFY_API}")
    runpod.serverless.start({"handler": handler})
