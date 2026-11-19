---
name: deploy-to-fasthosts
description: Install, update, schedule or remove a script on Matt's Fasthosts Linux server over SSH, so it runs on the server instead of the laptop. Use when moving a laptop-scheduled job to the server, deploying an update to one, or checking or fixing a scheduled job there.
---

# Deploy a script to the Fasthosts server

Server details live in [server.md](server.md). Read it first, and keep it up to date. If a field you need is still `TODO`, stop and ask Matt rather than guessing.

## Ground rules

- Connect only through the SSH host alias in server.md, which uses Matt's existing `~/.ssh/config` and keys. Never ask for, type or store a password.
- Secrets never go in this skill, the project repo, the crontab or the chat. They live in `~/apps/<name>/.env` on the server, `chmod 600`.
- Read-only checks can just run. Before the first command that changes the server, show Matt the plan and get a go-ahead.
- No `sudo` unless server.md says it is available and Matt OKs that specific command.
- If SSH fails, stop and report the error. Don't try other ways in.

## 1. Check the connection

```bash
ssh fasthosts 'echo connected && hostname'
```

## 2. Survey the server

Run the bundled check script remotely (it only reads, never changes anything):

```bash
ssh fasthosts 'bash -s' < scripts/check-server.sh
```

From the output, confirm: the runtime the script needs (and its version), that `crontab` works for this user, `rsync` availability, and the server timezone. Update the matching `TODO`s in server.md.

## 3. Understand the script

From the local project, work out:

- entry point and runtime/version (Node, Python, shell…)
- dependencies (`package.json` / lockfile, `requirements.txt`, etc.)
- env vars and config files it reads, and files it writes
- how and when it was scheduled on the laptop (launchd plist, cron, Claude scheduled task) — the times are what we'll recreate
- anything macOS-only: `osascript`, `open`, `pbcopy`, Keychain, `say`, notifications, `/Users/...` paths, Homebrew paths. These won't work on Linux — list them for Matt with a proposed replacement before deploying.

## 4. Upload

Layout on the server:

```
~/apps/<name>/
  ...script files...
  .env          # secrets, chmod 600, never synced
  run.sh        # wrapper cron calls
  logs/<name>.log
```

```bash
ssh fasthosts 'mkdir -p ~/apps/<name>/logs'
rsync -av --delete \
  --exclude .git --exclude node_modules --exclude .venv --exclude .env --exclude logs \
  ./ fasthosts:~/apps/<name>/
```

If `rsync` is missing on the server, fall back to `scp -r` (without `--delete` semantics — mention that to Matt).

Install dependencies on the server:

- Node: `cd ~/apps/<name> && npm ci --omit=dev`
- Python: `cd ~/apps/<name> && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt`

## 5. Secrets

Create `.env` with the variable names only and empty values, then lock it down:

```bash
ssh fasthosts 'cd ~/apps/<name> && [ -f .env ] || printf "KEY_ONE=\nKEY_TWO=\n" > .env; chmod 600 .env'
```

Ask Matt to fill in the values himself (`ssh fasthosts` then `nano ~/apps/<name>/.env`). Don't handle the values in chat.

## 6. Wrapper script

Write `~/apps/<name>/run.sh` so cron's bare environment doesn't matter:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
set -a; [ -f .env ] && . ./.env; set +a
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
echo "=== $(date -Is) start" >> logs/<name>.log
<command to run the script> >> logs/<name>.log 2>&1
echo "=== $(date -Is) exit $?" >> logs/<name>.log
```

`chmod +x run.sh`. Use absolute paths to runtimes if `command -v node`/`python3` differs between login and cron shells.

## 7. Test run

```bash
ssh fasthosts '~/apps/<name>/run.sh; echo "exit=$?"; tail -n 30 ~/apps/<name>/logs/<name>.log'
```

Don't schedule anything until this succeeds.

## 8. Schedule with cron

Cron uses the **server's** timezone. Matt is in Europe/London.

- If the server is already on Europe/London, use the laptop times as-is.
- If it's on UTC, either write times in UTC (they'll drift an hour during BST) or, if `cronie` is the cron daemon, put `CRON_TZ=Europe/London` above the entry. Debian/Ubuntu's default cron ignores `CRON_TZ`. Ask Matt which he prefers.

Add the entry with a marker comment so it can be found and replaced without duplicating:

```bash
ssh fasthosts '( crontab -l 2>/dev/null | grep -v "# deploy-to-fasthosts:<name>$" ; \
  echo "<m h dom mon dow> $HOME/apps/<name>/run.sh # deploy-to-fasthosts:<name>" ) | crontab -'
ssh fasthosts 'crontab -l'
```

## 9. Hand off

- Record the job in the "Deployed jobs" list in server.md (name, schedule, what it does).
- Tell Matt how to check it: `ssh fasthosts 'tail -f ~/apps/<name>/logs/<name>.log'`.
- Remind him to **turn off the laptop schedule** so it doesn't run twice.
- Suggest checking the log after the first scheduled run.

## Updating an existing job

Re-run step 4 (rsync + deps if the lockfile changed), then step 7. Only touch the crontab if the schedule changed.

## Removing a job

```bash
ssh fasthosts 'crontab -l | grep -v "# deploy-to-fasthosts:<name>$" | crontab -'
```

Leave `~/apps/<name>` in place unless Matt asks for it to be deleted. Update server.md.
