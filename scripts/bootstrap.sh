#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

create_app() {
  local app_dir="$1"
  local project_name="$2"
  local org_id="$3"
  local target_dir="$ROOT_DIR/apps/$app_dir"

  if [[ ! -d "$target_dir" ]]; then
    echo "Creating $app_dir..."
    flutter create --org "$org_id" --project-name "$project_name" "$target_dir"
  else
    echo "$app_dir already exists, skipping flutter create."
  fi

  echo "Wiring templates for $app_dir..."
  rm -rf "$target_dir/lib"
  mkdir -p "$target_dir/lib"
  cp -R "$ROOT_DIR/templates/$app_dir/lib/." "$target_dir/lib/"

  python3 "$ROOT_DIR/scripts/patch_pubspec.py" "$target_dir/pubspec.yaml"

  if [[ "$app_dir" == "courier_app" ]]; then
    python3 "$ROOT_DIR/scripts/patch_android_manifest.py" "$target_dir/android/app/src/main/AndroidManifest.xml"
  fi
}

create_app customer_app customer com.fooddelivery
create_app courier_app courier com.fooddelivery
create_app restaurant_admin_app restaurant com.fooddelivery

echo "Done. Run 'flutter pub get' inside each app if needed."
