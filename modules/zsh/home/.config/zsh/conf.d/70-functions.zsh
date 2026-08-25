# Shell functions.

# Claude Code, one config dir per account.
hpclaude() {   # work
  CLAUDE_CONFIG_DIR="$HOME/.claude-work" command claude "$@"
}
apclaude() {   # personal
  CLAUDE_CONFIG_DIR="$HOME/.claude-personal" command claude "$@"
}
# Bare `claude` is disabled so the wrong account is never used by accident.
claude() {
  print -u2 "Use 'hpclaude' (work) or 'apclaude' (personal) instead."
  return 1
}
