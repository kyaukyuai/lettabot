---
name: linear-cli
description: Create Linear issues from explicit task or ticket requests in Slack or chat. Use when the user clearly wants something tracked in Linear, and respond with the created issue identifier and URL.
---

# linear-cli

Use this skill when the user explicitly wants a task, issue, ticket, or TODO created in Linear.

Typical triggers include:
- "create a Linear issue"
- "make this a task"
- "open a ticket"
- "track this"
- Japanese requests like "タスクにして", "issue 作って", "チケット切って", "TODO にしておいて"

Do not create an issue for normal conversation. Only do it when tasking intent is explicit.
When the user explicitly asks for Linear, an issue, a ticket, or a tracked task, do not fall back to `manage_todo` as a substitute. Either create the Linear issue or clearly explain why the Linear action could not be completed.

## Requirements

- `linear` must be on `PATH`
- `LINEAR_API_KEY` must be set
- `Bash` must remain enabled for the agent

Never ask the user to paste a Linear API key into Slack or chat. Linear credentials belong in server-side environment variables such as Railway service variables.

Optional environment:
- `LINEAR_WORKSPACE`: if set, add `-w "$LINEAR_WORKSPACE"`
- `LINEAR_TEAM_ID`: if set, add `--team "$LINEAR_TEAM_ID"`

## Workflow

1. Before asking the user anything about credentials, verify server-side access with Bash:
   - `test -n "$LINEAR_API_KEY"`
   - if needed, run `linear issue list --no-interactive --limit 1` or another lightweight `linear` command to confirm auth
2. If the key is missing or auth fails, tell the user the bot environment is misconfigured and that `LINEAR_API_KEY` must be fixed in Railway variables. Do not ask the user to share the key in chat.
3. Extract a concise issue title.
4. Build a short markdown description from the Slack context: request, relevant details, constraints, and links or message excerpts if useful.
5. If title or scope is too ambiguous, ask one concise follow-up before creating anything.
6. Create the issue with `linear issue create --no-interactive`.
7. Reply with the created issue identifier and URL.

## Command pattern

Prefer `--description-file` over inline `-d` for multiline markdown.

```bash
desc_file=$(mktemp)
cat >"$desc_file" <<'EOF'
# Summary
- ...

# Context
- ...
EOF

linear issue create --no-interactive \
  --title "Replace this title" \
  --description-file "$desc_file"

rm -f "$desc_file"
```

If `LINEAR_WORKSPACE` is set, add `-w "$LINEAR_WORKSPACE"`.

If `LINEAR_TEAM_ID` is set, add `--team "$LINEAR_TEAM_ID"`.

## After creation

- Capture the created issue identifier from the command output.
- If the create output does not include a URL, run `linear issue url <identifier>`.
- Reply briefly with the issue identifier and URL.

## Guardrails

- Keep the created issue focused on one actionable task.
- Do not guess missing critical scope when the Slack request is too vague.
- Do not create duplicate issues if the user is only asking for status or discussion.
- Treat missing Linear credentials as a deployment/configuration problem, not as a request for the user to share secrets in chat.
- Do not create a local todo with `manage_todo` when the user asked for a Linear issue/task/ticket. Only use `manage_todo` if the user explicitly asked for an internal reminder instead of Linear.
