#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPENAPI_DIR="$REPO_ROOT/openapi"
GENERATED_DIR="$REPO_ROOT/lib/smplkit/_generated"
CONFIG="$REPO_ROOT/generator/config.yaml"

# Per-service module-name suffix. Adjust if the platform service set changes.
declare -A MODULE_SUFFIX=(
    [app]="App"
    [config]="Config"
    [flags]="Flags"
    [logging]="Logging"
)

for spec in "$OPENAPI_DIR"/*.json; do
    [ -f "$spec" ] || continue

    service="$(basename "$spec" .json)"
    suffix="${MODULE_SUFFIX[$service]:-${service^}}"
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
