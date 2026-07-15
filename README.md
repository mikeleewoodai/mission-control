# Mission Control

Two Claude skills for building a **Mission Control** — a single Claude Cowork workspace
that pulls a business's recurring work into scheduled workflows, on-demand skills, and a
live dashboard you open in a browser.

Give the blueprint skill a discovery transcript, ops notes, or just a description of what
you want. It returns a build packet you can drop straight into Cowork.

## The skills

### `mission-control-blueprint`

Turns a business into a deployable, local-first Mission Control.

**Input:** a transcript, notes, or a scope.

**Output:** two deliverables — a **build packet** (PRD, folder tree, data-schema contract,
ready-to-paste scheduled-task prompts, the dashboard + serve script, a Cowork kickoff
prompt, and a wiring checklist) and a plain-language **client-facing plan** for confirming
scope before you build.

### `mission-control-cloud`

Optional add-on. Puts the dashboard behind a login on a hosted URL so it's live with the
laptop closed.

**Output:** the Supabase table + RLS migration, a configured Supabase-backed dashboard, the
Cowork write-step that mirrors each refresh to Supabase, a free static-host deploy
checklist, and a client-facing privacy note.

Data schemas are identical to the base build — only *where* the data lives and *how* the
dashboard reads it change. Local files stay the source of truth; Supabase is a mirror for
remote reads.

## Architecture

A Cowork project on a local folder + the Productivity plugin foundation + 4–6 domains + a
data layer + interaction patterns.

- **Domains** — kebab-case folders, each with `CLAUDE.md` (role/voice), `inputs/`
  (human-maintained, never auto-overwritten), `data/` (machine-refreshed), `outputs/`.
- **Data layer** — local files. Connectors are read-only *sources*, never storage.
- **Three-tier memory** — root `CLAUDE.md` → `memory/{domain}/` → `{domain}/CLAUDE.md`.
- **Interaction patterns** — a dashboard served over a local server, a scheduled morning
  brief, on-demand skills, and optionally an autonomous builder queue.
- **The dashboard is a contract** — it fetches specific files by path with specific fields.
  Refreshes and the brief must write to that contract.

## Guardrails

- Read-only connectors
- Draft-only outbound — nothing sent, posted, or deleted without review
- A refresh never writes to any `inputs/` folder
- Everything runs against local files in the project folder
- Cloud mode: RLS is non-negotiable; the anon key is public-safe, the service-role key
  never ships in the dashboard

## Scoping

| Build window | Scope |
|---|---|
| ~3h | foundation + 1 domain + brief |
| ~5h | foundation + 2 domains (or 1 rich + the builder) |
| ~8h | foundation + 2–3 domains |

Never more than ~4 active domains in one window. The rest become placeholder folders that
scale in later with no re-architecture. A solid system across two domains beats a thin,
broken one across five.

## Mission Control vs. Conductor OS

**Conductor** is skills-only, runs unattended on the client's own plan, no servers — best
for lightweight always-on automation the client owns.

**Mission Control** is heavier and visual: a Cowork project with a local data layer and a
dashboard. Choose it when the value is a *command center* — brief, gauges, pipeline, and
inbox in one place — or when there's a richer data layer to maintain.

If the ask is purely "automate these recurring tasks," use Conductor instead.

## Local vs. cloud

Start local. Add `mission-control-cloud` only when the dashboard must be live
**independent of the laptop**. If "from my phone" just means "while my machine is on," a
Cloudflare Tunnel or Tailscale over the existing local server is lighter, free, and needs
no re-architecture.

Cloud adds: Supabase free tier + a free static host (Vercel or Cloudflare Pages). Cost
stays at zero.

## Install

Download the bundle you want from [`skills/`](./skills) and add it to your Claude
environment. In Cowork: drop the `.skill` file in chat → Accept → start a fresh session.

The unpacked sources live at [`mission-control-blueprint/`](./mission-control-blueprint)
and [`mission-control-cloud/`](./mission-control-cloud) if you'd rather read or fork them
directly. Run [`build.sh`](./build.sh) to repack the bundles after editing.

## Repo layout

```
mission-control-blueprint/    unpacked source
  SKILL.md
  references/playbook.md      domain library, schema contract, cron cheatsheet, worked example
  assets/                     dashboard.html, serve scripts, PRD template
mission-control-cloud/        unpacked source
  SKILL.md
  references/cloud-setup.md   SQL detail, write-step, key mapping
  assets/                     dashboard-cloud.html, Supabase migration
skills/                       installable .skill bundles
build.sh                      repack sources → skills/
```

## License

MIT — see [LICENSE](./LICENSE).
