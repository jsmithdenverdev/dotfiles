# PLAN.md - Dotfiles Enhancement Plan

## Overview
This document outlines the planned changes to improve the dotfiles dependency management system based on user feedback.

---

## 🎯 Requirements

1. **gh-dash Installation**: Use `gh extension install` instead of standalone package
2. **PostgreSQL Alignment**: Both macOS and Arch should use latest PostgreSQL
3. **LM Studio**: Add LM Studio installation via package managers
4. **Post-Install Commands**: Need mechanism to run commands after package installation

---

## 🔍 Research Findings

### 1. LM Studio Availability
- ✅ **macOS**: Available as Homebrew cask `lm-studio` (version 0.3.37)
- ❌ **Arch Linux**: Not available in official repos or AUR
- **Conclusion**: macOS-only installation via Homebrew cask

### 2. gh CLI and Extensions
- ✅ `gh` available via Homebrew and Arch repos
- ✅ `gh extension install dlvhdr/gh-dash` is the official way to install extensions
- ❌ mise does NOT have a gh plugin
- **Conclusion**: Keep gh in native package managers, add post-install step for extensions

### 3. mise Capabilities
- ✅ Has `[tasks]` section for custom commands
- ✅ Can run shell scripts
- ❌ No built-in "post-install hooks" per tool
- ❌ No gh plugin available
- **Conclusion**: mise tasks are great for maintenance, but not suitable for package post-install hooks

---

## 💡 Proposed Solutions

### Option A: Post-Install Function in install.sh (RECOMMENDED)

**Approach:**
Add a new `install_gh_extensions()` function to install.sh that runs after gh is installed.

**Pros:**
- ✅ Simple and straightforward
- ✅ Keeps gh in native package managers (fast binary installation)
- ✅ Idempotent (can check if extension already installed)
- ✅ Works on both macOS and Arch
- ✅ Easy to add more extensions in the future

**Cons:**
- ⚠️ Requires gh to be installed first (already guaranteed by install flow)

**Implementation:**
```bash
# In install.sh, add new function:
install_gh_extensions() {
    if ! command -v gh &>/dev/null; then
        log "WARN" "gh not found, skipping extension installation"
        return 0
    fi
    
    log "INFO" "Installing gh extensions..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would run: gh extension install dlvhdr/gh-dash"
        return 0
    fi
    
    # Check if already installed
    if gh extension list | grep -q "dlvhdr/gh-dash"; then
        log "INFO" "gh-dash extension already installed"
    else
        gh extension install dlvhdr/gh-dash
        log "SUCCESS" "gh-dash extension installed"
    fi
}

# In main() function, add after install_mise_tools:
install_gh_extensions
```

**Flow:**
```
install.sh
  ↓
Install packages (gh included via Brewfile/packages-arch.txt)
  ↓
Install oh-my-zsh
  ↓
Install powerlevel10k
  ↓
Install mise tools
  ↓
Install gh extensions (NEW)  ← gh extension install dlvhdr/gh-dash
  ↓
Done!
```

---

### Option B: mise Task for Extension Management (NOT RECOMMENDED)

**Approach:**
Use mise tasks to install extensions after first-time setup.

**Implementation:**
```toml
# .mise.toml
[tasks.setup-gh]
description = "Install gh extensions"
run = """
  if command -v gh >/dev/null; then
    gh extension install dlvhdr/gh-dash
  fi
"""
```

**User would run:**
```bash
./install.sh
mise run setup-gh  # Manual step
```

**Pros:**
- ✅ Declarative configuration

**Cons:**
- ❌ Requires manual step (not automated)
- ❌ User might forget to run it
- ❌ Doesn't fit with "run install.sh and done" philosophy

**Verdict:** REJECTED - Too manual, not integrated into install flow

---

### Option C: Move gh to mise (NOT RECOMMENDED)

**Approach:**
Since mise doesn't have a gh plugin, this would require creating a custom plugin or using a workaround.

**Cons:**
- ❌ mise has no gh plugin
- ❌ Would require custom plugin development
- ❌ Slower than native package manager
- ❌ Overkill for a tool that doesn't need version management
- ❌ Adds unnecessary complexity

