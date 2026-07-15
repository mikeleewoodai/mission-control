---
name: mission-control-blueprint
description: >-
  Turn a business into a deployable Mission Control build that runs in Claude Cowork with a live
  dashboard served on a local server. Input can be a discovery/scoping/kickoff transcript, ops notes,
  an ops-ai-advisor report, an existing conductor-blueprint, or just a description of the next system you want. Use whenever you want to map, scope, blueprint, or "spin up" a Mission Control — for your own use OR a client prototype — with triggers like "blueprint a mission control", "build a mission
  control for [business]", "scope a mission control", "turn this into a mission control", "mission
  control for this client", "repurpose mission control for X", or "what would a mission control do
  for them". Produces a BUILD PACKET (PRD, folder tree + data-schema contract, scheduled-task
  prompts, the local-server dashboard + serve script, a Cowork kickoff prompt, and a wiring
  checklist) plus a plain-language CLIENT-FACING PLAN. Use this even if they don't say "skill" or
  "blueprint" explicitly.
---

# Mission Control Blueprint

Translate a business into a deployable **Mission Control** — a single Claude Cowork workspace that
unifies recurring work into scheduled workflows, on-demand skills, and a **live dashboard served on a
local server**. This skill maps what a business needs onto Mission Control's primitives so you can drop the packet into Cowork and stand the system up.

Always produce two deliverables: a **Build packet** (internal) and a **Client-facing plan** (or, when
the target is you's own use, a short scope confirmation in its place).

**Mission Control vs. Conductor OS — pick the right tool.** Conductor (see `conductor-blueprint`) is
skills-only, runs unattended on the client's own monthly plan, no servers — best for lightweight
always-on automation the client owns. Mission Control is heavier and visual: a Cowork project with a
local data layer and a dashboard you open in a browser. Choose it when the value is a **command
center** — seeing brief + gauges + pipeline + inbox in one place — when there's a richer data layer to
maintain, or when it's a **prototype you build here and may later promote** (the am-conductor
pattern). If the ask is purely "automate these recurring tasks on their plan," route to
`conductor-blueprint` instead.

---

## The architecture you are mapping onto

Mission Control = a **Cowork project on a local folder** + the **Productivity plugin** foundation +
**N domains** + a **data layer** + **interaction patterns**.

- **Foundation:** the Productivity plugin (`/start`) seeds the root: `CLAUDE.md`, `TASKS.md`,
  `memory/`, `dashboard.html`. The project points Cowork at a local folder (e.g. `C:\Mission-Control`).
- **Domains** (kebab-case folders), each with the same shape: `CLAUDE.md` (voice/role in that domain),
  `inputs/` (human-maintained — **never auto-overwritten**), `data/` (machine-refreshed), `outputs/`
  (generated artifacts).
- **Data layer = local files.** Connectors (M365 / Google) are **read-only sources, never storage**.
  Mutable state lives in local files so it survives a read-only or separate runtime context.
- **Three-tier memory:** root `CLAUDE.md` (people, terminology, shorthand) → `memory/{domain}/` (deep
  knowledge) → `{domain}/CLAUDE.md` (role + tone).
- **Interaction patterns:** (1) a **dashboard** served on a local server — reads the data layer over
  HTTP via `fetch()`, auto-refreshes, no folder picker; (2) a scheduled **morning brief**; (3)
  on-demand **skills** (`/today`, `/prep`, `/client`, etc.); (4) optionally an **autonomous builder**
  queue (advanced; usually deferred).
- **The dashboard is a fixed contract.** It fetches specific files by path with specific fields — the
  refresh workflows and brief must write to that contract (see `references/playbook.md`).
- **Guardrails everywhere:** read-only connectors · draft-only outbound (nothing sent/posted/deleted
  without review) · a refresh never writes to any `inputs/` folder · everything runs against local
  files in the project folder, not a sandbox.

The blueprint's job: turn each need into a (domain · refresh/brief/skill · connector source · output)
and a dashboard panel. `references/playbook.md` has the domain library, data-schema contract, scoping
rule, cron cheatsheet, wiring checklist, and a worked example. `assets/` has the dashboard template,
serve scripts, and the PRD skeleton.

---

## Input

- A **transcript / notes / scope**: uploaded file (`.txt`, `.vtt`, `.docx`, `.pdf`) or pasted text.
  Rough notes are fine. An `ops-ai-advisor` report or a `conductor-blueprint` are also valid inputs —
  reuse their findings instead of re-deriving.
- For your **own** systems, you may just describe what you want in chat — no transcript needed.
- Optional context: business name, **stack** (Microsoft 365 vs Google Workspace), who'll use it, OS
  (Windows vs macOS — sets the serve script), and target build length (3 / 5 / 8 hours).
- If the stack or OS isn't stated, infer it; ask once only if truly unclear.

---

## Step 1 — Extract from the input

Pull and list:

1. **Profile** — business, who runs it, who'll use the dashboard, team size.
2. **Stack & OS** — M365 vs Google; Windows vs macOS; plus any other apps named (CRM, accounting,
   project tool, ticketing, data source).
