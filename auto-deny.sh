#!/usr/bin/env bash
# auto-deny.sh — scan Pi-hole's recently-ALLOWED queries, exact-deny the ones
# that look like ads/trackers. Runs on the Pi-hole host via cron.
#
# Fully automatic. The SKIP list below is the guardrail that stops it blocking
# video CDNs / core service domains. Edit SKIP, never remove it.
#
# Install:
#   sudo cp auto-deny.sh /usr/local/bin/pihole-auto-deny
#   sudo chmod +x /usr/local/bin/pihole-auto-deny
#   sudo crontab -e      # add:  */10 * * * * /usr/local/bin/pihole-auto-deny
#
# Review what it blocked:   cat /var/log/pihole-auto-deny.log
# Undo one:                 pihole --white-regex ... ; or: pihole allow <domain>

set -euo pipefail

DB="/etc/pihole/pihole-FTL.db"
STATE="/var/lib/pihole-auto-deny.last"   # last-processed unix timestamp
SEEN="/var/lib/pihole-auto-deny.seen"    # domains already handled
LOG="/var/log/pihole-auto-deny.log"

# Domains we must NEVER auto-block (breaks streaming / core services).
# Label-anchored where it matters; broad where safety > precision.
SKIP='(googlevideo\.com|ggpht\.com|ytimg\.com|youtube\.com$|youtu\.be$|gstatic\.com|googleusercontent\.com|gvt1\.com|gvt2\.com|nflx|netflix\.com|\.arpa$|\.local$|\.lan$|windowsupdate|\.microsoft\.com$|\.apple\.com$|icloud|akamai|fbcdn|whatsapp|cloudfront\.net$|cloudflare|\.gov$|\.edu$)'

# Looks-like-ad: network names + label-anchored generic tokens.
# (^|\.)token([.-]|$) stops "downloads.x.com" matching "ads".
MATCH='(^|\.)(ads?|adserver|adservice|adsystem|advert[a-z]*|doubleclick|googlesyndication|googleadservices|googletagservices|2mdn|taboola|outbrain|criteo|adnxs|pubmatic|rubiconproject|openx|moatads|scorecardresearch|quantserve|adform|bidswitch|mathtag|adsrvr|teads|innovid|flashtalking|spotx[a-z]*|yieldmo|sharethrough|adroll|adcolony|serving-sys|adsafeprotected|doubleverify|adsymptotic|smartadserver|casalemedia|zedo|fwmrm|tremorhub|springserve|amazon-adsystem|samsungads|lgsmartad|pixel|beacon|telemetry)([.-]|$)'

# pihole v6 uses `pihole deny`, v5 uses `pihole -b`.
deny() { pihole deny "$1" >/dev/null 2>&1 || pihole -b "$1" >/dev/null 2>&1; }

now=$(date +%s)
last=$(cat "$STATE" 2>/dev/null || echo $((now - 600)))
touch "$SEEN"

# status 2=forwarded, 3=cached  → allowed (not already blocked)
sqlite3 "$DB" "SELECT DISTINCT domain FROM queries WHERE timestamp > $last AND status IN (2,3);" \
| while IFS= read -r d; do
    [ -z "$d" ] && continue
    echo "$d" | grep -qiE "$SKIP" && continue
    echo "$d" | grep -qiE "$MATCH" || continue
    grep -qxF "$d" "$SEEN" && continue
    deny "$d"
    echo "$d" >> "$SEEN"
    echo "$(date '+%F %T') DENY $d" >> "$LOG"
done

echo "$now" > "$STATE"
