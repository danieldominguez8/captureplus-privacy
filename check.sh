#!/usr/bin/env bash
# Checks the policy page before and after publishing.
#   ./check.sh            # the local index.html
#   ./check.sh --live     # the published page
set -euo pipefail
if [[ "${1:-}" == --live ]]; then
  PAGE=$(curl -fsS https://danieldominguez8.github.io/captureplus-privacy/)
else
  PAGE=$(cat "$(dirname "$0")/index.html")
fi
fail() { echo "FAIL: $1" >&2; exit 1; }
grep -q "<h1>Capture Plus</h1>" <<<"$PAGE" || fail "heading not the app name"
grep -q "Capture Plus: Screen Recorder" <<<"$PAGE" || fail "store name not mentioned"
grep -q "effective October 26, 2026" <<<"$PAGE" || fail "effective date missing"
for id in summary collect use retention share contact state-rights europe support; do
  grep -q "id=\"$id\"" <<<"$PAGE" || fail "no #$id section"
done
grep -q "General Legal" <<<"$PAGE" || fail "template credit missing (General Legal asks to keep it)"
grep -q "Google LLC (Gmail)" <<<"$PAGE" || fail "email provider not disclosed"
grep -q "GitHub Pages" <<<"$PAGE" || fail "page host not disclosed"
grep -qi "two-factor" <<<"$PAGE" && fail "claims two-factor authentication (not confirmed)"
grep -q "mailto:dominguezdanieldev@gmail.com" <<<"$PAGE" || fail "contact address missing"
# The app has no network code (no URLSession/NWConnection, no network entitlement): the page says so.
grep -q "never connects to the internet" <<<"$PAGE" || fail "no-network statement missing"
grep -q "We never receive them" <<<"$PAGE" || fail "recordings-stay-local statement missing"
grep -q "Screen Recording" <<<"$PAGE" || fail "Screen Recording permission not described"
grep -q "Microphone" <<<"$PAGE" || fail "microphone permission not described"
grep -q "Notifications" <<<"$PAGE" || fail "notifications permission not described"
# Nothing loaded from another origin (scripts, styles, fonts, images, frames); outbound links only to
# GitHub's privacy statement and the European data protection authorities.
if grep -Eoi '<(script|link|img|iframe)[^>]+(src|href)="https?://' <<<"$PAGE"; then fail "third-party resource"; fi
bad=$(grep -Eo '(src|href)="https?://[^"]+"' <<<"$PAGE" | grep -Ev '"https://(docs\.github\.com|www\.edpb\.europa\.eu|ico\.org\.uk)' || true)
[[ -z "$bad" ]] || fail "unexpected outbound link: $bad"
if [[ "${1:-}" != --live ]]; then
  (cd "$(dirname "$0")" && npx --yes html-validate@9 index.html >/dev/null) || fail "html-validate"
fi
echo "policy checks: all passed"