**Verdict:** REJECTED - Not worth the effort, gh doesn't benefit from version management

---

## 📋 Detailed Implementation Plan

### Change 1: Remove gh-dash from Package Lists

**Files to modify:**
- `Brewfile` - Remove `brew "gh-dash"`
- `packages-aur.txt` - Remove `gh-dash`

**Reason:** Will be installed via `gh extension install` instead

---

### Change 2: Align PostgreSQL to Latest

**Files to modify:**
- `Brewfile` - Change `brew "postgresql@15"` to `brew "postgresql"`

**Current:**
```ruby
brew "postgresql@15"
```

**New:**
```ruby
brew "postgresql"      # Latest version
```

**Arch packages-arch.txt:**
```
postgresql  # Already set to latest
```

**Reason:** Dev environment, latest is safe and keeps both platforms aligned

---

### Change 3: Add LM Studio (macOS Only)

**Files to modify:**
- `Brewfile` - Add `cask "lm-studio"`

**Implementation:**
```ruby
# GUI Apps
cask "visual-studio-code"
cask "docker"
cask "alacritty"
cask "lm-studio"      # NEW: AI model runner
```

**Arch Linux:**
- No changes (not available in AUR)
- Document in README as manual installation

**Note:** LM Studio installs to `/Applications/LM Studio.app` on macOS. The CLI binary at `~/.lmstudio/bin` is created by the app on first launch, so the PATH addition in .zshrc is correct.

---

### Change 4: Add gh Extensions Installation Function

**File to modify:**
- `install.sh`

**New function (insert after `install_mise_tools`):**

```bash
# Install gh extensions
install_gh_extensions() {
    if ! command -v gh &>/dev/null; then
        log "WARN" "gh CLI not found, skipping extension installation"
        return 0
    fi
    
    log "INFO" "Installing gh extensions..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would install gh extensions"
        return 0
    fi
    
    # Array of extensions to install
    local extensions=(
        "dlvhdr/gh-dash"
        # Add more extensions here in the future
    )
    
    for ext in "${extensions[@]}"; do
        local ext_name="${ext##*/}"  # Extract name after /
        
        if gh extension list | grep -q "$ext"; then
            log "INFO" "gh extension '$ext_name' already installed"
        else
            log "INFO" "Installing gh extension: $ext_name..."
            gh extension install "$ext"
            log "SUCCESS" "gh extension '$ext_name' installed"
        fi
    done
}
```

**Update main() function:**
```bash
main() {
    # ... existing code ...
    
    # Install mise development tools
    install_mise_tools
    
    # Install gh extensions (NEW)
    install_gh_extensions
    
    echo ""
    log "SUCCESS" "Installation complete!"
    # ... rest of function ...
}
```

---

### Change 5: Update README.md

**Add section about gh extensions:**

```markdown
## GitHub CLI Extensions

The following gh extensions are installed automatically:

- **gh-dash**: Interactive dashboard for GitHub (https://github.com/dlvhdr/gh-dash)

### Adding More Extensions

Edit `install.sh` and add to the `extensions` array in the `install_gh_extensions()` function:

```bash
local extensions=(
    "dlvhdr/gh-dash"
    "owner/repo-name"  # Add new extensions here
)
```

Then run `./install.sh` or manually install:

```bash
gh extension install owner/repo-name
```

### Listing Installed Extensions

```bash
gh extension list
```

### Updating Extensions

```bash
gh extension upgrade --all
# Or via topgrade (automatically included)
topgrade
```
```

**Add LM Studio note:**

```markdown
## Platform-Specific Tools

### macOS Only

- **LM Studio**: AI model runner (installed via Homebrew cask)
  - GUI app: `/Applications/LM Studio.app`
  - CLI available after first launch: `~/.lmstudio/bin/lms`

### Arch Linux Only

- (None currently)

### Manual Installations

**LM Studio (Arch Linux):**
- Download from https://lmstudio.ai
- Extract and run manually
- Not available in AUR
```

---

### Change 6: Update AGENTS.md

