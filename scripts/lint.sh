#!/bin/bash
set -e

echo "🔍 Running ShellCheck..."
shellcheck bootstrap.zsh .zshrc

echo ""
echo "🔍 Running Vint..."
vint .vimrc .config/vim/*.vim .config/nvim/init.vim || true

echo ""
echo "🔍 Running taplo..."
taplo fmt --check .config/**/*.toml

echo ""
echo "✅ All linters passed!"
