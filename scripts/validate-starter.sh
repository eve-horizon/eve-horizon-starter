#!/usr/bin/env bash
# Static checks that keep the starter aligned with its public manifest.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/.eve/manifest.yaml"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

command -v git >/dev/null || fail "git is required"
command -v ruby >/dev/null || fail "Ruby is required for YAML validation"

ruby -ryaml -e '
  manifest = YAML.load_file(ARGV.fetch(0))
  abort "unexpected manifest schema" unless manifest["schema"] == "eve/compose/v2"
  abort "sandbox environment missing" unless manifest.dig("environments", "sandbox")
  abort "deploy-sandbox pipeline missing" unless manifest.dig("pipelines", "deploy-sandbox")
  abort "sandbox pipeline mismatch" unless manifest.dig("environments", "sandbox", "pipeline") == "deploy-sandbox"
  abort "migrate service missing" unless manifest.dig("services", "migrate")
' "$MANIFEST"

# Compose and the manifest run the same migrate image: Eve's, from GHCR, at a
# pinned platform version.
migrate_image() {
  ruby -ryaml -e 'puts YAML.load_file(ARGV.fetch(0)).dig("services", "migrate", "image")' "$1"
}
manifest_image="$(migrate_image "$MANIFEST")"
compose_image="$(migrate_image "$REPO_ROOT/docker-compose.yml")"
[[ $manifest_image =~ ^ghcr\.io/eve-horizon/eve-horizon/migrate:[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || fail "manifest migrate image must be ghcr.io/eve-horizon/eve-horizon/migrate:<version>: $manifest_image"
[[ $compose_image == "$manifest_image" ]] \
  || fail "Docker Compose and the manifest use different migrate images"

if git -C "$REPO_ROOT" grep -n -I -E \
  'public\.ecr\.aws|ghcr\.io/eve-horizon/eve-migrate|github\.com/Incept5|ci-cd-main|eve env deploy staging|eve project sync --validate-secrets|^GITHUB_TOKEN=' \
  -- . ':(exclude)scripts/validate-starter.sh'; then
  fail "starter contains a private, nonexistent, or manifest-inconsistent instruction"
fi

if grep -Eq '^[A-Z][A-Z0-9_]*=.+$' "$REPO_ROOT/secrets.env.example"; then
  fail "secrets.env.example must contain empty placeholders only"
fi

if git -C "$REPO_ROOT" grep -n -I -E \
  'AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|BEGIN [A-Z ]*PRIVATE KEY' \
  -- . ':(exclude)scripts/validate-starter.sh'; then
  fail "tracked files contain a credential-shaped value"
fi

echo "Starter validation passed."
