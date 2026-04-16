# AGENT PLAYBOOK

1. The repository is a chezmoi-managed dotfiles tree located in the chezmoi source directory (`chezmoi source-path` shows it); every file mirrors something in `$HOME` (e.g., `dot_zshrc` -> `~/.zshrc`).
2. Treat every tracked shell file as user-facing startup logic; prioritize vanilla zsh compatibility and gate bash-only extensions behind feature checks.
3. Chezmoi is the source of truth; prefer `chezmoi edit <target>` or edit files here then run `chezmoi apply` to materialize.
4. Author works on macOS with Homebrew, OrbStack (Docker engine/CLI/Compose), Powerlevel10k, oh-my-zsh, mise, Bun, Go, and LM Studio CLI already wired in the shell startup; Arch is the alternate target.
5. If you add Cursor rules or Copilot instruction files, summarize their location and purpose in this document so future agents inherit the constraints.
6. Keep everything ASCII unless the upstream file already relies on Unicode glyphs (current configs are ASCII only).
7. Always run `git status` before and after edits; never stomp user changes that may live alongside your work.
8. Remember that `$ZSH` points to `~/.oh-my-zsh`; do not assume oh-my-zsh is vendored in this repo.
9. When in doubt, mimic the indentation style already present (two spaces in conditionals, aligned comments, blank line separation between blocks).
10. Provide concise inline comments only when you add non-obvious logic; this repo avoids comment noise.

## CHEZMOI WORKFLOW
11. `chezmoi status` shows drift between repo and workstation; run it whenever you need to confirm pending changes.
12. `chezmoi diff` lets you preview differences in your local edits versus what would be applied to `$HOME`.
13. `chezmoi apply --dry-run --verbose` is the safest way to preview what will change without touching the real dotfiles.
14. `chezmoi apply` should only be run after you are confident diff output looks correct.
15. Use `chezmoi cd` if you need to drop into this repo from elsewhere; it opens this same directory.
16. New dotfiles must respect chezmoi naming (`dot_<file>`, `dot_config/<path>`, etc.) and should be added with `chezmoi add` if created outside this tree.
17. Do not commit secrets; chezmoi supports templates and encrypted data if needed, but none are currently present.
18. Respect macOS-specific assumptions (Homebrew paths under `/opt/homebrew`, OrbStack-provided Docker context/CLI, LM Studio CLI additions).
19. When testing environment changes, open a new shell so .zshrc reloads cleanly.
20. Use `topgrade` via the provided `update` alias if you need to validate the global maintenance command path.

## BUILD / LINT / TEST COMMANDS
21. There is no application build pipeline; validation focuses on shell startup correctness and linting.
22. Run `zsh -n dot_zshrc` for a fast syntax check before committing.
23. Run `shellcheck -x dot_zshrc` to lint with awareness of sourced files and SC directives already in place.
24. `chezmoi doctor` validates chezmoi setup on the host; use it when diagnosing environment-specific issues.
25. `chezmoi verify` can be used after deployments to ensure the live files match what the repo expects.
26. To smoke-test startup, execute `ZDOTDIR=$(pwd) ZSH=$(echo ~/.oh-my-zsh) ENV=dev HOME=$HOME zsh --login -i` from inside the repo to force-load the edited file.
27. To test Powerlevel10k-specific sections, source `~/.p10k.zsh` manually after verifying the file exists, because chezmoi does not track it.
28. For completions (bun), run its completion command (`bun completions`) before wiring new paths, then restart the shell.
29. Always test alias additions by invoking them directly in a new shell to catch quoting mistakes early.
30. Record any new test commands you introduce inside this document so agents know how to reproduce them.