3. **Recurring / surfaceable work** — anything done on a cadence, watched daily, or that they wish
   they could see at a glance. For each: *what · cadence/trigger · source (where input comes from) ·
   output (what's produced) · who needs to see it.*
4. **What they want to SEE** — the command-center view: status, gauges, queues, pipelines. These
   become dashboard panels.
5. **Constraints** — privacy, approval rules, connector consent, anything that must stay draft-only.
6. **One-offs** — non-recurring asks. Flag as **project work, out of scope** for the daily system
   (note separately so they can be quoted as a build).

---

## Step 2 — Map onto Mission Control primitives

**a. Candidate domains.** Propose **4–6** domains from the input (use the domain library in the
playbook as a starting palette; adapt names to the business). Each domain is a folder. Present them as
a pick-list so you (or the client) choose.

**b. For each domain, map the work:**
- **Refreshes** — `data/*.json` files pulled from a read-only connector or derived from an `inputs/`
  file. Name each + its schema (match the contract in the playbook).
- **Brief** — what the daily morning brief should include from this domain.
- **Skills** — on-demand commands. **Prefer reuse** of existing skills (Conductor: `inbox-triage`,
  `calendar-prep`, `weekly-review`, `draft-email`; Leewood: `invoice`, `hours-statement`,
  `quote-builder`) — wire them rather than rebuild. Add new lightweight skills only when needed.
- **Dashboard panels** — which of: brief · gauges (hours/retainer/quota) · pipeline · inbox · outputs.

**c. Connectors** — which read-only connector each refresh uses; note consent/admin needs.

Carry these guardrails into every mapping: read-only connectors · draft-only output · local-file data
layer · refresh never writes to `inputs/` · everything in the project folder.

---

## Step 2.5 — Scope to the build window

Apply the scoping rule (playbook has the table): **~3h** = foundation + 1 domain + brief; **~5h** =
foundation + 2 domains (or 1 rich + the builder); **~8h** = foundation + 2–3 domains. **Never more than
~4 active domains** in one window — the rest become **placeholder folders** that scale in later with no
re-architecture. State plainly which domains are fully built vs. placeholders, and why. A solid system
across two domains beats a thin, broken one across five.

---

## Step 3 — BUILD PACKET (for you)

Output under `# Build packet (internal)`:

1. **PRD** — fill `assets/prd-template.md` (§1 summary → §10 out-of-scope). This is the authoritative
   build doc; it must stand alone so Cowork can build from it cold.
2. **Folder tree** — the full local tree (root skeleton + chosen domain folders + placeholders).
3. **Data-schema contract** — the exact `data/` and `inputs/` files with field-level schemas and the
   brief filename pattern. This is what the dashboard fetches; producers must match it byte-for-byte.
4. **Scheduled-task prompt(s)** — ready-to-paste, self-contained prompt text + cron (client local time)
   for the brief and refreshes (refreshes run BEFORE the brief; scheduled-safe; draft-only).
5. **Dashboard setup** — instructions to drop in `assets/dashboard.html` (set its `MC_CONFIG` for
   title, brand, domain paths, and which panels show) and the matching serve script
   (`serve-dashboard.bat` for Windows / `serve-dashboard.sh` for macOS/Linux). Explain it loads over
   HTTP from a local server — no folder picker — and auto-refreshes.
6. **Cowork kickoff prompt** — a ready-to-paste first message that points Cowork at the project folder,
   reconciles the folder name to the PRD root, and runs the build one Block at a time from Block 0.
7. **Wiring checklist** — the contract-match diagnostic from the playbook (confirm files land in the
   project folder, match the schema, and that the schedule writes there — the #1 failure mode).

---

## Step 4 — CLIENT-FACING PLAN (or scope confirmation)

If the target is a **client**, output under `# Client-facing plan` in plain language and you's warm,
concise voice (no jargon, no cron, no file paths):
- One-line intro: what their Mission Control will show and do.
- A short bulleted list **in their words** — what each part shows, when it updates, what they get.
- A reassurance line: you stay in control (drafts, nothing sent), it's private (read-only, your data),
  it lives on your machine.
- A confirmation ask: "Does this match what you need? Anything to add or cut before we build it?"

If the target is **your own use**, replace this with a 3–5 line **scope confirmation**: the chosen
domains, what's built vs. placeholder at the picked build length, and the one decision to confirm before building.

---

## Output

Render both deliverables in the reply under the two headers. Offer to save the packet as files
(e.g. `<business>-mission-control-PRD.md`, `<business>-plan.md`) plus copies of the customized
`dashboard.html` and serve script in the scratch/output folder. Keep the build packet precise and the
client plan human.

## Principles

- Only recurring/surfaceable work becomes domains and panels; one-offs are flagged as project work.
- Default to **read-only connectors + draft-only output**. Never propose auto-send without explicit request.
- **Reuse existing skills**; add new ones sparingly. Duplicating a skill that already exists is a failure mode.
- The dashboard is a **contract** — design the data producers to match the exact paths/fields it reads.
- **Local files are the source of truth**; connectors are sources, the served dashboard is the view.
- **Solid beats thin** — respect the ≤4-active-domains cap; defer the rest as placeholders.
- When the value is "automate on their own plan, no dashboard," route to `conductor-blueprint` instead.
