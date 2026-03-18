# Railway Deployment

Deploy LettaBot to [Railway](https://railway.app) for always-on hosting. For other platforms (Fly.io, Docker, Render), see [Cloud Deployment](./cloud-deploy.md).

This repo now prefers Railway's root-`Dockerfile` flow rather than Nixpacks so custom CLIs, project-local skills, and bundled skills behave the same locally and in production.

## Deploy from GitHub

1. Create a Railway service from this GitHub repository
2. Provide `LETTA_API_KEY`
3. Deploy the service
4. Add channel configuration and redeploy

**No local setup required.** The first deploy can boot with only `LETTA_API_KEY`, which lets Railway finish the deployment, attach the volume, and pass healthchecks before you wire up channels.

After the first deploy, configure the bot with either:

- `LETTABOT_CONFIG_YAML` for full YAML-based config
- Individual channel env vars such as `TELEGRAM_BOT_TOKEN` or `SLACK_BOT_TOKEN`

## Configuration

### Option A: Full YAML Config (Recommended)

Use `LETTABOT_CONFIG_YAML` to pass your entire `lettabot.yaml` as a single base64-encoded environment variable. This gives you access to the full config schema (multi-agent, conversation routing, group policies, etc.) without managing dozens of individual env vars.

```bash
# Encode your local config
base64 < lettabot.yaml | tr -d '\n'

# Or use the CLI helper
lettabot config encode
```

Set the output as `LETTABOT_CONFIG_YAML` in your Railway service variables. If your YAML includes Letta and channel credentials, no other env vars are needed.

### Option B: Individual Environment Variables

For simple setups (one channel, basic config), you can use individual env vars instead.

#### Required

| Variable | Description |
|----------|-------------|
| `LETTA_API_KEY` | Your Letta API key ([get one here](https://app.letta.com)) |

#### Channel Configuration (at least one required)

**Telegram:**
```
TELEGRAM_BOT_TOKEN=your-bot-token
TELEGRAM_DM_POLICY=pairing
```

**Discord:**
```
DISCORD_BOT_TOKEN=your-bot-token
DISCORD_DM_POLICY=pairing
```

**Slack:**
```
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
```

#### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `LETTA_AGENT_NAME` | `LettaBot` | Agent name (used to find/create agent) |
| `AGENT_NAME` | - | Legacy alias for `LETTA_AGENT_NAME` |
| `LETTA_AGENT_ID` | - | Override auto-discovery with specific agent ID |
| `CRON_ENABLED` | `false` | Enable cron jobs |
| `HEARTBEAT_ENABLED` | `false` | Enable heartbeat service |
| `HEARTBEAT_INTERVAL_MIN` | `30` | Heartbeat interval (minutes). Also enables heartbeat when set |
| `HEARTBEAT_SKIP_RECENT_POLICY` | `fraction` | Recent-user skip policy (`fixed`, `fraction`, `off`) |
| `HEARTBEAT_SKIP_RECENT_FRACTION` | `0.5` | Fraction of interval used when policy is `fraction` |
| `HEARTBEAT_SKIP_RECENT_USER_MIN` | `5` | Skip window in minutes when policy is `fixed` (`0` disables) |
| `HEARTBEAT_INTERRUPT_ON_USER_MESSAGE` | `true` | Cancel in-flight heartbeat when a user message arrives on the same key |
| `HEARTBEAT_TARGET` | - | Target chat (e.g., `telegram:123456`) |
| `OPENAI_API_KEY` | - | For voice message transcription |
| `API_HOST` | `0.0.0.0` on Railway | Optional override for API bind address |
| `LOG_LEVEL` | `info` | Log verbosity (fatal/error/warn/info/debug/trace) |
| `LOG_FORMAT` | - | Set to `json` for structured JSON output (recommended for Railway) |

## How It Works

### First Deploy Experience

If the service has `LETTA_API_KEY` but no channels yet, LettaBot starts in an API-only waiting state:

- `/health` returns `ok`
- the admin/API server is available
- no messaging channels are connected yet

This makes the published Railway template usable as a true first deploy. Once you add channel settings and redeploy, the bot starts receiving messages normally.

### Agent Discovery

On startup, LettaBot:
1. Checks for `LETTA_AGENT_ID` env var - uses if set
2. Otherwise, searches Letta API for an agent named `LETTA_AGENT_NAME` (or legacy `AGENT_NAME`, default: "LettaBot")
3. If found, uses the existing agent (preserves memory!)
4. If not found, creates a new agent on first message

This means **your agent persists across deploys** without any manual ID copying.

### Build & Deploy

Railway automatically:
- Detects the root `Dockerfile` and builds the container image
- Sets the `PORT` environment variable
- Binds API server to `0.0.0.0` by default on Railway (unless `API_HOST` is set)
- Monitors `/health` endpoint

If you need extra binaries, system packages, or project-local skills inside the runtime image, add them to the root `Dockerfile`.

## Persistent Storage

The Railway template includes a persistent volume mounted at `/data`. This is set up automatically when you deploy using the button above.

### What Gets Persisted

- **Agent ID** - No need to set `LETTA_AGENT_ID` manually after first run
- **Cron jobs** - Scheduled tasks survive restarts
- **Skills** - Agent-scoped (`.letta/agents/.../skills`) and working-dir (`WORKING_DIR/.skills`) skills persist
- **Attachments** - Downloaded media files

### Volume Size

- Free plan: 0.5 GB (sufficient for most use cases)
- Hobby plan: 5 GB
- Pro plan: 50 GB

### Manual Deployment (Without Template)

If you deploy manually from a fork instead of using the template, you'll need to add a volume yourself:

1. In your Railway project, click **+ New** and select **Volume**
2. Connect the volume to your LettaBot service
3. Set the mount path to `/data`

LettaBot automatically detects `RAILWAY_VOLUME_MOUNT_PATH` and uses it for persistent data.

By default (when `WORKING_DIR` is unset), LettaBot uses `$RAILWAY_VOLUME_MOUNT_PATH/data` as the working directory, so `WORKING_DIR/.skills` is persisted across redeploys. Agent-scoped skills are also stored under `$RAILWAY_VOLUME_MOUNT_PATH/.letta/agents/.../skills`.

## Remote Pairing Approval

When using `pairing` DM policy on a cloud deployment, you need a way to approve new users without CLI access.

### Web Portal

Navigate to `https://your-app/portal` to access the admin portal. It provides a UI for managing pairing requests across all channels (Telegram, Discord, Slack).

You'll need your `LETTABOT_API_KEY` to log in. The key is auto-generated on first boot and printed in logs. Set it as an environment variable for stable access across deploys:

```bash
# Railway
# Set LETTABOT_API_KEY in service variables

# Fly.io
fly secrets set LETTABOT_API_KEY=your-key -a your-app
```

### API

You can also approve pairings via the HTTP API:

```bash
# List pending pairing requests for a channel
curl -H "X-Api-Key: $LETTABOT_API_KEY" \
  https://your-app/api/v1/pairing/telegram

# Approve a pairing code
curl -X POST \
  -H "X-Api-Key: $LETTABOT_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"code": "ABCD1234"}' \
  https://your-app/api/v1/pairing/telegram/approve
```

Alternatively, use `allowlist` DM policy and pre-configure allowed users in environment variables to skip pairing entirely.

## Channel Limitations

| Channel | Railway Support | Notes |
|---------|-----------------|-------|
| Telegram | Yes | Full support |
| Discord | Yes | Full support |
| Slack | Yes | Full support |
| WhatsApp | No | Requires local QR pairing |
| Signal | No | Requires local device registration |

## Troubleshooting

### Deploy succeeded but the bot does not respond anywhere

The service can now start without channels during the first Railway deploy. To make the bot usable, add at least one channel configuration and redeploy:

- `TELEGRAM_BOT_TOKEN`
- `DISCORD_BOT_TOKEN`
- `SLACK_BOT_TOKEN` and `SLACK_APP_TOKEN`
- or `LETTABOT_CONFIG_YAML`

### Agent not found / wrong agent

- Check `LETTA_AGENT_NAME` (or legacy `AGENT_NAME`) matches your intended agent
- Or set `LETTA_AGENT_ID` explicitly to use a specific agent
- Multiple agents with the same name? The most recently created one is used

### Health check failing

Check Railway logs for startup errors. Common issues:
- Missing `LETTA_API_KEY`
- Invalid channel tokens
- `API_HOST` incorrectly set to localhost (`127.0.0.1`)

At startup, LettaBot prints a `[Railway] Preflight check` block with:
- `OK` lines for detected config
- `WARN` lines for risky settings (for example missing volume)
- `FAIL` lines for blocking issues (for example missing `LETTA_API_KEY`)

### Reading logs

Set `LOG_FORMAT=json` for structured output compatible with Railway's log search and filtering. Use `LOG_LEVEL=debug` to enable verbose channel-level debug output when diagnosing issues.

### Data not persisting

If data is lost between restarts:
1. Verify a volume is attached to your service
2. Check that the mount path is set (e.g., `/data`)
3. Look for `[Storage] Railway volume detected` in startup logs
4. If not using a volume, set `LETTA_AGENT_ID` explicitly
