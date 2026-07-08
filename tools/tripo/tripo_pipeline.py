# TRIPO PIPELINE (GameOS module, CHARACTER-FOUNDRY station 2)
# image (A-pose) -> image_to_model (face_limit) -> animate_prerigcheck -> animate_rig -> rigged GLB
# Usage: python tripo_pipeline.py <input_image> <output_glb> [face_limit] [texture_quality]
# texture_quality: standard (default) | detailed  <- detailed = the hero-model default
# (2026-07-06 lesson: standard texture mushed FANG's eyes/fangs; detailed restored them)
# Reads TRIPO_API_KEY from the repo's .env.local (gitignored).
# Recorded engine rule (STYLE-GUIDE §3D): this API path, NOT the Magnific wrapper,
# is the game-ready route - controllable poly budget + real rig.

import json
import os
import sys
import time
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
API = "https://api.tripo3d.ai/v2/openapi"


def api_key():
    with open(os.path.join(REPO, ".env.local"), encoding="utf-8") as f:
        for line in f:
            if line.strip().startswith("TRIPO_API_KEY"):
                return line.split("=", 1)[1].strip().strip('"').strip("'")
    raise SystemExit("TRIPO_API_KEY not found in .env.local")


def call(method, path, key, body=None, raw=None, content_type=None):
    url = API + path
    data = None
    headers = {"Authorization": f"Bearer {key}"}
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    if raw is not None:
        data = raw
        headers["Content-Type"] = content_type
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())


def upload_image(path, key):
    # multipart/form-data by hand (stdlib only)
    boundary = "----tripoboundary7f3a"
    ext = os.path.splitext(path)[1].lstrip(".").lower()
    ext = "jpeg" if ext == "jpg" else ext
    with open(path, "rb") as f:
        filedata = f.read()
    body = (
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; "
        f"filename=\"{os.path.basename(path)}\"\r\n"
        f"Content-Type: image/{ext}\r\n\r\n"
    ).encode() + filedata + f"\r\n--{boundary}--\r\n".encode()
    resp = call("POST", "/upload", key, raw=body,
                content_type=f"multipart/form-data; boundary={boundary}")
    return resp["data"]["image_token"], ("jpg" if ext == "jpeg" else ext)


def wait_task(task_id, key, label):
    while True:
        resp = call("GET", f"/task/{task_id}", key)
        d = resp["data"]
        status, progress = d["status"], d.get("progress", 0)
        print(f"  [{label}] {status} {progress}%", flush=True)
        if status == "success":
            return d
        if status in ("failed", "cancelled", "banned", "expired"):
            raise SystemExit(f"{label} FAILED: {json.dumps(d)[:500]}")
        time.sleep(6)


def main():
    img, out_glb = sys.argv[1], sys.argv[2]
    face_limit = int(sys.argv[3]) if len(sys.argv) > 3 else 18000
    texture_quality = sys.argv[4] if len(sys.argv) > 4 else "standard"
    model_version = sys.argv[5] if len(sys.argv) > 5 else "v3.0-20250812"
    key = api_key()

    print(f"1/4 upload {os.path.basename(img)}")
    token, ftype = upload_image(img, key)

    print(f"2/4 image_to_model (face_limit={face_limit}, texture={texture_quality}, version={model_version})")
    t1 = call("POST", "/task", key, body={
        "type": "image_to_model",
        "model_version": model_version,
        "file": {"type": ftype, "file_token": token},
        "face_limit": face_limit,
        "texture_quality": texture_quality,
    })["data"]["task_id"]
    gen = wait_task(t1, key, "image_to_model")
    pre_url = gen["output"].get("pbr_model") or gen["output"].get("model")
    if pre_url:
        prerig = out_glb + ".prerig.glb"
        urllib.request.urlretrieve(pre_url, prerig)
        print(f"  saved pre-rig intermediate -> {prerig}")

    print("3/4 animate_prerigcheck")
    t2 = call("POST", "/task", key, body={
        "type": "animate_prerigcheck", "original_model_task_id": t1,
    })["data"]["task_id"]
    check = wait_task(t2, key, "prerigcheck")
    riggable = check.get("output", {}).get("riggable")
    print(f"  riggable = {riggable}")
    if not riggable:
        raise SystemExit("Model not riggable per prerigcheck - inspect manually.")

    print("4/4 animate_rig")
    t3 = call("POST", "/task", key, body={
        "type": "animate_rig", "original_model_task_id": t1, "out_format": "glb",
    })["data"]["task_id"]
    rig = wait_task(t3, key, "animate_rig")
    url = rig["output"].get("model") or rig["output"].get("pbr_model")
    print(f"download -> {out_glb}")
    urllib.request.urlretrieve(url, out_glb)
    print(f"DONE {out_glb} ({os.path.getsize(out_glb) // 1024} KB)")


if __name__ == "__main__":
    main()
