#!/bin/sh
script_user=`whoami`
script_dir=$(realpath "$(dirname "$0")")

echo "USER:" ${script_user}
echo "DIR:" ${script_dir}
echo

# Install GitHub CLI extension for actions lock
# To perform an update, run the command:
#   `gh actions-lock --relock --no-narrow`.
gh extension install github/gh-actions-lock
