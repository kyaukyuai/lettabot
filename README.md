# LettaBot

Persistent AI assistant for Telegram, Slack, Discord, WhatsApp, Signal, and Bluesky. Built on the [Letta Code SDK](https://github.com/letta-ai/letta-code-sdk).

<img width="750" alt="lettabot-preview" src="assets/preview.jpg" />

[![Discord](https://img.shields.io/badge/discord-join-blue?style=flat-square&logo=discord)](https://discord.gg/letta)

LettaBot is designed for one agent with long-lived memory, reachable from the messaging apps you already use. You can run it locally, self-host it, or deploy it on Railway.

> [!IMPORTANT]
> This fork exists as a companion repository for the article "LettaBot × 自作 linear-cli — 記憶を持つ Slack Bot でタスク管理を試した".
> It is preserved as a snapshot for readers and is not intended to be actively maintained.
> For the article version of this repo, use the `article-note-43` tag.
> For the maintained upstream project, see [letta-ai/lettabot](https://github.com/letta-ai/lettabot).

## Why LettaBot

- One agent can span multiple channels with shared memory.
- Conversations persist across restarts and redeploys.
- The agent can use local tools, custom skills, scheduling, and voice.
- You can start simple with one bot token, or grow into multi-agent YAML configs.
- Railway deploys use the root `Dockerfile`, so runtime behavior matches local builds.

## Start Here

### Railway

Deploy the repository on Railway from GitHub and provide `LETTA_API_KEY` for the first boot.

What happens now:

1. Create a Railway service from this GitHub repository and provide `LETTA_API_KEY`.
2. Railway creates the service and attaches the template volume.
3. The service can boot even before channels are configured, so healthchecks pass on first deploy.
4. Add either `LETTABOT_CONFIG_YAML` or channel-specific environment variables, then redeploy.

For a real bot connection, you still need at least one channel configuration after the first deploy.

Common next steps:

- Telegram: set `TELEGRAM_BOT_TOKEN`
- Slack: set `SLACK_BOT_TOKEN` and `SLACK_APP_TOKEN`
- Full YAML: set `LETTABOT_CONFIG_YAML`

Use these guides after the initial deploy:

- [Railway Deployment](docs/railway-deploy.md)
- [Slack + Linear on Railway](docs/slack-linear-railway.md)

### Local

Prerequisites:

- Node.js 20+
- A Letta API key from [app.letta.com](https://app.letta.com), or a running [Letta Docker server](https://docs.letta.com/guides/docker/)
- At least one channel token if you want the bot to receive messages immediately

Install and start:

```bash
git clone https://github.com/letta-ai/lettabot.git
cd lettabot
npm install
npm run build
npm link
lettabot onboard
lettabot server
```

If you prefer AI-assisted setup, paste this into Letta Code, Claude Code, Cursor, or another coding agent:

```text
Clone https://github.com/letta-ai/lettabot, read the SKILL.md,
and help me configure LettaBot for my preferred channel.
```

Prefer to use your ChatGPT subscription instead of a separate API key? Run:

```bash
lettabot connect chatgpt
```

## Popular Setups

- Personal assistant on Telegram: [Getting Started](docs/getting-started.md)
- Team bot on Slack: [Slack Setup](docs/slack-setup.md)
- Slack bot that creates Linear issues on Railway: [Slack + Linear on Railway](docs/slack-linear-railway.md)
- Discord bot with shared memory: [Discord Setup](docs/discord-setup.md)
- Multi-agent fleet config: [Configuration Reference](docs/configuration.md)

## Capabilities

- Multi-channel messaging across Telegram, Slack, Discord, WhatsApp, and Signal
- Read-only Bluesky Jetstream ingestion for selected DID(s)
- Shared memory across channels, or per-channel/per-chat conversation routing
- CLI and filesystem tool use from the agent runtime
- Voice transcription and voice memo replies
- Heartbeats and recurring background work
- Turn logging, attachments, outbound file sending, and redaction controls
- Skills from the repo, `.skills/`, Letta global skills, and skills.sh

## Channels

| Channel | Guide | Notes |
|---------|-------|-------|
| Telegram | [Getting Started](docs/getting-started.md) | Easiest first setup |
| Slack | [Slack Setup](docs/slack-setup.md) | Socket Mode bot |
| Discord | [Discord Setup](docs/discord-setup.md) | Bot token + intents |
| WhatsApp | [WhatsApp Setup](docs/whatsapp-setup.md) | Requires phone pairing |
| Signal | [Signal Setup](docs/signal-setup.md) | Requires `signal-cli` |
| Bluesky | [Bluesky Setup](docs/bluesky-setup.md) | Read-only ingestion or posting |

By default, LettaBot uses one shared conversation across channels. If you want per-channel or per-chat isolation, configure it in `lettabot.yaml`. See [Configuration Reference](docs/configuration.md).

## Skills

Skills extend the agent with specialized instructions and helper CLIs.

Useful commands:

```bash
lettabot skills
lettabot skills status
```

Project-local skills live in `.skills/`. Bundled skills ship in `skills/`. See [Skills](docs/skills.md) for discovery order, installation behavior, and authoring guidance.

## Configuration

For anything beyond the simplest environment-variable setup, use `lettabot.yaml` and encode it for cloud deploys:

```bash
LETTABOT_CONFIG=./lettabot.yaml lettabot config encode
```

Configuration docs:

- [Configuration Reference](docs/configuration.md)
- [Railway Deployment](docs/railway-deploy.md)
- [Cloud Deployment](docs/cloud-deploy.md)
- [Self-Hosted Letta Server](docs/selfhosted-setup.md)

## Documentation

- [Docs Index](docs/README.md)
- [Voice](docs/voice.md)
- [OpenAI-Compatible API](docs/openai-compat.md)
- [Testing](TESTING.md)
- [Project Skill Instructions](SKILL.md)

## License

Apache-2.0
