#!/usr/bin/env bash

env_file="${1:-.env}"

if [[ -f "$env_file" ]]; then
    echo "enum Environment {"
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
        if [[ -n "$key" ]]; then
            if [[ -z "$value" ]]; then
                value=$(eval "echo \$$key")
            fi
            echo "  static let $key = \"$value\""
        fi
    done < "$env_file"
    echo "}"
fi