**Add section about gh extensions:**

```markdown
## GitHub CLI Extensions

gh extensions are managed via `gh extension install` in the `install_gh_extensions()` function.

### Adding a new gh extension:

1. Edit `install.sh`
2. Add to `extensions` array in `install_gh_extensions()`:
   ```bash
   local extensions=(
       "dlvhdr/gh-dash"
       "new/extension"
   )
   ```
3. Run `./install.sh` or `gh extension install new/extension`

### Why not use package managers?

- gh extensions use `gh extension install` as the official method
- Many extensions are not packaged separately
- Extensions auto-update via `gh extension upgrade`
- Keeps extension management consistent regardless of OS
```

---

## 🧪 Testing Plan

### Before Implementation
- [x] Research gh extension installation
- [x] Verify LM Studio availability in Homebrew
- [x] Check PostgreSQL latest version compatibility
- [x] Design post-install function

### After Implementation
1. **Test on macOS (clean state):**
   ```bash
   # Remove existing gh extensions
   gh extension list
   gh extension remove dlvhdr/gh-dash
   
   # Run install script
   ./install.sh --dry-run  # Preview
   ./install.sh            # Execute
   
   # Verify
   gh extension list       # Should show gh-dash
   gh dash                 # Should open dashboard
   brew list | grep lm-studio  # Should be installed
   psql --version          # Check PostgreSQL version
   ```

2. **Test on Arch Linux:**
   ```bash
   # Run install script
   ./install.sh --dry-run
   ./install.sh
   
   # Verify
   gh extension list       # Should show gh-dash
   pacman -Q postgresql    # Should be latest version
   # LM Studio: verify manual installation note in README
   ```

3. **Test idempotency:**
   ```bash
   ./install.sh  # Run again
   # Should skip already-installed extensions
   # Should not error or duplicate
   ```

4. **Test error handling:**
   ```bash
   # Remove gh temporarily
   brew uninstall gh
   ./install.sh  # Should warn and skip extension install
   ```

---

## 📝 Files to Modify

### Modified Files
1. `Brewfile` - Remove gh-dash, change postgresql@15 → postgresql, add lm-studio
2. `packages-aur.txt` - Remove gh-dash
3. `install.sh` - Add `install_gh_extensions()` function
4. `README.md` - Add gh extensions and LM Studio documentation
5. `AGENTS.md` - Add gh extensions management docs

### No Changes Needed
- `packages-arch.txt` - postgresql already set to latest, gh already present
- `.mise.toml` - No changes needed
- `.zshrc` - LM Studio PATH already configured
- `bootstrap.zsh` - No changes needed

---

## 🎯 Expected Behavior After Implementation

### First-Time Install (macOS)
```
./install.sh
  ↓
Installs Homebrew packages (including gh, postgresql, lm-studio)
  ↓
Installs oh-my-zsh & powerlevel10k
  ↓
Installs mise tools (node, python, go, deno, bun)
  ↓
Installs gh extensions (gh-dash)  ← NEW
  ↓
✅ Done! gh dash works, LM Studio in Applications, PostgreSQL latest
```

### First-Time Install (Arch)
```
./install.sh
  ↓
Installs yay packages (including github-cli, postgresql)
  ↓
Installs oh-my-zsh & powerlevel10k
  ↓
Installs mise tools
  ↓
Installs gh extensions (gh-dash)  ← NEW
  ↓
✅ Done! gh dash works, PostgreSQL latest
⚠️  Manual: Install LM Studio from website (not in AUR)
```

### Re-running Install
```
./install.sh
  ↓
Skips already-installed packages
  ↓
Skips already-installed gh extensions  ← Idempotent
  ↓
✅ Done! No duplicates, no errors
```

### Adding Future Extensions
```bash
# Developer edits install.sh:
local extensions=(
    "dlvhdr/gh-dash"
    "github/gh-copilot"  # NEW
)

# Run installer
./install.sh
  ↓
Skips gh-dash (already installed)
  ↓
Installs gh-copilot (new)
  ↓
✅ Done!
```

---

## 🚀 Implementation Steps (Do Not Execute Yet)

