#!/usr/bin/env bash
# Read-only survey of the server. Run with: ssh fasthosts 'bash -s' < scripts/check-server.sh
echo "== whoami / host";   whoami; hostname
echo "== OS";              (. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME") || uname -a
echo "== kernel";          uname -r
echo "== timezone";        (timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || date +%Z)
echo "== date now";        date
echo "== runtimes"
for c in node npm python3 pip3 uv bash rsync git curl; do
  printf '%-8s ' "$c"; if command -v "$c" >/dev/null 2>&1; then "$c" --version 2>&1 | head -n1; else echo "not found"; fi
done
echo "== cron"
if command -v crontab >/dev/null 2>&1; then
  crontab -l >/dev/null 2>&1 && echo "crontab: usable (has entries)" || echo "crontab: usable (empty or none yet)"
  (systemctl is-active cron 2>/dev/null || systemctl is-active crond 2>/dev/null) | sed 's/^/daemon: /'
  (rpm -q cronie >/dev/null 2>&1 && echo "cronie: yes") || echo "cronie: no/unknown"
else
  echo "crontab: not found"
fi
echo "== sudo";            sudo -n true 2>/dev/null && echo "passwordless sudo: yes" || echo "passwordless sudo: no"
echo "== disk (home)";     df -h "$HOME" | tail -n1
echo "== ~/apps";          ls -1 "$HOME/apps" 2>/dev/null || echo "(not created yet)"
