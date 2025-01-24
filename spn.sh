#!/usr/bin/env bash

# API docs at
# https://docs.google.com/document/d/1Nsv52MvSjbLb2PCpHlat0gkzw0EvtSgpKHu4mk0MnrA/edit?tab=t.0

set -euo pipefail

function err() {
    echo "$@" >&2
    exit 1
}

function save() {
    local url="$1"
    local capture_outlinks="${2:-1}"
    local if_not_archived_within="${3:-7d}"

    if [[ $capture_outlinks == "true" ]]; then
        capture_outlinks=1 # Convert from YAML
    fi

    local query=(
        "capture_outlinks=${capture_outlinks}"
        "if_not_archived_within=${if_not_archived_within}"
        "delay_wb_availability=1"
    )
    local query_str=""
    for q in "${query[@]}"; do
        query_str="${query_str}&${q}"
    done

    curl -fsSL \
        -X POST \
        -H "Accept: application/json" \
        -H "Authorization: LOW ${S3_ACCESS_KEY}:${S3_SECRET_KEY}" \
        -d "url=${url}${query_str}" \
        "https://web.archive.org/save" ||
        err "Failed to save ${url}${query_str}"
}

function status() {
    local job_id="$1"

    curl -fsSL \
        -X GET \
        -H "Accept: application/json" \
        -H "Authorization: LOW ${S3_ACCESS_KEY}:${S3_SECRET_KEY}" \
        "https://web.archive.org/save/status/${job_id}" ||
        err "Failed to get status for job_id: ${job_id}"
}

function main() {
    local config_file="${1:-}"
    if [[ -z "$config_file" ]]; then
        err "Usage: $0 <config_file>"
    fi
    if [[ ! -f "$config_file" ]]; then
        err "Config file not found: $config_file"
    fi
    if [[ -z "${S3_ACCESS_KEY:-}" ]]; then
        err "S3_ACCESS_KEY is not set"
    fi
    if [[ -z "${S3_SECRET_KEY:-}" ]]; then
        err "S3_SECRET_KEY is not set"
    fi

    config_len=$(yq '. | length' "$config_file")

    for ((i = 0; i < config_len; i++)); do
        url=$(
            yq ".[$i].url" "$config_file"
        )
        echo "Saving $url" >&2
        capture_outlinks=$(
            yq ".[$i].capture_outlinks" "$config_file" || true
        )
        if_not_archived_within=$(
            yq ".[$i].if_not_archived_within" "$config_file" || true
        )

        resp=$(save "$url" "$capture_outlinks" "$if_not_archived_within")
        job_id=$(echo "$resp" | yq '.job_id')
        message=$(echo "$resp" | yq '.message' || true)
        if [[ -n "$message" ]]; then
            echo "  message: $message" >&2
        fi

        echo "  job_id:  $job_id" >&2
        resp=$(status "$job_id")
        status_message=$(echo "$resp" | yq '.status')
        echo "  status:  ${status_message}" >&2
    done
}

main "$@"
