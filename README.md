# pihole-blocklists

Personal Pi-hole blocklists. Each file is a plain domain list (one domain per
line, `#` comments allowed) — add the **raw** URL of each file under
**Pi-hole → Adlists**, then run **Tools → Update Gravity**.

| File | Raw URL to paste into Pi-hole |
|------|-------------------------------|
| YouTube ads | `https://raw.githubusercontent.com/muchkurisrivardhan/pihole-blocklists/main/youtube-ads.txt` |
| Netflix ads | `https://raw.githubusercontent.com/muchkurisrivardhan/pihole-blocklists/main/netflix-ads.txt` |
| Aggressive ads/trackers | `https://raw.githubusercontent.com/muchkurisrivardhan/pihole-blocklists/main/aggressive-ads.txt` |

## Regex

`regex.txt` is **not** an adlist. Pi-hole regex rules go under
**Group Management → Domains → Add a new regex filter** (paste one per line).

## Reality check

- **YouTube**: Pi-hole can't block in-stream video ads — they come from the
  same `*.googlevideo.com` servers as the videos. These lists only kill
  YouTube's ad/tracking + display-ad endpoints. For real blocking use uBlock
  Origin / SponsorBlock in the browser.
- **Netflix**: the ad-supported tier's ad/measurement endpoints are blocked;
  this may trigger ad-tier verification. Whitelist if playback stalls.

If something you use breaks, whitelist the specific domain in Pi-hole rather
than removing a whole list.
