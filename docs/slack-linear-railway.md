# Slack + Linear on Railway

Deploy LettaBot to Railway as a Slack bot that stays conversational and creates Linear issues when people explicitly ask for a task or ticket.

This flow uses:

- the root `Dockerfile` for Railway builds
- the project-local `.skills/linear-cli` skill to teach task creation behavior
- `@kyaukyuai/linear-cli` in the container so `linear` is always on `PATH`

## Prerequisites

- A Letta API key from [app.letta.com](https://app.letta.com)
- A Slack workspace where you can install apps
- A Linear Personal API key
- A Railway project with a persistent volume mounted at `/data`

## 1. Slack app setup

Start with the general [Slack setup guide](./slack-setup.md), then make sure your app has the scopes and events needed for the group modes you plan to use.

Required for DMs and `mention-only` channels:

| Type | Values |
|------|--------|
| Bot scopes | `app_mentions:read`, `chat:write`, `files:read`, `im:history`, `im:read`, `im:write` |
| Bot events | `app_mention`, `message.im` |

Also required if you want `groups.<id>.mode: open` or `listen` in public/private channels:

| Type | Values |
|------|--------|
| Extra bot scopes | `channels:history`, `channels:read`, `groups:history`, `groups:read` |
| Extra bot events | `message.channels`, `message.groups` |

If you change scopes or event subscriptions after install, reinstall the Slack app in the workspace.

## 2. Use the provided config example

Copy [slack-linear-railway.example.yaml](../slack-linear-railway.example.yaml) to a working config file and replace the placeholders with real values.

Important details:

- There is no `persona:` field in the current schema. This setup relies on the `linear-cli` skill instead of a long prompt blob.
- Add `features.skills: [linear-cli]` so Railway installs the project-local skill into the agent-scoped skills directory before the session starts.
- Do not leave `${VAR}` placeholders in YAML. Current LettaBot config does not interpolate environment variables inside YAML values.
- Do not use `agent.model` as your primary model-setting workflow. Reuse an existing agent with `agent.id`, or set the model after first boot.

## 3. Encode the config for Railway

From the repo root:

```bash
cp slack-linear-railway.example.yaml lettabot.yaml
$EDITOR lettabot.yaml
LETTABOT_CONFIG=./lettabot.yaml lettabot config encode
```

Set the printed value as `LETTABOT_CONFIG_YAML` in Railway.

## 4. Railway service variables

For this deployment path, these values are required inputs:

| Input | Required | Where it lives in this guide |
|-------|----------|------------------------------|
| `LETTA_API_KEY` | Yes | Encoded inside `LETTABOT_CONFIG_YAML` |
| `SLACK_BOT_TOKEN` | Yes | Encoded inside `LETTABOT_CONFIG_YAML` |
| `SLACK_APP_TOKEN` | Yes | Encoded inside `LETTABOT_CONFIG_YAML` |
| `LINEAR_API_KEY` | Yes | Standalone Railway service variable |
| `LINEAR_WORKSPACE` | No | Standalone Railway service variable |
| `LINEAR_TEAM_ID` | No | Standalone Railway service variable |
| `LETTABOT_CONFIG_YAML` | Yes | Standalone Railway service variable |
| `LETTABOT_API_KEY` | No | Standalone Railway service variable |

The example in this guide assumes a structured YAML deploy, so Letta and Slack secrets are carried inside `LETTABOT_CONFIG_YAML`. `LINEAR_API_KEY` should remain a normal environment variable so the bundled `linear` CLI can read it directly.

## 5. Deploy

Railway will auto-detect the root `Dockerfile`, build the image, and run LettaBot with the container `CMD`.

Recommended service setup:

- mount a volume at `/data`
- keep the default `/health` healthcheck
- set `LOG_FORMAT=json` for searchable logs

The container now includes:

- `linear` on `PATH`
- bundled `skills/`
- project-local `.skills/`

## 6. Model selection

The current YAML schema does not use a `persona` or `model` field as the source of truth for the agent.

Recommended options:

1. Reuse an existing Letta agent with the right model and set `agent.id` in the YAML.
2. Let Railway create a new agent on first message, then update the model once with `lettabot model set <handle>` from an environment that can access the same agent.

## 7. Verify end to end

1. Deploy and confirm `/health` returns `ok`.
2. Send a DM like `Hello` and confirm the bot responds normally.
3. In a `mention-only` channel, mention the bot with a normal question and confirm it answers without creating an issue.
4. In an `open` or mentioned channel, send an explicit tasking request such as:
   - `ログイン画面のエラーを修正するタスクを作って`
   - `API rate limit handling needs a Linear issue`
5. Confirm the bot replies with the created issue identifier and URL.

## Troubleshooting

### The bot responds in DMs but not open channels

You are usually missing one of the extra Slack events or scopes for channel-wide message delivery:

- `message.channels`
- `message.groups`
- `channels:history`
- `channels:read`
- `groups:history`
- `groups:read`

### The bot chats normally but does not create Linear issues

Check all of these:

- `LINEAR_API_KEY` is set on the Railway service
- `features.skills` includes `linear-cli` in your encoded YAML
- Bash is still enabled for the agent
- the request actually contains explicit tasking intent

### The wrong model is being used

`agent.model` in YAML is deprecated/ignored. Reuse an existing agent ID or update the agent model after first boot.