## RUNNING A SINGLE TEST
31. Use `shellcheck -x dot_zshrc --enable=all --severity=style --include=SC2296,SC1090` to lint only the tracked shell config (this is the closest equivalent to a single test case).
32. For a minimal parse test of just the block you edited, pipe it through `zsh -n <(sed -n 'START,ENDp' dot_zshrc)` by replacing START/END with the relevant line numbers.
33. If you add standalone scripts later, adopt the convention `shellcheck path/to/script` plus `bats test/<script>.bats` and document the invocation lines here.
34. When editing alias or function definitions, run `() { source ./dot_zshrc; <function>; }` within a subshell to limit side effects.
35. Document any reproducible bug-specific checks directly inside your pull request description so downstream agents can re-run them.

## CODE STYLE – GENERAL
36. Maintain max line length of ~120 characters; wrap earlier if readability suffers.
37. Prefer double quotes for strings and paths to preserve variable expansion safety; single quotes only when expansion must not occur.
38. Exported variables should use uppercase snake case (`DOCKER_HOST`, `ZSH_THEME`), while local helper variables can be lowercase.
39. When referencing paths, use `$HOME` instead of `~` so chezmoi template expansion remains deterministic.
40. Group related `export` statements together, separated by blank lines between conceptual clusters (e.g., Docker vs. LM Studio).
41. Use two-space indentation inside conditionals and loops, as already seen in the completions and PATH guards.
42. Keep shell directives (e.g., `# shellcheck disable=...`) directly above the line they influence.
43. For large feature toggles, prefer early exits or guard clauses rather than nested conditionals.
44. When referencing environment-dependent paths (Colima, LM Studio), gate them with `if [[ -d ... ]]` to avoid startup warnings.
45. Avoid sourcing files twice; guard with `[[ -f ... ]]` and `source` once per block.

