#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPENAPI_DIR="$REPO_ROOT/openapi"
GENERATED_DIR="$REPO_ROOT/lib/smplkit/_generated"
CONFIG="$REPO_ROOT/generator/config.yaml"

# Per-service module-name suffix. Resolved with a portable case statement —
# macOS's bash 3.2 does not support associative arrays.
suffix_for_service() {
    case "$1" in
        app)     echo "App" ;;
        config)  echo "Config" ;;
        flags)   echo "Flags" ;;
        logging) echo "Logging" ;;
        *)       printf '%s' "$(printf '%s' "$1" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')" ;;
    esac
}

for spec in "$OPENAPI_DIR"/*.json; do
    [ -f "$spec" ] || continue

    service="$(basename "$spec" .json)"
    suffix="$(suffix_for_service "$service")"
    output_dir="$GENERATED_DIR/$service"

    echo "Generating client for service: $service"

    rm -rf "$output_dir"
    mkdir -p "$output_dir"

    npx --yes @openapitools/openapi-generator-cli generate \
        -i "$spec" \
        -g ruby \
        --library=faraday \
        -c "$CONFIG" \
        -o "$output_dir" \
        --additional-properties="gemName=smplkit_${service}_client,moduleName=SmplkitGeneratedClient::${suffix},gemVersion=0.0.0"

    echo "Generated client at: $output_dir"
done

echo "Done."
