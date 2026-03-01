#!/bin/bash

# Check if ruby-lsp is installed and available in PATH

if command -v ruby-lsp &> /dev/null; then
    exit 0
fi

# Check if gem is available
if ! command -v gem &> /dev/null; then
    echo "[ruby-lsp] Ruby is not installed. Please install Ruby first."
    echo "           Then run: gem install ruby-lsp"
    exit 0
fi

echo "[ruby-lsp] ruby-lsp not found. Please install it:"
echo "           gem install ruby-lsp"

exit 0
