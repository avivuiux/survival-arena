# Survival Arena - Online (Phase 2, the real wall)

The single-player game is solid (movement + combat + readability all Aviv-validated
"מעולה", 2026-07-02). Per the locked bet, online is **the REAL mode and the hardest wall**,
so we tackle it now, riskiest-assumption-first.

## The model (locked)

- **Single-client multiplayer - you play ALONE** (one human per client), like Survival Project.
  The bot in the single-player game is a stand-in for a remote player.
- **Transport:** Godot built-in high-level multiplayer over **ENet** (`ENetMultiplayerPeer`).
  Start here; it is the standard, batteries-included path.

## The AUTHORITY MODEL - ✅ DECIDED (2026-07-02, WITH Aviv): SERVER-AUTHORITATIVE

*Who decides what actually happened* (position, hits, HP, KO) was the heavy architecture fork.
The options were:
- **Client-authoritative** - each client owns its fighter and broadcasts state. Simplest,
  cheatable, "hits" ambiguous. Was used ONLY to prove the pipe (slices 1-2).
- **Server-authoritative** - the host simulates the whole fight; clients send inputs. ← **CHOSEN**
- **Rollback (GGPO-style)** - the gold standard for fighting-game feel, and months of work.

**Decision (Aviv, 2026-07-02, after a plain-language walkthrough of the feel implications):
server-authoritative.** Reasoning: (1) scope-is-the-killer - rollback is months before any
playable online fight exists; server-auth reaches "playing a friend online" in weeks. (2) Our
parry window is generous (0.18s = ~10x a fighting-game frame), so we have far more latency
tolerance than a Street-Fighter-class game - prediction/interpolation (slice 4) can carry it.
(3) The rollback door STAYS OPEN: if real-latency play (slice 4+) feels bad, switching means
rewriting the net core, not the game. Known cost accepted: under a bad connection there will
be occasional "I blocked and still got hit" moments - the host's ruling wins.

## Slice ladder (build order, one at a time, each play-tested)

1. ~~**Prove the pipe**~~ **✅ DONE (2026-07-02, Aviv "עובד").** Two Godot windows on one machine
   connected over ENet localhost (H=host, J=join) and each saw the other's square move in real
   time, smoothly. The transport works in our setup - the netcode wall is breached at the
   principle level. Throwaway code: `scripts/net_test.gd` + `scenes/net_test.tscn`,
   client-authoritative position broadcast, NOT wired into the game (rewrite for real, per below).
2. ~~**Two real fighters synced**~~ **✅ DONE (2026-07-02, Aviv "מעולה" - both windows worked,
   the remote fighter moved smoothly with the full motion read).** The REAL fighter (untouched
   `fighter.gd`) runs in two windows via `scripts/net_fight.gd` + `scenes/net_fight.tscn`;
   auto host/join from the command line (`++ host` / `++ join`). Still throwaway
   client-authoritative - damage deliberately OFF (that is slice 3).

   **Slice 2 SPEC (2026-07-02, before build):**
   - **New throwaway scene** `scripts/net_fight.gd` + `scenes/net_fight.tscn` - the REAL
     `fighter.gd` (untouched), NOT the full game (no select screen / rounds / bot - that is
     slice 3+ territory and depends on the authority decision).
   - Each window: **my fighter** = real input + the real tuned movement (arrows steer, A run,
     S melee, R lunge, Space block) · **remote fighter** = a PUPPET fed by the network
     (a passive-bot fighter instance whose state is overwritten by incoming packets).
   - **Synced every frame (unreliable):** position + facing + momentum velocity (drives the
     stretch + trail read) + action state (idle / wind-up / attack / block, with phase time -
     so the parry-window color reads too). Lunge syncs by itself (it is movement).
   - **Deliberately OUT:** damage / HP / KO (hurtboxes disabled - hits SHOW but don't count;
     deciding who "really" hit = slice 3, the authority fork), chill/shockwave (no caster here),
     latency handling (slice 4). Ranged shot = synced as a visual-only event.
   - **Pass =** two windows, H/J connect, both fighters are the real thing: the remote one
     moves with the full momentum read + readable wind-up, smoothly, at localhost.
