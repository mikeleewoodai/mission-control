# Mission Control — Playbook (reference)

Deep reference for `mission-control-blueprint`. Read the section you need.

## Contents
1. Domain library (palette for Step 2a)
2. Interaction-pattern catalog
3. Data-schema contract (what the dashboard fetches)
4. Scoping rule
5. Cron cheatsheet
6. Local-server setup + gotchas
7. Wiring / troubleshooting checklist
8. Worked example

---

## 1. Domain library

A starting palette. Rename to the business; propose 4–6, let the user pick.

- **daily-ops / personal-ops** — the always-on driver: calendar, inbox triage, day plan, weekly
  review. Almost every Mission Control wants this. Reuses Conductor `inbox-triage`, `calendar-prep`,
  `weekly-review`.
- **client-delivery / engagement** — active client work: hours/retainer burn, deliverable pipeline,
  client inbox, one-tap invoice / status. Reuses Leewood `invoice`, `hours-statement`.
- **pipeline / sales** — new-business intake → proposal/quote; lead status; revenue view. Reuses
  `quote-builder`, `conductor-blueprint` for intake.
- **builds / projects** — sprint/SES log, deploy status, project health for product or dev work.
- **finance / billing** — invoices out, AR aging, expense tracking, simple cash view.
- **autonomous-builder** (advanced) — a queue (`pending → in-progress → done → failed`) where a
  scheduled task picks up an approved spec and builds it. A `done/` step can **promote** a proven
  prototype elsewhere (e.g. to a separate account). Highest complexity — usually a placeholder /
  next window.

Each domain is a folder with `CLAUDE.md`, `inputs/`, `data/`, `outputs/`.

---

## 2. Interaction-pattern catalog

- **Dashboard (served, always-on visual).** A single `dashboard.html` served by a local server,
  fetching the data layer over HTTP and auto-refreshing. The command center. (Asset:
  `assets/dashboard.html` + serve scripts.)
- **Brief / digest (scheduled push).** A daily morning brief written to `briefs/brief-YYYY-MM-DD.md`,
  assembled from the domains' `data/` files.
- **Skill (on-demand command).** `/today`, `/prep [meeting]`, `/client [name]`, `/invoice`, `/hours`,
  etc. Prefer wiring existing skills.
- **Autonomous builder (advanced).** Scheduled queue that builds approved specs unattended. Defer
  unless the build length and need clearly justify it.

---

## 3. Data-schema contract

The dashboard reads these exact paths and fields. **Producers (refreshes, brief) must match this
byte-for-byte** — a field rename silently empties a panel. Domain folder names are configurable in the
dashboard's `MC_CONFIG`; the field shapes are not.

```
{daily-domain}/data/calendar.json
  { "refreshed_at": ISO8601,
    "events": [ { "id","title","start","end","attendees":[],"location","source" } ] }

{daily-domain}/data/inbox-triage.json
  { "refreshed_at": ISO8601,
    "needs_reply": [ { "id","from","subject","received","why","priority" } ],
    "fyi":         [ { "id","from","subject","priority" } ] }
  # priority is exactly "high" | "med" | "low"

{client-domain}/inputs/clients.json            # human-maintained
  { "clients": [ { "id","name","contacts":[{"name","role","email"}],
                   "engagement","retainer_hours","rate_path",
                   "brand": { "primary_teal","dark_teal","cta_teal" },
                   "status","parked": [] } ] }

{client-domain}/data/hours-summary.json        # derived from an inputs/*.xlsx — never write back
  { "refreshed_at": ISO8601,
    "by_client": [ { "client_id","allotted","used","remaining",
                     "last_activity","open_deliverables":[] } ] }
  # every client_id must match an id in clients.json

{client-domain}/data/client-inbox.json         # same shape as inbox-triage.json

briefs/brief-YYYY-MM-DD.md                      # filename MUST match  brief-\d{4}-\d{2}-\d{2}\.md
{domain}/outputs/*                              # any generated files; listed via server autoindex
```

Panel → data mapping: **brief** ← latest `briefs/brief-*.md` (+ counts from calendar/inbox); **gauges**
← `hours-summary.json` × `clients.json`; **pipeline** ← `hours-summary.by_client[].open_deliverables`
(+ `clients[].parked`); **inbox** ← `client-inbox.json` / `inbox-triage.json` `needs_reply`; **outputs**
← autoindex of the `outputs/` dirs.

To generalize beyond clients (e.g. matters, projects, accounts), keep the same shapes and relabel in
`MC_CONFIG` — "client" → "matter", "hours" → "budget", etc. Net-new panel types are future work; note
them in PRD §10 rather than forking the template.

---

## 4. Scoping rule

