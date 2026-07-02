# Survival Arena - Online (Phase 2, the real wall)

The single-player game is solid (movement + combat + readability all Aviv-validated
"מעולה", 2026-07-02). Per the locked bet, online is **the REAL mode and the hardest wall**,
so we tackle it now, riskiest-assumption-first.

## The model (locked)

- **Single-client multiplayer - you play ALONE** (one human per client), like Survival Project.
  The bot in the single-player game is a stand-in for a remote player.
- **Transport:** Godot built-in high-level multiplayer over **ENet** (`ENetMultiplayerPeer`).
  Start here; it is the standard, batteries-included path.

## The real decision, deliberately deferred: the AUTHORITY MODEL

*Who decides what actually happened* (position, hits, HP, KO) is the heavy architecture fork,
and it changes how the game feels under latency. The options, roughly hardest-last:
- **Client-authoritative** - each client owns its fighter and broadcasts state. Simplest,
  cheatable, and "hits" get ambiguous. Fine for proving the pipe; wrong for a real fight.
- **Server-authoritative** - the host (or a dedicated peer) simulates and clients send inputs.
  Standard, fair, but needs prediction/interpolation or it feels laggy.
- **Rollback (GGPO-style)** - the gold standard for fighting-game feel, and months of work.

**We do NOT decide this yet.** We decide it after the pipe is proven, as its own slice with
Aviv. The first slice uses the cheapest throwaway (client-authoritative) ONLY to answer "does
the pipe work at all in our setup?" - it is not the model.

## Slice ladder (build order, one at a time, each play-tested)

1. ~~**Prove the pipe**~~ **✅ DONE (2026-07-02, Aviv "עובד").** Two Godot windows on one machine
   connected over ENet localhost (H=host, J=join) and each saw the other's square move in real
   time, smoothly. The transport works in our setup - the netcode wall is breached at the
   principle level. Throwaway code: `scripts/net_test.gd` + `scenes/net_test.tscn`,
   client-authoritative position broadcast, NOT wired into the game (rewrite for real, per below).
2. **Two real fighters synced** - replace squares with the actual fighter (position + facing +
   action state). Still localhost, still throwaway model.
3. **Authority-model decision (the real fork)** - pick server-auth vs rollback WITH Aviv, then
   make hits/HP/KO authoritative. This is where the netcode actually begins.
4. **Latency handling** - interpolation / prediction / (maybe) rollback. The hardest part;
   a local slice at 0ms CANNOT validate this (see FIND-THE-FUN-DECISIONS: network-feel caveat).

## How to test slice 1

Launch the net-test scene in TWO windows on this machine. In one press **H** (host), in the
other press **J** (join localhost). Move with arrows/WASD in each - each window should show its
own square plus the other window's square moving live.

Run command (scene passed as the argument, main game untouched):
`Godot_v4.7-stable_win64.exe --path "<repo>" res://scenes/net_test.tscn`
