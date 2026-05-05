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

    # Post-process: the openapi-generator template writes
    # +Logger.new(STDOUT)+ inside the per-service module. For the
    # +logging+ service that resolves lexically to
    # +SmplkitGeneratedClient::Logging::Logger+ (the generated model
    # class) instead of stdlib +::Logger+, blowing up at construction.
    # Force a top-level reference and replace the deprecated +STDOUT+
    # constant with +$stdout+ at the same time.
    config_file="$output_dir/lib/smplkit_${service}_client/configuration.rb"
    if [ -f "$config_file" ]; then
        # macOS sed needs an extension for in-place; use a portable form.
        sed -i.bak \
            -e 's|: Logger\.new(STDOUT)|: ::Logger.new($stdout)|' \
            "$config_file"
        rm -f "$config_file.bak"
    fi

    # The generator emits +:'AnyOf'+ as the openapi_types entry for spec
    # fields whose schema is +anyOf+ — but it never declares an +AnyOf+
    # constant, so deserialization fails with +uninitialized constant+
    # when a response includes such a field. Replace with the generator's
    # own untyped sentinel +:'Object'+, which routes through the dynamic
    # value path.
    find "$output_dir/lib" -name "*.rb" -type f -print0 | while IFS= read -r -d '' model_file; do
        if grep -q ":'AnyOf'" "$model_file"; then
            sed -i.bak "s|:'AnyOf'|:'Object'|g" "$model_file"
            rm -f "$model_file.bak"
        fi
    done

    echo "Generated client at: $output_dir"
done

echo "Done."
