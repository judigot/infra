#!/bin/sh
set -eu

usage() {
  echo "Usage: $0 workspace/<scope>/<app> [--refresh]" >&2
  exit 2
}

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage

refresh=false
if [ "$#" -eq 2 ]; then
  [ "$2" = "--refresh" ] || usage
  refresh=true
fi

case "$1" in
  workspace/*) ;;
  *) usage ;;
esac

case "/$1/" in
  */../*|*/./*|*//*)
    echo "Invalid workspace path: $1" >&2
    exit 2
    ;;
esac

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
workspace_rel=${1%/}
workspace_dir="$repo_root/$workspace_rel"

[ -d "$workspace_dir" ] || {
  echo "Workspace not found: $workspace_rel" >&2
  exit 1
}

[ -f "$workspace_dir/blueprint" ] || {
  echo "Missing blueprint reference: $workspace_rel/blueprint" >&2
  exit 1
}

blueprint_ref=$(sed -n '1p' "$workspace_dir/blueprint")
case "$blueprint_ref" in
  ""|/*|*..*|*//*|*\ *)
    echo "Invalid blueprint reference: $blueprint_ref" >&2
    exit 1
    ;;
esac

blueprint_dir="$repo_root/blueprints/$blueprint_ref"
[ -d "$blueprint_dir" ] || {
  echo "Blueprint not found: blueprints/$blueprint_ref" >&2
  exit 1
}

output_rel=${workspace_rel#workspace/}
output_dir="$repo_root/dist/$output_rel/infra"

# Regeneration must never erase state, operator tfvars, or local edits. Build a
# fresh artifact and retain the previous directory beside it for inspection.
if [ -e "$output_dir" ] && [ "$refresh" = false ]; then
  operational_files=$(find "$output_dir" \( -name '*.tfstate*' -o -name '*.tfvars' -o -name '*.tfvars.json' -o -name '.terraform' -o -name '.terraform.lock.hcl' -o -name '*.tfplan' \) -print -quit)
  if [ -n "$operational_files" ]; then
    echo "Refusing to replace an initialized export or operator data. Move the deployment to a durable directory first." >&2
    exit 1
  fi
  previous_dir=$(mktemp -d "$repo_root/dist/$output_rel/infra.previous.XXXXXX")
  mv -- "$output_dir" "$previous_dir/infra"
  printf 'Preserved previous export at %s/infra\n' "$previous_dir"
fi
mkdir -p "$output_dir/environments"

# Materialize the selected blueprint as the exported Terraform root. Blueprint
# module paths are rewritten because root files move from blueprints/*/* to infra/.
for file in "$blueprint_dir"/*; do
  [ -f "$file" ] || continue
  name=$(basename -- "$file")
  case "$name" in
    *.tf)
      sed 's#../../../modules/#./modules/#g' "$file" > "$output_dir/$name"
      ;;
    README.md)
      cp "$file" "$output_dir/BLUEPRINT.md"
      ;;
  esac
done

# Export only committed-safe examples. Real tfvars can contain secrets and must
# never be copied into an artifact intended for another repository.
if [ -d "$workspace_dir/environments" ]; then
  for environment_dir in "$workspace_dir"/environments/*; do
    [ -d "$environment_dir" ] || continue
    environment=$(basename -- "$environment_dir")
    mkdir -p "$output_dir/environments/$environment"
    for file in "$environment_dir"/*.tfvars.example; do
      [ -f "$file" ] || continue
      cp "$file" "$output_dir/environments/$environment/"
    done
    for file in "$environment_dir"/*.tfbackend.example; do
      [ -f "$file" ] || continue
      cp "$file" "$output_dir/environments/$environment/"
    done
  done
fi

# Vendor only modules referenced directly by the selected blueprint.
module_refs=$(grep -hE '^[[:space:]]*source[[:space:]]*=[[:space:]]*"../../../modules/[^\"]+"' "$blueprint_dir"/*.tf 2>/dev/null \
  | sed -E 's#.*"../../../modules/([^\"]+)".*#\1#' \
  | sort -u || true)

if [ -n "$module_refs" ]; then
  printf '%s\n' "$module_refs" | while IFS= read -r module_ref; do
    [ -n "$module_ref" ] || continue
    source_dir="$repo_root/modules/$module_ref"
    [ -d "$source_dir" ] || {
      echo "Referenced module not found: modules/$module_ref" >&2
      exit 1
    }
    target_dir="$output_dir/modules/$module_ref"
    mkdir -p "$(dirname -- "$target_dir")"
    cp -R "$source_dir"/. "$target_dir"/
  done
fi

cat > "$output_dir/README.md" <<EOF
# Infrastructure

Standalone Terraform infrastructure exported from \`$workspace_rel\`.

This directory is a generated artifact. Copy it into the application repository
before initialization. Never apply directly from dist. Re-export preserves the
previous artifact in an adjacent infra.previous.* directory.

Configure a separate remote backend key or HCP Terraform workspace for each
environment before applying. Selecting a different var-file does not isolate state.

Selected blueprint: \`blueprints/$blueprint_ref\`

- Root \`*.tf\` files are the materialized blueprint.
- \`modules/\` contains only referenced reusable modules.
- \`environments/\` contains committed-safe environment examples. Keep real tfvars out of Git or manage values in HCP Terraform.

Example:

\`\`\`sh
cp infra/environments/development/terraform.tfvars.example infra/environments/development/terraform.tfvars
terraform -chdir=infra init
terraform -chdir=infra plan -var-file=environments/development/terraform.tfvars
\`\`\`
EOF

printf 'Exported %s -> %s\n' "$workspace_rel" "dist/$output_rel/infra"
