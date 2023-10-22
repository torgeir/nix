#!/usr/bin/env bash
# prevents secrets.yaml from being added to .git
# run this script before running nixos-rebuild
for f in secrets.yaml; do
    git add -f --intent-to-add $f \
        && git update-index --assume-unchanged $f;
done