1. **Revert the gh-dash commit:**
   ```bash
   git revert <commit-hash>  # Revert "feat: add GitHub CLI (gh) and gh-dash extension"
   ```

2. **Update Brewfile:**
   - Remove `brew "gh-dash"`
   - Change `brew "postgresql@15"` → `brew "postgresql"`
   - Add `cask "lm-studio"`

3. **Update packages-aur.txt:**
   - Remove `gh-dash`

4. **Update install.sh:**
   - Add `install_gh_extensions()` function
   - Call it from `main()` after `install_mise_tools()`

5. **Update README.md:**
   - Add gh extensions section
   - Add LM Studio platform-specific notes

6. **Update AGENTS.md:**
   - Add gh extensions management documentation

7. **Test thoroughly:**
   - Run `./install.sh --dry-run`
   - Run `./install.sh` on clean environment
   - Verify gh-dash works: `gh dash`
   - Verify idempotency: run `./install.sh` again

8. **Commit:**
   ```bash
   git add -A
   git commit -m "feat: install gh-dash via gh extension + add LM Studio

   - Use 'gh extension install' for gh-dash instead of standalone package
   - Add install_gh_extensions() function to install.sh
   - Align PostgreSQL to latest on both macOS and Arch
   - Add LM Studio cask for macOS (not available on Arch)
   - Update README and AGENTS.md with extension management docs
   - Idempotent: checks if extension already installed"
   ```

---

## ✅ Success Criteria

- [ ] `gh extension list` shows `dlvhdr/gh-dash`
- [ ] `gh dash` opens the dashboard
- [ ] `psql --version` shows latest PostgreSQL (not version 15)
- [ ] LM Studio appears in `/Applications` on macOS
- [ ] Running `./install.sh` twice doesn't duplicate extensions
- [ ] Dry-run mode shows extension installation would occur
- [ ] README documents how to add new extensions
- [ ] Works on both macOS and Arch Linux

---

## 🤔 Future Enhancements (Not in Scope)

1. **Multiple gh extensions:** Easy to add more to the array
2. **Extension version pinning:** gh extensions don't support version pinning natively
3. **Custom mise plugins:** Could create mise plugin for gh if needed (unlikely)
4. **LM Studio on Arch:** Wait for official package or create AUR package
5. **Post-install hooks framework:** Generic system for any tool (overkill for now)

---

## 📊 Comparison: Before vs After

### Before (Current State)
```
Brewfile:
  - gh ✓
  - gh-dash ✓ (standalone package)
  - postgresql@15 ✓

Install flow:
  brew bundle → gh and gh-dash installed as separate packages
```

### After (Planned State)
```
Brewfile:
  - gh ✓
  - postgresql ✓ (latest)
  - lm-studio ✓ (macOS only)

Install flow:
  brew bundle → gh installed
  ↓
  install_gh_extensions() → gh extension install dlvhdr/gh-dash
```

**Key Difference:**
- **Before:** gh-dash is a package
- **After:** gh-dash is a gh extension (official method)

---

## ❓ Open Questions

1. **Should we add more gh extensions by default?**
   - gh-copilot? (GitHub Copilot CLI)
   - gh-markdown-preview? (Preview markdown in terminal)
   - Decision: Start with just gh-dash, easy to add more later

2. **Should topgrade update gh extensions?**
   - Research: topgrade already supports `gh extension upgrade --all`
   - Decision: No action needed, topgrade handles it

3. **What if gh is not installed (edge case)?**
   - Solution: Function checks for gh and warns if missing
   - This should never happen since gh is in package lists

---

## 📚 References

- [gh extension install docs](https://cli.github.com/manual/gh_extension_install)
- [gh-dash repository](https://github.com/dlvhdr/gh-dash)
- [Homebrew LM Studio cask](https://formulae.brew.sh/cask/lm-studio)
- [mise tasks documentation](https://mise.jdx.dev/tasks/)

---

**Status:** Ready for implementation  
**Confidence Level:** High (95%)  
**Risk Level:** Low (changes are additive, easy to revert)  
**Estimated Implementation Time:** 30 minutes  
