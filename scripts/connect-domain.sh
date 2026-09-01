#!/usr/bin/env bash
# Finish connecting training.stealmyagency.com once the two DNS records exist.
#
# Run this AFTER whoever manages stealmyagency.com DNS has added:
#   TXT    _vercel.stealmyagency.com   vc-domain-verify=training.stealmyagency.com,f5587fd1de1620f6c08b
#   CNAME  training.stealmyagency.com  07800e8bf82db1bd.vercel-dns-016.com.
#
# It checks DNS, waits for Vercel to verify, rewrites every absolute URL in the
# site from the .vercel.app host to the real domain, commits, and deploys.
#
#   ./scripts/connect-domain.sh              # full run
#   ./scripts/connect-domain.sh --check      # just report status, change nothing

set -euo pipefail

DOMAIN="training.stealmyagency.com"
APEX="stealmyagency.com"
OLD_HOST="stealmyagency-a2p.vercel.app"
PROJECT="stealmyagency-a2p"
TEAM_ID="team_26oADIWJ5ZLiTNHr199AOPAs"
TEAM_SLUG="neil-s-team-1825f849"

cd "$(dirname "$0")/.."

TOK=$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/Library/Application Support/com.vercel.cli/auth.json')))['token'])")

say(){ printf '\n\033[1m%s\033[0m\n' "$1"; }
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ printf '  \033[31m✗\033[0m %s\n' "$1"; }

say "1. DNS"
TXT=$(dig +short TXT "_vercel.$APEX" | tr -d '"')
if echo "$TXT" | grep -q "f5587fd1de1620f6c08b"; then ok "TXT _vercel.$APEX found"; else no "TXT _vercel.$APEX missing (got: ${TXT:-nothing})"; fi

CN=$(dig +short CNAME "$DOMAIN")
if [ -n "$CN" ]; then ok "CNAME $DOMAIN -> $CN"; else no "CNAME $DOMAIN missing"; fi

say "2. Vercel verification"
VER=$(curl -s --max-time 30 -H "Authorization: Bearer $TOK" \
  "https://api.vercel.com/v9/projects/$PROJECT/domains/$DOMAIN?teamId=$TEAM_ID" \
  | python3 -c "import sys,json;print(json.load(sys.stdin).get('verified'))")
if [ "$VER" = "True" ]; then ok "Vercel reports verified"; else no "not verified yet (DNS can take up to an hour)"; fi

if [ "${1:-}" = "--check" ]; then
  say "check only, nothing changed"; exit 0
fi

if [ "$VER" != "True" ]; then
  say "Stopping: domain is not verified yet."
  echo "  Re-run once the records have propagated. Nothing was changed."
  exit 1
fi

say "3. Rewriting absolute URLs to https://$DOMAIN"
# Only absolute URLs need touching. Every internal link is already relative.
grep -rl "$OLD_HOST" --include="*.html" --include="*.xml" --include="*.txt" . \
  | while read -r f; do
      sed -i '' "s|$OLD_HOST|$DOMAIN|g" "$f"
      ok "$f"
    done

say "4. Live check on the new host"
for p in "" "privacy-policy.html" "terms-and-conditions.html" "thank-you.html" "og-card.png"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 25 "https://$DOMAIN/$p" || true)
  [ "$code" = "200" ] && ok "$code /$p" || no "$code /$p"
done

say "5. Commit and deploy"
git add -A
git commit -q -m "Point canonical, OG, sitemap and robots at $DOMAIN" || echo "  (nothing to commit)"
git push -q origin main
vercel --prod --yes --scope "$TEAM_SLUG" >/dev/null 2>&1 && ok "deployed"

say "Done. Update the TCR campaign's opt-in URL to https://$DOMAIN"