| Build length | What fits | Everything else |
|---|---|---|
| ~3 hours | foundation + **1** domain + morning brief | placeholder folders |
| ~5 hours | foundation + **2** domains (or 1 rich + the autonomous builder) | placeholder folders |
| ~8 hours | foundation + **2–3** domains | placeholder folders |

**Never more than ~4 active domains** in one window. Placeholders are empty domain folders with a
one-line README stub; they become live by filling `inputs/`/`data/`/`outputs/` and adding workflows —
no re-architecture. Always state which domains are built vs. placeholder and why.

---

## 5. Cron cheatsheet

Express schedules in the **business's local time**. Common ones:

- Daily morning brief: `30 6 * * *` (06:30 every day) — refreshes run first, then the brief.
- Weekday only: `0 8 * * 1-5`.
- Twice daily check: `0 8,16 * * *`.
- Weekly review: `0 17 * * 5` (Fri 17:00).

Refreshes that feed the brief should fire in the same task, before the brief step, so the brief reads
fresh data.

---

## 6. Local-server setup + gotchas

The dashboard loads data over HTTP, so it must be **served**, not double-clicked.

- **Windows:** double-click `serve-dashboard.bat` in the project folder (or `cd` in and run
  `py -m http.server 8000` / `python -m http.server 8000`).
- **macOS/Linux:** `bash serve-dashboard.sh` (or `cd` in and run `python3 -m http.server 8000`).
- Then open `http://localhost:8000/dashboard.html`.

Gotchas to bake into the packet:
- **Must serve from the project root** — the dashboard fetches by relative path (`{domain}/data/…`).
- **`file://` won't work** — fetch is blocked there; the template shows a "serve me" notice instead.
- **No `index.html` inside `briefs/` or `outputs/`** — the dashboard lists those via the server's
  directory autoindex; an index file hides the listing.
- **Cache** — the template cache-busts every read (`?t=…`) so new files show on the next auto-refresh.
- Directory autoindex parsing assumes a simple static server (python `http.server`, `npx http-server`).

---

## 7. Wiring / troubleshooting checklist

When the dashboard is empty, it's almost always one of these — give Cowork this diagnostic:

1. **Location.** Is the schedule/workflow writing into the **project folder** the server serves, or a
   sandbox? Repoint to the project folder. (The #1 failure mode.)
2. **Tree.** Do `{domain}/data`, `{domain}/inputs`, `{domain}/outputs`, `briefs/` exist?
3. **Contract.** Do the files match §3 exactly — paths, field names, `priority` enum, `client_id`
   linkage, brief filename pattern?
4. **Inputs real?** Are `inputs/clients.json` / `inputs/*.xlsx` populated, not empty stubs? (Empty
   inputs → empty dashboard even with perfect wiring. Flag, don't fabricate.)
5. **Run order.** Does the scheduled task run refreshes **before** the brief, and is the connector
   authorized in the scheduled/headless context?
6. **Report.** For each contract file: path · exists · size · `refreshed_at`/mtime · row counts.

---

## 8. Worked example

**Input (notes):** "Riverside Bookkeeping, 3 people, Microsoft 365, Windows. Owner Dana wants to open
her laptop and see today's calls, which client emails need answers, where each client's monthly
bookkeeping hours stand, and what's still owed to send out. Month-end invoicing is painful. Some new
leads come in she forgets to follow up."

**Step 1 extract:** M365 / Windows · daily: see calendar + client emails needing reply · watch
hours per client · invoices to send · lead follow-ups · pain: month-end invoicing · one-off: cleaning
up last year's books (project work).

**Step 2 domains (pick-list, picked in bold):** **daily-ops**, **client-delivery**, pipeline (leads),
finance, autonomous-builder.

**Step 2.5 scope (5h):** foundation + **daily-ops** + **client-delivery** + brief. pipeline, finance,
autonomous-builder → placeholders.

**Mapped:**
- daily-ops → `calendar.json` (M365 cal), `inbox-triage.json` (M365 mail); brief = calls + needs-reply
  + day plan; skills `/today`, `/prep`. Panels: brief, inbox.
- client-delivery → `clients.json` (inputs), `hours-summary.json` (from `hours-tracker.xlsx`),
  `client-inbox.json`; skills `/client`, `/invoice` (wire `leewood-invoice`). Panels: gauges,
  pipeline, client-inbox, outputs.

**Build packet** then emits: the filled PRD, the folder tree, the §3 schemas, a `30 6 * * *` brief
task prompt, `dashboard.html` with `MC_CONFIG` titled "Riverside Mission Control" / M365 paths /
gauges labeled "bookkeeping hours", `serve-dashboard.bat`, the Cowork kickoff prompt, and the wiring
checklist.

**Client-facing plan** (for Dana): "Open one page each morning and see your day's calls, the client
emails that actually need an answer, where every client's monthly hours stand, and what's ready to
invoice — updated for you automatically. Nothing sends without you. Want to add or cut anything before
we build it?"
