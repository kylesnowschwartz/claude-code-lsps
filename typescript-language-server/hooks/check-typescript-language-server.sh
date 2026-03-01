#!/bin/bash

# Check if typescript-language-server is installed and available in PATH

if command -v typescript-language-server &> /dev/null; then
    exit 0
fi

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "[typescript-language-server] npm is not installed. Please install Node.js first."
    echo "                             Then run: npm i -g typescript-language-server typescript"
    exit 0
fi

echo "[typescript-language-server] Not found. Please install it:"
echo "                             npm i -g typescript-language-server typescript"

exit 0
