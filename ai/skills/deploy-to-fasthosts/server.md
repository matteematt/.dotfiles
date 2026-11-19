# Fasthosts server details

No secrets in this file. Fill in the TODOs.

- SSH host alias (from `~/.ssh/config`): `fasthosts` (key auth, `~/.ssh/fasthosts`)
- Hostname / IP: set in `~/.ssh/config`, use the alias
- SSH user: set in `~/.ssh/config`, use the alias
- Server type: VPS (2 vCPU, 2 GB RAM, x86_64, 77 GB disk)
- OS: Ubuntu 20.04.6 LTS (kernel 5.4). Runtimes: python3 3.8.10, node v10.19 (old), curl, rsync, git. No uv, no Chromium, no Docker
- sudo available: no passwordless sudo
- Cron daemon: Debian/Ubuntu cron (ignores CRON_TZ); user crontab already has entries
- Server timezone: Etc/UTC
- Apps directory: `~/apps`

## Deployed jobs

- `tala-hoodie-watch` — **stopped 2026-11-19** (cron entry removed after the hoodie was bought; files left in `~/apps/tala-hoodie-watch` for reference). To restart, re-add `*/5 * * * * $HOME/apps/tala-hoodie-watch/run.sh # deploy-to-fasthosts:tala-hoodie-watch` (UTC; `CHECK_INTERVAL_MIN` in watch.py defaults to 5 and must match), and point `PRODUCT_URL`/`VARIANT_ID` in `.env` at the new item. Checks TALA Cocoon Zip Through Hoodie (black, size S) stock via Shopify `/products/<handle>.js` and posts to an ntfy topic set in `.env` when it comes back. Warns after 30 min of failed checks and again when they recover. Uses curl with UA `Mozilla/5.0` (Python urllib and full-Chrome UAs get 429 from the bot filter). Source: `~/Documents/personal/fasthosts/tala-hoodie-watch`.
- Pre-existing, not deployed by this skill: `0 2 * * * ~/istanbul/cryptonissance/job.sh`. Crontab has a `MAILTO` set.