3. **Authority-model decision (the real fork)** - ✅ DECIDED: server-authoritative (see above).
   **✅ LOCKED (2026-07-03, Aviv "מעולה" after a LIVE best-of-3 in two windows)** - the host
   refereed a real networked match (damage/HP/KO/score), both windows agreed, the guest side
   felt right. Slice 3 is done. Next net step: slice 4 (latency).

   **Slice 3 SPEC (2026-07-02, before build):**
   - `scripts/net_fight.gd` evolves IN PLACE from the slice-2 throwaway into the first REAL
     net model (slice-2 version stays in git history). Still localhost, still `++ host/join`.
   - **Host = the referee.** The host window simulates BOTH fighters with the real `fighter.gd`
     rules (hurtboxes ON - damage is REAL now). The guest window renders what the host says.
   - **Guest sends INPUTS, not state:** held keys (steer/block/run) every frame + presses
     (melee/skill/ranged) as reliable one-shot events. `fighter.gd` gets a minimal
     `remote_driven` intent hook (the intent layer was built for exactly this - human keys,
     bot brain, and now the network all feed the same rules).
   - **Host broadcasts the whole picture every frame:** per fighter - position, facing,
     momentum velocity, action/pose state (wind-up/attack/block/hit/parry), HP, active -
     plus live projectiles. Guest puppets replay it (slice-2 mechanism, extended).
   - **Guest-side juice derived, not sent:** an HP drop = play sparks/shake/hit-pose locally;
     active→false at 0 HP = KO burst. Host hit-stop freezes the sim itself, so the guest
     inherits the freeze through the state stream.
   - **Round flow lives on the host** (KO → score → banner → reset), mirrored to the guest
     via two reliable events (round_over / round_start).
   - **Deliberately OUT:** latency tricks (prediction/interpolation/lag simulation) = slice 4.
     At 0ms localhost the guest should feel identical to the host despite being a puppet.
   - **Pass =** two windows fight a REAL match (HP drops, parry negates, KO, best-of-3 score)
     and both windows always agree on the result.
4. **Latency handling** - interpolation / prediction / (maybe) rollback. The hardest part;
   a local slice at 0ms CANNOT validate this (see FIND-THE-FUN-DECISIONS: network-feel caveat).

   **✅ SLICE 4 LOCKED (2026-07-03, Aviv live: "עובד נדיר" - ALL levels, including the
   GUEST window at 100ms one-way = 200ms round-trip, with ZERO mitigation).** The raw
   server-authoritative fight survives real delay: the generous 0.18s parry window +
   momentum movement absorb it, exactly as reasoned in the authority decision. Consequences:
   - **Server-authoritative is CONFIRMED at the feel level. The rollback door closes** (can
     reopen only if real-internet play contradicts this).
   - **No prediction / interpolation needed at prototype level** - a whole engineering
     layer just fell off the plan.
   - **Honest caveat (the remaining unknown):** localhost simulates constant delay only.
     Real internet adds jitter / packet loss / spikes - the final proof is a two-machine
     real-network test (PC vs Mac). That is the LAST net gate, logistics permitting.

   **Slice 4 SPEC (2026-07-03, before build) - FEEL THE LAG FIRST, mitigate second:**
   - `net_fight.gd` evolves in place again (slice-3 version stays in git history).
     Still localhost, still `++ host/join`.
   - **Artificial-latency injector:** every incoming network message (state -> guest,
     inputs -> host, round events) is held in a queue and applied only after a configurable
     ONE-WAY delay. Constant delay, order preserved. This turns localhost into a honest
     delay simulator (jitter/packet-loss simulation = deferred, delay dominates the feel
     question).
   - **`L` cycles the delay live in both windows** (synced over the net): one-way
     0 / 30 / 60 / 100 ms = round-trip 0 / 60 / 120 / 200 ms. Status line shows it.
     Command-line preset: `++ host lag60`.
   - **Deliberately NO mitigation in this step** - no prediction, no interpolation. The
     point is to FEEL the raw cost: the guest's own fighter answers a full round-trip late,
     and both players react to a world that is one-way old. Aviv plays at each level and
     answers: at what delay does the fight stop feeling fair - and does the generous 0.18s
     parry window carry it?
   - **The verdict routes the next step:** playable at 60-100ms RTT = ship-shaped, move on ·
     bad self-movement feel = client-side prediction slice · parry feels unfair = rollback
     door reopens (the known cost accepted in the authority decision).
   - **Pass =** a real best-of-3 at each delay level + a written verdict per level.

## How to test slice 1

Launch the net-test scene in TWO windows on this machine. In one press **H** (host), in the
other press **J** (join localhost). Move with arrows/WASD in each - each window should show its
own square plus the other window's square moving live.

Run command (scene passed as the argument, main game untouched):
`Godot_v4.7-stable_win64.exe --path "<repo>" res://scenes/net_test.tscn`
