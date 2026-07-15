# PRD — {System Name} (Claude Cowork)

*Author: {owner} · Timezone: {tz} · Build window: ~{N} hours · Build surface: Claude Cowork*
*This document is the handoff to Cowork — it must stand on its own; Cowork is a blank slate when it first reads it.*

---

## 1. Executive summary
One paragraph: what {System Name} unifies. Then the live domains for this window and the interaction
patterns (served dashboard · scheduled brief · on-demand skills). Note any domain reused from an
existing skill rather than built from scratch. List deferred placeholder domains (→ §10).

## 2. Quick start — moving this into Cowork
**A.** Create the project folder and point a Cowork project at it; drop this PRD in.
**B.** Project-instructions block to paste into the project's custom-instructions field (state the live
domains, the placeholders, "data layer is LOCAL files; connectors are read-only sources, never
storage; never write to inputs/ on refresh", "build one Block at a time from Block 0", timezone).
**C.** How to run the build (Block 0 first — verify Productivity plugin + `/start` + connectors).
**D.** The first thing to type: `Start building {System Name} — begin with Block 0.`

## 3. Goals and non-goals
Goals for this window. Non-goals (deferred domains; never sends anything; no writes to client systems).

## 4. Architecture overview
Three layers (local folders → Cowork project → workflows). Interaction patterns and which workflows use
each. Three-tier memory. Pointer to §9 for decisions.

## 5. The data layer — the foundation
Built on the Productivity plugin root files. Local files; connectors are sources. Include:
- the full **folder tree** (root skeleton + chosen domains + placeholders),
- **memory files** (root people/terminology + per-domain),
- **data-file schemas** (match the contract; this is what the dashboard fetches),
- **inputs vs data** rule and the **refresh strategy** table (file · source · cadence · mode).

## 6. Component specifications
Each pipeline/brief/skill/dashboard: what it reads, what it writes, schedule. All interfaces read only
from the §5 data layer. Note which components wire existing skills.

## 7. The build plan
Block 0 (Setup) + numbered Blocks. Table: Block · what · who runs it · output · done-when. Include a
**cut order** (what to drop if short) and **never-cut** (Block 0, data layer, morning brief).

## 8. Setup details and copy-paste prompts
Complete, self-contained, copy-paste prompts for the data-layer scaffold, each refresh, the morning
brief (scheduled), and each skill. Every prompt names exact files and carries the CRITICAL guard:
never write to inputs/ on refresh; read-only against sources; draft-only outbound.

## 9. Decision log
Table of decisions + the tension behind each (why local files, why these domains, scope cut, M365 vs
Google, reuse vs rebuild, etc.). Use A-xxx labels for assumptions to confirm.

## 10. Out of scope / future work
Placeholder folders (one-line README stub each) and how each goes live with no re-architecture. What
WOULD force a re-architecture (moving the data layer off local files; multi-user access).