## CODE STYLE – IMPORTS & SOURCING
46. Always check readability of `source` statements; align them when multiple consecutive inclusions appear.
47. Document non-obvious sources with a short comment (e.g., “# mise activation hook”).
48. Use `${var}` brace expansion when concatenating, especially inside strings that mix literal characters and variables.
49. When adding new completions directories, update `FPATH` only if the directory exists and is not already present.
50. Keep sourcing blocks near the top of the file if they impact shell startup (instant prompt, oh-my-zsh, theme configuration).
51. Lazy-load optional tooling by wrapping `source` calls inside `if command -v <tool> >/dev/null 2>&1; then ... fi`.
52. Maintain alphabetical ordering when adding multiple plugin names or environment-specific exports to keep diffs predictable.
53. If you need to introduce template logic (chezmoi supports go templates), keep it minimal and clearly marked to avoid confusing raw shell.
54. When referencing secrets, rely on environment variables or external secret managers; do not hardcode values.
55. If you source user-specific files (like custom functions), gate them with `[ -f <file> ]` and comment on their ownership.

## CODING STANDARDS – TYPES & VARIABLES
56. Shell is dynamically typed; emulate type clarity via naming: prefixes like `is_`, `has_`, `path_`, `count_` communicate intent.
57. Avoid global side effects unless necessary; wrap complex logic in functions and invoke them near the bottom of the file.
58. Use `local` inside functions to prevent accidental leakage into the interactive session.
59. Defaults should be established with `${VAR:-default}` pattern; keep the default literal short and documented.
60. For arrays, use parenthesis and `typeset -a` or `typeset -g` if needed; keep array definitions single-line unless readability demands multi-line.
61. When referencing plugin lists (`plugins=(git)`), append new entries on the same line unless the list grows unwieldy, then switch to multi-line alignment with one entry per line.
62. Keep alias names lowercase and descriptive; prefer verbs (`alias update="topgrade"`).
63. When storing commands in variables, wrap them with `command ${(q)}` patterns if you need to preserve spacing.
64. Document environment variables that influence third-party tools (e.g., `DOCKER_HOST` for Colima) to prevent unintentional overrides.
65. Remove dead variables when they no longer serve a purpose; dotfiles should stay minimal.

## NAMING & ORGANIZATION
66. Headings in this file use uppercase words separated by hyphens (`## SECTION NAME`) to keep grep-friendly anchors.
67. Group functionality: PATH management, completions, version managers, editor settings, and aliases each get their own block separated by blank lines.
68. Follow chronological ordering during startup: caches, package managers, completions, prompt, language runtimes, tool-specific exports, editor defaults, aliases.
69. Use descriptive comments when disabling shellcheck rules, referencing the rule IDs (`SC2296`, `SC1090`).
70. Keep custom functions (if added later) at the bottom after environment setup but before alias definitions if they support those aliases.
71. Template directives (if introduced) must sit at column 1 to remain obvious; avoid mixing them with inline code.
72. Keep new files named `dot_<name>` or `dot_config/<path>`; avoid leading dots because chezmoi handles them automatically.
73. When adding directories, prefer `private_dot_<name>` for sensitive data so chezmoi can manage encryption separately.
74. Document any new file in this AGENTS guide under an appropriate section.
75. Every addition should mention whether it is macOS-specific or cross-platform.

## PATH & TOOLING
76. PATH mutations should add `$HOME/.local/bin`, `$HOME/.local/go/bin`, and `$HOME/.lmstudio/bin` only once; de-duplicate before exporting.
77. Keep Homebrew paths via `eval "$$(/opt/homebrew/bin/brew shellenv)"` near the top so later PATH edits see brew binaries.
78. Mise already injects shims; avoid re-adding its bin directories unless troubleshooting.
79. Bun completions rely on `$HOME/.bun/_bun`; wrap sourcing in existence checks to avoid warnings.
80. OrbStack provides the Docker engine, CLI, and Compose on macOS—do not brew-install docker/compose there; Arch uses the packaged docker/docker-compose pair.
81. Powerlevel10k instant prompt block must stay at the very top to avoid prompt flicker.
82. Keep `ZSH_THEME` and `plugins` definitions above the `source "$ZSH/oh-my-zsh.sh"` line so oh-my-zsh reads the configuration.
83. Editor defaults (`EDITOR`, `VISUAL`) belong toward the bottom, after PATH finalization, so they inherit any environment tweaks.
84. Document any new aliases referencing third-party tools, noting whether they require brew installs or mise shims.
85. If you add launch agents or background tasks, mention their startup hooks here plus any log locations.

## ERROR HANDLING
86. For standalone scripts, enable `set -euo pipefail` (bash) or `setopt errexit nounset pipefail` (zsh) near the top; dotfiles typically avoid it, but scripts should use it.
87. Guard optional dependencies with informative echo statements inside `if` blocks to make troubleshooting easier.
88. Prefer `command -v <tool> >/dev/null 2>&1` to check for binaries; avoid `which` due to portability issues.
89. When altering PATH, append rather than prepend unless the tool strictly requires precedence; document the rationale when deviating.
90. Keep fallback logic explicit—if a directory is missing, exit the block silently rather than failing the login shell.
91. Wrap risky commands (those that might prompt) in conditionals so they do not block the login shell.
92. When interacting with Docker via Colima, rely on the exported `DOCKER_HOST` instead of running `docker context use` commands inside the shell startup.
93. Avoid modifying `ZDOTDIR` inside this repo; chezmoi expects the current layout.
94. If you add long-running hooks, background them (`command & disown`) to keep login fast, but only if they tolerate asynchronous execution.
95. Remember that alias definitions override commands; verify there is no accidental shadowing of system binaries.

## TESTING & VERIFICATION CHECKLIST
86. After editing, run `git status` to ensure only intentional files changed.
87. Run `zsh -n dot_zshrc` and `shellcheck -x dot_zshrc` sequentially; both must pass.
88. Optionally run `chezmoi diff` to confirm the rendered file looks right inside `$HOME`.
89. Open a new terminal tab to confirm Powerlevel10k still renders correctly (prompt should appear without delays).
90. Trigger `mise doctor` if you touch its initialization block to make sure versions resolve cleanly.
91. Verify `bun`, `deno`, and `go` commands if you changed their completions PATH settings.
92. Run `which <alias>` for any new alias to confirm it maps to the intended command.
93. Ensure LM Studio PATH additions remain at the end so earlier PATH manipulations are not overridden.
94. Keep `EDITOR` and `VISUAL` exports consistent (`nvim` and `code --wait` respectively) unless the user specifically asks for changes.
95. Double-check shellcheck suppression lists; remove unused suppressions to avoid masking new warnings.

## DOCUMENTATION DUTIES
96. Update this AGENTS file whenever workflows, commands, or code style conventions change.
97. Note any new directories or files along with their purpose so future agents understand the expected structure.
98. If you add tests or scripts, expand the build/lint/test section with explicit commands and single-test instructions.
99. Summaries for large changes should reference both the chezmoi path and the realized `$HOME` path for clarity.
100. When adding automation policy files (Cursor or Copilot), summarize their key directives here and link to the filepath.
101. Keep line-oriented instructions (like this document) around 150 lines so they remain digestible but thorough.
102. Document any macOS-specific assumptions (brew paths, LaunchAgents) for portability.
103. Mention if you introduce template variables (e.g., `{{ .chezmoi.os }}`) so later agents know to render before editing.
104. Keep instructions chronological within sections for easier scanning.
105. Prefer actionable sentences starting with verbs to maintain a consistent tone.
106. Cross-link related sections via references (e.g., “see CODE STYLE – GENERAL line 36”) when clarity demands it.
107. Avoid duplicating text; reference existing bullets where possible.
108. Validate this file using `wc -l AGENTS.md` to confirm you stayed near 150 lines.
109. Remember that this document is version-controlled—treat it like code with reviews and diffs.
110. Close every update with a short note in your PR/commit summarizing documentation edits.
111. Keep the instructions self-sufficient so agentic tools do not need to read extra context.
112. Emphasize safety: never remove user data, never commit credentials, always dry-run.
113. Encourage experimentation only inside throwaway shells, never the user’s main config without confirmation.
114. Maintain readability by avoiding overly long paragraphs; short bullets win.
115. This section intentionally reminds you to keep AGENTS.md authoritative.

## BRANCH & CI POLICY
116. `main` is protected—create feature branches (e.g., `feat/*`, `fix/*`) for every change and merge via pull requests only.
117. Never force-push or commit directly to `main`; keep history linear by rebasing feature branches before opening a PR when necessary.
118. `.github/workflows/ci.yml` defines mandatory jobs: `lint` (shell/Neovim syntax checks), `arch`, and `macos`, with a final aggregating job named `ci`.
119. The `ci` job depends on all other jobs and is the target of branch protection—do not rename or remove it without updating repository rules.
120. When adding new CI coverage (extra OSes, lint steps), document the change here and ensure the new job is included in the `ci` job’s `needs` list.

## AUTOMATED TOOL INSTALLS
121. `run_after_install-tools.sh` executes on every `chezmoi apply` and installs platform packages plus `mise` toolchains; keep it idempotent.
122. Package manifests live at the repo root (`Brewfile`, `packages-arch.txt`); update them to add/remove dependencies and keep comments concise.
123. The script detects macOS (brew bundle) and Arch (yay + package list). Extend it if you add new OS support.
124. The installer also bootstraps oh-my-zsh, Powerlevel10k, and tmux TPM when missing; keep those paths consistent with `.zshrc`/`.tmux.conf` expectations.
125. Guard long installs by setting `CHEZMOI_INSTALL_TOOLS=0` when you want to skip them (e.g., ad-hoc testing); document permanent skips in AGENTS first.
126. `.mise.toml` is tracked as `dot_mise.toml`; run `mise install` or `mise apply` whenever tool versions change and commit the updated file.
