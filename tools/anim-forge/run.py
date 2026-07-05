# ANIM-FORGE driver (system python, not Blender).
# Usage:  python run.py specs/fang_idle_crouch.json
# Runs Blender headless with forge.py on the spec, then assembles the preview gif
# and drops it in the deliver_dir (a folder Aviv can actually open - never a temp dir).
import json, os, subprocess, sys

BLENDER = os.environ.get("BLENDER_EXE",
    r"C:\Users\Aviv\dev\tools\blender-4.2.3-windows-x64\blender.exe")
HERE = os.path.dirname(os.path.abspath(__file__))

spec_path = os.path.abspath(sys.argv[1])
S = json.load(open(spec_path, encoding="utf-8"))

r = subprocess.run([BLENDER, "--background", "--python",
                    os.path.join(HERE, "forge.py"), "--", spec_path],
                   capture_output=True, text=True)
for line in r.stdout.splitlines():
    if line.startswith("FORGE:") or line.startswith("!!"): print(line)
if "FORGE: DONE" not in r.stdout:
    print("--- blender failed, tail of output ---")
    print("\n".join(r.stdout.splitlines()[-25:])); print(r.stderr[-2000:]); sys.exit(1)

P = S.get("preview")
if P:
    from PIL import Image
    d = P["dir"]
    n = len([f for f in os.listdir(d) if f.startswith("f_") and f.endswith(".png")])
    frames = []
    for i in range(n):
        im = Image.open(os.path.join(d, "f_%02d.png" % i)).convert("RGBA")
        bg = Image.new("RGBA", im.size, (232, 234, 240, 255))
        bg.alpha_composite(im)
        frames.append(bg.convert("P", palette=Image.ADAPTIVE))
    deliver = S.get("deliver_dir", d)
    os.makedirs(deliver, exist_ok=True)
    gif = os.path.join(deliver, S["clip"] + ".gif")
    dur = int(S.get("length", 120) / max(n, 1) * (1000 / S.get("fps", 30)))
    frames[0].save(gif, save_all=True, append_images=frames[1:],
                   duration=dur, loop=0, disposal=2)
    print("GIF:", gif)
    os.startfile(gif)   # open it on Aviv's screen - zero clicks
