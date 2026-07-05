# ANIM-FORGE - Blender-side engine (GameOS module).
# Runs INSIDE Blender headless:  blender --background --python forge.py -- spec.json
# Reads an animation SPEC (JSON) and builds a named clip in the .blend:
#   base_pose (bone euler degrees) + oscillator layers (living motion) -> keyframed loop,
#   then saves the .blend, optionally exports GLB (mechanics contract: named clips, in-place),
#   and renders preview frames for the gif step (run.py does the gif).
# Spec format: see specs/fang_idle_crouch.json + README.md.
import bpy, json, math, sys, os, mathutils

spec_path = sys.argv[-1]
S = json.load(open(spec_path, encoding="utf-8"))

bpy.ops.wm.open_mainfile(filepath=S["blend"])
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
mesh = next(o for o in bpy.data.objects if o.type == "MESH")

clip = S["clip"]
# replace an existing action of this name (keep_old_as lets you archive it instead)
old = bpy.data.actions.get(clip)
if old:
    if S.get("keep_old_as"):
        old.name = S["keep_old_as"]; old.use_fake_user = True
        print("kept old action as", S["keep_old_as"])
    else:
        bpy.data.actions.remove(old); print("removed old action", clip)

act = bpy.data.actions.new(clip)
act.use_fake_user = True
if not arm.animation_data: arm.animation_data_create()
arm.animation_data.action = act

bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
pb = arm.pose.bones
for b in pb: b.rotation_mode = 'XYZ'

BASE = S.get("base_pose", {})          # "BoneName": [x,y,z] degrees; "BoneName_loc": [x,y,z] units
OSC = S.get("oscillators", [])          # {bone, axis(x|y|z), amp, period, phase, loc?}
T = int(S.get("length", 120))
STEP = int(S.get("keys_every", 6))
AXI = {"x": 0, "y": 1, "z": 2}

def osc_val(o, f):
    return o["amp"] * math.sin(2*math.pi*((f-1)/o["period"]) + o.get("phase", 0.0))

missing = set()
for f in range(1, T+2, STEP):
    # rotations
    for name, e in BASE.items():
        if name.endswith("_loc"): continue
        b = pb.get(name)
        if not b: missing.add(name); continue
        v = [e[0], e[1], e[2]]
        for o in OSC:
            if o["bone"] == name and not o.get("loc"):
                v[AXI[o["axis"]]] += osc_val(o, f)
        b.rotation_euler = tuple(math.radians(x) for x in v)
        b.keyframe_insert("rotation_euler", frame=f)
    # locations (e.g. Hip_loc for a body bob)
    for name, e in BASE.items():
        if not name.endswith("_loc"): continue
        bn = name[:-4]
        b = pb.get(bn)
        if not b: missing.add(bn); continue
        v = [e[0], e[1], e[2]]
        for o in OSC:
            if o["bone"] == name and o.get("loc"):
                v[AXI[o["axis"]]] += osc_val(o, f)
        b.location = mathutils.Vector(v)
        b.keyframe_insert("location", frame=f)
if missing: print("!! bones not found:", sorted(missing))
bpy.ops.object.mode_set(mode='OBJECT')
print("FORGE: clip '%s' built (%d frames, keys every %d)" % (clip, T, STEP))

bpy.ops.wm.save_as_mainfile(filepath=S["blend"])
print("FORGE: blend saved")

if S.get("export_glb"):
    bpy.ops.export_scene.gltf(filepath=S["export_glb"], export_format='GLB',
        export_animations=True, export_animation_mode='ACTIONS',
        export_nla_strips=False, export_bake_animation=False, export_apply=False)
    print("FORGE: glb exported", S["export_glb"], os.path.getsize(S["export_glb"]))

# ---- preview render ----
P = S.get("preview")
if P:
    outdir = P["dir"]; os.makedirs(outdir, exist_ok=True)
    scn = bpy.context.scene
    scn.render.engine = 'BLENDER_EEVEE_NEXT'
    scn.render.resolution_x, scn.render.resolution_y = P.get("size", [360, 460])
    scn.render.film_transparent = True
    w = bpy.data.worlds.new("fw"); scn.world = w; w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[1].default_value = 1.15
    sd = bpy.data.lights.new("fs", "SUN"); su = bpy.data.objects.new("fs", sd)
    bpy.context.collection.objects.link(su); sd.energy = 3.1
    su.rotation_euler = (math.radians(55), math.radians(15), math.radians(35))
    arm.animation_data.action = act
    scn.frame_set(1)
    deps = bpy.context.evaluated_depsgraph_get()
    mev = mesh.evaluated_get(deps)
    pts = [mesh.matrix_world @ v.co for v in mev.data.vertices]
    top = max(p.z for p in pts); bot = min(p.z for p in pts)
    h = max(top-bot, 0.6); cz = (top+bot)/2
    cd = bpy.data.cameras.new("fc"); cam = bpy.data.objects.new("fc", cd)
    bpy.context.collection.objects.link(cam); scn.camera = cam; cd.lens = 50
    dist = h*3.0
    CAMS = {"side": (dist, 0.001, cz+h*0.12), "front": (0, -dist, cz+h*0.12),
            "threeq": (dist*0.62, -dist*0.75, cz+h*0.4)}
    cam.location = CAMS.get(P.get("cam", "threeq"), CAMS["threeq"])
    dirv = mathutils.Vector((0, 0, cz+h*0.05)) - cam.location
    cam.rotation_euler = dirv.to_track_quat('-Z', 'Y').to_euler()
    N = int(P.get("frames", 30))
    for i in range(N):
        scn.frame_set(int(1 + (T-1)*i/N))
        scn.render.filepath = os.path.join(outdir, "f_%02d.png" % i)
        bpy.ops.render.render(write_still=True)
    print("FORGE: preview rendered", N, "frames ->", outdir)
print("FORGE: DONE")
