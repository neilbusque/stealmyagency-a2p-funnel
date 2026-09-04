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

# Pick a token that can actually see this project. The shared Vercel CLI session
# (~/Library/Application Support/com.vercel.cli/auth.json) belongs to whichever
# account logged in last, so it is the LAST resort, not the first: when it holds a
# different account every API call here 403s.
resolve_token(){
  local cands=()
  [ -n "${VERCEL_TOKEN:-}" ] && cands+=("$VERCEL_TOKEN")
  local f
  for f in "$HOME"/.config/neilos-secrets/vercel-*.token; do
    [ -f "$f" ] && cands+=("$(tr -d '\n' < "$f")")
  done
  local cli="$HOME/Library/Application Support/com.vercel.cli/auth.json"
  [ -f "$cli" ] && cands+=("$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['token'])" "$cli" 2>/dev/null || true)")
  local t
  for t in "${cands[@]}"; do
    [ -z "$t" ] && continue
    if curl -s --max-time 20 -H "Authorization: Bearer $t" \
         "https://api.vercel.com/v9/projects/$PROJECT?teamId=$TEAM_ID" \
         | grep -q '"name"'; then
      printf '%s' "$t"; return 0
    fi
  done
  return 1
}

if ! TOK=$(resolve_token); then
  echo "No Vercel token on this machine can see $PROJECT in $TEAM_SLUG." >&2
  echo "That team is busqueneil@gmail.com. Export VERCEL_TOKEN for that account and re-run." >&2
  exit 1
fi
WHO=$(curl -s --max-time 20 -H "Authorization: Bearer $TOK" https://api.vercel.com/v2/user \
      | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('user',d).get('email','?'))" 2>/dev/null || echo '?')

say(){ printf '\n\033[1m%s\033[0m\n' "$1"; }
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ printf '  \033[31m✗\033[0m %s\n' "$1"; }

say "1. DNS"
TXT=$(dig +short TXT "_vercel.$APEX" | tr -d '"')
if echo "$TXT" | grep -q "f5587fd1de1620f6c08b"; then ok "TXT _vercel.$APEX found"; else no "TXT _vercel.$APEX missing (got: ${TXT:-nothing})"; fi

CN=$(dig +short CNAME "$DOMAIN")
if [ -n "$CN" ]; then ok "CNAME $DOMAIN -> $CN"; else no "CNAME $DOMAIN missing"; fi

say "2. Vercel verification (as $WHO)"
# Reads 'verified' but surfaces an API error as an error. Reporting a 403 as
# "not verified yet" sends you looking at DNS that was fine all along.
read_verified(){
  curl -s --max-time 30 -H "Authorization: Bearer $TOK" \
    "https://api.vercel.com/v9/projects/$PROJECT/domains/$DOMAIN?teamId=$TEAM_ID" \
  | python3 -c "
import sys,json
d=json.load(sys.stdin)
if 'error' in d:
    print('API-ERROR: '+d['error'].get('code','?')+' '+d['error'].get('message',''))
else:
    print('true' if d.get('verified') else 'false')"
}

VER=$(read_verified)
case "$VER" in
  API-ERROR*) no "$VER"; VER=false ;;
  true)  ok "Vercel reports verified" ;;
  false)
    # The TXT record can be live while Vercel has not re-checked it. Ask it to.
    if echo "$TXT" | grep -q "f5587fd1de1620f6c08b"; then
      no "not verified yet - triggering a verify now"
      curl -s -X POST --max-time 30 -H "Authorization: Bearer $TOK" \
        "https://api.vercel.com/v9/projects/$PROJECT/domains/$DOMAIN/verify?teamId=$TEAM_ID" >/dev/null || true
      VER=$(read_verified)
      [ "$VER" = "true" ] && ok "verified after trigger" || no "still not verified (DNS can take up to an hour)"
    else
      no "not verified yet - the TXT record is not visible in DNS"
    fi ;;
esac

if [ "${1:-}" = "--check" ]; then
  say "check only, nothing changed"; exit 0
fi

if [ "$VER" != "true" ]; then
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
if vercel --prod --yes --token "$TOK" --scope "$TEAM_SLUG" >/tmp/a2p-deploy.log 2>&1; then
  ok "deployed"
else
  no "deploy FAILED - see /tmp/a2p-deploy.log"; tail -20 /tmp/a2p-deploy.log; exit 1
fi

say "Done. Update the TCR campaign's opt-in URL to https://$DOMAIN"
