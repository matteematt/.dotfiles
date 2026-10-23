#!/bin/sh
# Backwards-compatible entry point for existing Claude Code settings.
exec "$(dirname "$0")/agent_notify.sh" claude "$@"
