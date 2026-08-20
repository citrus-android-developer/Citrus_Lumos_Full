# Lumos

[繁體中文](README.md) · **English**

> **Lumos — light up the black box of all-AI development, and the path to the right requirements.**
>
> (A revealing charm. It lights the *code* — surfacing the hidden *why*, the decisions, the hard contracts — and lights the *requirements* — forcing understanding through unavoidable dialogue. Lumos doesn't make your requirements correct for you; it lights the path so you can walk it correctly.)

Lumos is the single source for the complete toolset behind the **"graph-as-contract"** methodology. Every all-AI iteration gets woven into a *cloth of understanding*: a knowledge graph is the project's single source of truth — *why it's built this way / where the boundaries are / which behaviors are immutable contracts* — and **commit-time enforcement plus executable contract tests** keep that graph from rotting.

> **This governance is built on [Claude Code](https://claude.com/claude-code).** The whole methodology is designed around Claude Code as the executing AI agent: `skills/` are user-scope Claude Code skills (symlinked into `~/.claude/skills/`), the discipline is injected into the project's `CLAUDE.md`, L1/L3 hooks load at Claude Code session start, and the `[audit:]` independent-legitimacy check uses a **clean Claude agent** (maker ≠ checker). The `scripts/lumos` CLI itself is plain python and runs anywhere — but the full *read-before-act / write-back / independent-audit* loop assumes the agent is Claude Code.

---

## 1. Why Lumos exists

When an AI writes most of the code, the bottleneck shifts from "can it produce code" to "**do we still understand the system, and can we tell when a change is wrong**". Code only tells you *how it currently is*. It cannot tell you:

- *Why* it was built this way (the decision, the alternatives rejected).
- Where the **boundaries** are.
- Which behaviors are **contracts** (changing them = breaking) vs **incidental** (free to refactor).
- Whether something was **verified**, and under what assumptions.
- Whether an action is **reversible**, and how to undo it if it goes wrong.

Lumos keeps that knowledge in a graph of Markdown notes (Obsidian-compatible, but **no Obsidian app required**), and uses a zero-dependency Python CLI + git hooks to make *"not updating the graph" harder than updating it*.

---

## 2. The core idea: graph-as-contract

- The **graph is the single source of truth.** When the graph and code/memory/assumptions disagree, the graph wins.
- **Read before you act.** Before touching an existing system, your first move is `lumos`, not `grep`/`Read`/DB queries. The graph gives you contracts and boundaries first; code/DB only confirm details.
- **Write on the way out.** When done, write the decisions / verifications / contracts back.
- **Enforce at commit time.** A pre-commit hook blocks "changed code without updating the graph"; `lumos doctor` proves the graph is internally consistent and that every load-bearing claim is bound to an executable test.

---

## 3. What's in the toolkit

| Category | Files / Commands | Role |
|---|---|---|
| **CLI** | `scripts/lumos`, `scripts/test_lumos.py` | Pure python3 stdlib, zero dependencies, **61 top-level commands**. Read / write (write-then-self-verify) / inspect (`doctor`) / archive. |
| **Contract-guard scaffold** | `lumos guard list/scaffold/bind/audit/trace` | Dialogue-driven: list unbound `★INVARIANT★`, scaffold **red-by-default** test stubs, bind `[test:]`, stamp independent `[audit:]`. |
| **Adversarial-audit loops** | `lumos pitfalls`, `code-loop`, `canary`, `loop`, `fold-check`, `refcheck` | `pitfalls --diff` classifies findings by tier (standard/high); tier=high branches go through canary-guarded `code-loop` (adversarial code review); `design-loop` audits a spec adversarially *before* implementation; `fold-check` catches design fold-drift. |
| **Impact / integrity** | `lumos impact`, `anchor verify/approve`, `lumos testmap` | `impact` reverse-looks up graph nodes affected by a changed file (direct + indirect) and surfaces matched incidents via `pitfall_when`; `anchor` guards test/gate files from *silent* drift (a change detector — catches accidental/unnoticed edits; same-repo self-signed, not a trust root against deliberate attack); `testmap` builds a file↔test dependency map (naming/content/cochange signals) and `affected` suggests which tests to run for a diff (advisory; promoted via a two-layer gold-pair recall of 1.0 on a real repo). |
| **git hooks** | `scripts/hooks/` | pre-commit hard-blocks "code without graph"; post-commit logs any bypass; pre-push runs `doctor --ci` **+ `anchor verify` + hard-blocks tier=high branches that haven't passed `code-loop`**. |
| **Claude hooks** | `scripts/hooks/claude/` | PreToolUse: injects the impact radius before you edit code; PostToolUse: self-sufficiency / verification-rot post-check. (ADR 2026-07-06: the per-turn Stop nag for code-loop was removed — too noisy; enforcement is the pre-push gate alone.) |
| **Installers** | `get.sh`, `get.ps1`, `install.sh`, `scripts/merge-claude-settings.py` (underlying: `install-hooks.sh` / `install-graph-toolchain.sh`) | Machine layer (`get.*`) + project layer (`lumos init`) — two-step onboarding, hook setup, and Claude settings merge. |
| **Discipline template** | `scripts/templates/graph-discipline.md` | The "graph-first" rules injected into each project's `CLAUDE.md`. |
| **Skills** | `lumos-project-notes`, `core-knowledge`, `design-loop`, `code-loop`, `pitfalls-gapfill` | Graph read/write rules and adversarial-audit loop orchestration written *for the AI* (user-scope, shared across projects). |

---

## 4. Quick start

### 4a. A project already onboarded to Lumos
Clone it and run one command — it even clones Lumos for you:

```bash
git clone <your-project> && cd <your-project>
python3 scripts/lumos bootstrap     # clones Lumos (if missing) + user-scope skills + global lumos + repo hooks
```

Then **restart your Claude Code session** (L1/L3 hooks load at session start).

> `bootstrap` does **not** pull updates by default. To refresh later: `git -C ~/harness/lumos-toolchain pull` (everything is symlinked), or `lumos bootstrap --pull`.

### 4b. Onboard a brand-new project (two commands)

**① Once per machine** (remote, clones Lumos automatically):

```bash
curl -fsSL https://raw.githubusercontent.com/citrus-android-developer/Citrus_Lumos_Full/main/get.sh | bash
# then restart your Claude Code session
```

`get.sh` installs the machine layer: clones Lumos + user-scope skills + global `lumos`. (You can `curl -fsSL <url> -o get.sh` to inspect first; pass flags with `… | bash -s -- --pull`.)

**② Once per project** (inside your project):

```bash
cd <your-project> && lumos init       # slug defaults to folder name; customize with --name <slug>
```

`lumos init` installs the project layer: creates `docs/<slug>-knowledge/{Systems,…,MOC}` + `.gitignore`, vendors the toolset, and installs pre-commit/pre-push gates. Existing graph data is **never overwritten** (`--force` fills in missing pieces only; `--no-hooks` creates just the graph scaffold).

<details><summary>Advanced / offline: manual install-graph-toolchain</summary>

```bash
git clone https://github.com/citrus-android-developer/Citrus_Lumos_Full ~/harness/lumos-toolchain
cd ~/harness/lumos-toolchain && ./install.sh        # user-scope skills (symlinked)
python3 scripts/lumos install                       # (optional) global `lumos` on PATH
scripts/install-graph-toolchain.sh --target <your-project> --slug <name>
```
</details>

### 4c. Windows (native PowerShell)
Prerequisites: Git for Windows (bundles bash for git hooks), python on PATH, Claude Code.

```powershell
irm https://raw.githubusercontent.com/citrus-android-developer/Citrus_Lumos_Full/main/get.ps1 | iex
# restart your Claude Code session (L1/L3 load at session start)
# if `lumos` isn't found: add %USERPROFILE%\.local\bin to PATH
cd <your-project>; lumos init
```

`get.ps1` installs the machine layer: clones Lumos (if missing) and calls `lumos install` — global `lumos` via a `%USERPROFILE%\.local\bin\lumos.cmd` shim, user-scope skills via directory **junction** (`mklink /J`, falls back to copy on failure), no admin rights required. Individual Claude hook `.py` files are always **copied** to `~/.claude/hooks/`. Then `lumos init` sets up the project layer (graph scaffold + vendored tools + git/Claude hooks), same as Unix.

### Why two install layers?
CI only checks out the project repo, and git hooks are per-repo — so the **toolchain must be vendored into each project**. **Skills are user-scope** (one shared copy, symlinked to `~/.claude/skills/`). `git pull` on the Lumos clone updates skills + global CLI instantly; the vendored toolchain inside a project refreshes via `lumos update`.

---

## 5. The mental model: nodes and tags

### Node types (`type:` in frontmatter)
`system` (a module: flows, contracts, deps) · `verification` (a test/audit record) · `issue` (a finding) · `project` (a plan) · `moc` (a map/index).

### `summary` symbol lines (Systems / Issues)
A `summary:` block scalar where each line starts with a prefix, so you grasp a module at a glance:

| Prefix | Meaning | Prefix | Meaning |
|---|---|---|---|
| `FLOW:` | core flow `a→b→c` | `VERIFY:` | verification link `[[..]]` |
| `KEY:` | key concept/field | `DECISION:` | decision pointer (short) |
| `DEP:` | dependency module `[[..]]` | `FLAG:` | semantic tag (`TECHNICAL`/`ORIGIN`…) |
| `TEST:` | test status | `AUTH:` | auth method |

### The three enforced "chains" (Lumos's differentiators)

**Contract chain** — *is this a rule, and is it proven?*
```
KEY:★INVARIANT★ <business contract; changing = breaking> [test:MethodName] [audit:model/date]
                 └ the claim          └ executable proof    └ independent clean-agent legitimacy check
KEY:★DEBT★ <known-incidental behavior; free to change, not breaking>
```
- `★INVARIANT★` **must** bind `[test:]` (a real test method that exists in code) — else `doctor` reports a *naked contract* and blocks.
- It **must** then carry `[audit:]` — a verdict from a **context-free agent** that the rule is genuinely a contract and the test isn't a tautology (maker ≠ checker). Missing → *unaudited*, blocks under `--ci`.
- *If unsure whether something is a contract, don't mark it.* Never reverse-engineer "it's probably a contract" from code.

**Reversibility chain** — *can this be undone, and how?* (Systems only)
```
KEY:★IRREVERSIBLE★ <can't undo: prod migration / go-live> [rollback:decisions]
KEY:★CHECKPOINT★   <hard to undo: deploy to a test box>
unmarked = reversible (git/test-level, go ahead)
```
- `★IRREVERSIBLE★` **must** carry `[rollback:decisions]`, and the node's `decisions[]` must contain an entry with a non-empty `rollback` field (the actual revert SQL / compensation steps) — else `doctor`'s **Check R** blocks.
- `★CHECKPOINT★` *should* carry it (missing = warning, never blocks).
- **Ceiling:** `[rollback:]` proves *you wrote down an undo path*, **not** that it runs or still matches the current schema — same honesty as `[test:]`/`[audit:]`. Don't read "has a rollback" as "safe".

### Frontmatter fields
`status` (`doing`/`pass`/`open`/`done`/`stale`/`superseded`…) · `verified_by` / `plan_refs` / `related` / `tags` (lists) · `decisions[]` (ADR: `content`/`context`/`alternatives_considered`/`why_chosen`/`trade_offs`/`decided`/`valid`/`superseded_by`/`rollback`) · `valid_under` / `revalidate_when` (re-validation conditions) · `core_refs` (pointer to a cross-project core graph).

> ⚠ Multiple wikilinks must be a YAML **list**, one per line (`- "[[A]]"`). A single string `"[[A]], [[B]]"` creates ghost nodes. Always edit scalars/lists/decisions via `lumos set`/`append`/`decision-add` (safe format + self-verify), not by hand.

---

## 6. Daily workflow

```
ENTER   ── lumos search <kw> → lumos context <node> → lumos contracts <node>   (read graph BEFORE grep/DB)
DESIGN  ── before implementing a spec: run design-loop (canary-guarded adversarial audit) until
           `lumos loop status` converges; write the design as a plan node (Projects/X_plan)
WORK    ── make the change; before editing code the impact hook auto-injects affected graph nodes
           + matched incidents; for new INVARIANTs: guard scaffold → bind → audit
WRITE   ── lumos set/append/decision-add to record decisions, verifications, contracts
VERIFY  ── lumos lint <node>        (fast, single file — run right after writing a node)
        ── lumos doctor             (whole-graph health)
FINISH  ── lumos testmap affected --diff <base>..HEAD for suggested tests (advisory);
           lumos pitfalls --diff <base>..HEAD; tier=high → code-loop (canary-guarded adversarial
           code review) → code-loop pass records the convergence ledger
COMMIT  ── pre-commit blocks code-without-graph; pre-push runs doctor --ci + anchor verify +
           code-loop check (hard-blocks tier=high branches that haven't passed)
```

Enforcement layers, fastest to hardest:

| Layer | Command | Scope |
|---|---|---|
| **impact** | `lumos impact --file <file>` (+ PreToolUse hook) | Before editing code: pushes affected graph nodes (direct + indirect) + matched incidents; informational, never blocks |
| **lint** | `lumos lint <node>` | One file, no repo scan — predicts what pre-push will reject |
| **doctor** | `lumos doctor [--ci]` | Whole graph: orphans, broken links, `verified_by` sync, **Check T** (contract→test→audit), **Check R** (reversibility), frontmatter lint |
| **code-loop** | `lumos code-loop check` | tier=high branch not yet passed adversarial code review → pre-push single-point hard-block |
| **pre-push** | `doctor --ci` + `anchor verify` + `code-loop check` | Three-in-one hard gate before every push |

---

## 7. Command reference

**Read**
```bash
lumos context <node> [--brief]   # node + neighbors compressed index (contracts surfaced at top)
lumos contracts [<node>]         # contract register: ★INVARIANT★ (+ bound tests) / ★DEBT★
lumos search <kw> [--path P]     # full-text search (replaces Obsidian search)
lumos links / backlinks <node>   # outgoing / incoming edges
lumos map <node> [--depth N]     # neighborhood tree
lumos decisions [<node>] [--superseded]   # ADR decisions / scan overturned ones
lumos stale [--match S] [--candidate]     # stale verifications / "what to re-verify when X changes" (risk-sorted by hub-ness × age; --legacy for alphabetical)
lumos recent [N] · lumos stats · lumos export --format mermaid|dot|html
```

**Write** (all self-verify after writing)
```bash
lumos new system|issue|project|verification <name>   # scaffold a node (prints how to fill tags)
lumos set <node> <field> <value>                     # scalar field (status/updated/...)
lumos append <node> verified_by|plan_refs|related|tags "[[X]]"
lumos decision-add <node> "<content>" --decided DATE [--context ..] [--why ..]
lumos decision-supersede <node> "<substr>" --by "..." [--ended DATE]
```

**Contracts & verification**
```bash
lumos guard list [--unbound]                         # ★INVARIANT★ binding status (real/dangling/fake/naked) + audit state
lumos guard scaffold --node S --invariant "<substr>" --method M --type pure|behavioral|state --claim "..." [--platform P]
lumos guard bind  <node> "<substr>" <method> [--platform P]   # write [test:method] onto the KEY line (multi-platform: [test:P:method])
lumos guard audit <node> "<substr>" [--model sonnet] [--date D]   # stamp [audit:] after an independent review
lumos guard trace [<node>]                           # contract → guard test → Verification evidence chain
lumos sync-verified-by [--apply]                     # fix missing verified_by (doctor Check 3)
```

**Adversarial-audit loops / impact / integrity**
```bash
lumos pitfalls --diff <base>..HEAD [--no-lint]       # scan diff for risks, classify by tier (standard/high); high → run code-loop
lumos code-loop check [--json]                        # tier=high branch not yet passed → rc1 (pre-push single-point hard-block)
lumos code-loop pass|skip --note "<reason>"          # record / escape-hatch convergence ledger (pass binds to HEAD sha; skip leaves a trail)
lumos canary record caught|missed --loop <id> ...    # record design-loop / code-loop canary wakefulness
lumos loop status <id> --need 2 --gate               # convergence gate (K-streak ∧ G1 ∧ G2)
lumos loop status <id> --gate --spec <spec.md> --settle <list.json>   # settle mode (all-claims-settled ∧ G1 ∧ G3; --spec required)
lumos loop compress <notes> / lumos loop verify-progress <id>   # whitelist compression / structural cross-check
lumos loop status <id> --gate --panel                # panel gate (does not consume --need)
lumos loop capture-counts --finder ... --from-pitfalls <range>   # capture-recapture counts helper
lumos fold-check <spec>                               # catch design fold-drift (mirrored sections / value drift / missing reversal)
lumos refcheck <spec> --repo . [--json]              # mechanically verify spec→repo references (missing / line-number out of range)
lumos impact --file <file> [--depth N] [--json]      # reverse-lookup affected graph nodes (direct + indirect) + matched incidents (pitfall_when)
lumos testmap build [--repo R] [--json]              # file↔test dependency map: mine edges via naming/content/cochange signals into .lumos/testmap.json
lumos testmap affected --diff <range> [--json]       # suggest tests for a diff + uncovered files + 3-signal staleness hints (advisory, always rc0)
lumos anchor verify | approve --note "<reason>"      # test/gate file integrity: verify fingerprint / approve a deliberate change as new baseline
```

**Govern & inspect**
```bash
lumos lint <node>                # single-file fast check (tags/format/contracts/reversibility)
lumos doctor [--ci] [--suggest]  # whole-graph health; --ci = strict + no color (blocks)
lumos gov [<node>] [--since N]   # read-only governance ledger: which gates flagged a node, hard vs soft
```

**Install / lifecycle**
```bash
lumos install [--force] · lumos uninstall          # global lumos symlink on ~/.local/bin
lumos update [--source PATH] [--no-pull]           # refresh this project's vendored toolset from the Lumos source
lumos bootstrap [--pull]                            # one-shot full setup
lumos archive [--days N] [--apply]                 # roll old passed Verifications into Archive/ (live guards protected)
```

### Uninstalling

Lumos installs in two layers, with one command each:

- **Project layer** (this repo's hooks / vendored toolkit / CLAUDE.md injection / graph), run inside the project:
  ```bash
  lumos deinit              # full reverse of init: unbar gate + remove toolkit + strip CLAUDE.md block + delete graph (interactive confirm)
  lumos deinit --keep-graph     # keep the graph, remove everything else
  lumos deinit --dry-run        # preview only, change nothing
  lumos deinit -y               # skip interactive confirm (for CI / non-interactive environments)
  lumos deinit --source <path>  # specify Lumos source (for self-protection validation)
  ```
  deinit never auto-commits and never touches machine-shared items; if it detects a standalone vault (graph == repo root) it force-keeps the graph to avoid deleting the whole repo.
- **Machine layer** (global `~/.local/bin/lumos`, user-scope skills): `lumos uninstall`.

> Full removal = run `lumos deinit` in each project, then `lumos uninstall` + optionally `rm -rf ~/harness/lumos-toolchain`.

Run `lumos --help` for the authoritative, current list.

---

## 8. The governance ledger (`lumos gov`)

Governance signals used to be scattered across hooks. `lumos gov` is a **read-only aggregator** over three local JSONL logs:

- `docs/.bypass-log.jsonl` — L2 pre-commit bypasses (post-commit writes it)
- `docs/.rot-queue.jsonl` — L3 verification-rot findings
- `docs/.governance-log.jsonl` — `doctor --ci` findings (Check T / Check R), single writer

```bash
lumos gov                # timeline of all gate events
lumos gov OrderService   # which gates flagged this node, hard-block vs soft, with dates
```

> This is a **local developer-visibility** tool (all three logs are gitignored), not a compliance artifact. L2 bypass events carry no node, and L3 keys on Verification paths, so per-node views are partial — the output says so.

---

## 9. Updating

- **Skills + global CLI** (symlinked): `git -C ~/harness/lumos-toolchain pull` — instant, no reinstall.
- **A project's vendored toolset + `CLAUDE.md` discipline block**: run `lumos update` inside that project (pulls the Lumos source, re-vendors, re-injects). Your graph data is protected.

---

## 10. Design principles

- **DRY / YAGNI / TDD**, frequent commits; the CLI is stdlib-only and CI-runnable.
- **Don't over-govern.** Mark only what's load-bearing; soft stays soft; never add ceremony without proportional value.
- **Honest ceilings.** The gates are a floor and friction, not an oracle. Tools prove *form* (a test exists, a rollback is written, a clean agent reviewed) — never *validation* (the rule is right for today's business, the rollback actually runs). `--no-verify` bypasses git gates — that's self-owned and logged. PreToolUse Claude-hook injections are push-only and ignorable. The judgment stays with people.
- **Maker ≠ checker.** No-right-answer judgments (is this a real contract? is the test a tautology?) go to an independent, context-free agent — not the author.

---

## 11. Boundary & further reading

Lumos holds only the **generic graph toolset**. A project's own things stay out: business graph content, the app's release/deploy scripts (e.g. `release.sh`), tech-stack skills (vue/csharp project-scope skills).

- Onboarding details: [ONBOARDING.md](ONBOARDING.md)
- Full architecture: [ARCHITECTURE.md](ARCHITECTURE.md) (single source → two scopes → consumers, lifecycle commands, subcommands, enforcement pipeline)
- Difference vs SDD: [SDD-vs-Lumos.md](SDD-vs-Lumos.md)
