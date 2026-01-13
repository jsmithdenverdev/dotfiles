#!/usr/bin/env bats

load test_helper

@test "bootstrap script exists and is executable" {
    [ -x "./bootstrap.zsh" ]
}

@test "bootstrap --help displays usage information" {
    run ./bootstrap.zsh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"Options"* ]]
}

@test "bootstrap --version displays version number" {
    run ./bootstrap.zsh --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"version"* ]]
}

@test "bootstrap --dry-run completes without errors" {
    run ./bootstrap.zsh --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"dry-run mode"* ]] || [[ -f "$HOME/.dotfiles_bootstrap.log" ]]
}

@test "bootstrap creates log file" {
    ./bootstrap.zsh --dry-run >/dev/null 2>&1
    [ -f "$HOME/.dotfiles_bootstrap.log" ]
}

@test "bootstrap is idempotent" {
    ./bootstrap.zsh --dry-run >/dev/null 2>&1
    run ./bootstrap.zsh --dry-run
    [ "$status" -eq 0 ]
}

@test "bootstrap rejects invalid arguments" {
    run ./bootstrap.zsh --invalid-flag
    [ "$status" -ne 0 ]
}

@test "bootstrap handles missing config file gracefully" {
    # Temporarily move config if it exists
    if [ -f ".dotfiles-config" ]; then
        mv .dotfiles-config .dotfiles-config.bak
    fi
    
    run ./bootstrap.zsh --dry-run
    [ "$status" -eq 0 ]
    
    # Restore config
    if [ -f ".dotfiles-config.bak" ]; then
        mv .dotfiles-config.bak .dotfiles-config
    fi
}

@test "bootstrap verbose mode produces output" {
    run ./bootstrap.zsh --dry-run --verbose
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ "$output" == *"INFO"* ]] || [[ "$output" == *"Starting dotfiles bootstrap"* ]]
}
