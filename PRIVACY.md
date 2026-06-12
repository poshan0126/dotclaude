# Privacy Policy

Effective date: June 12, 2026

dotclaude (https://github.com/poshan0126/dotclaude) is a collection of plugins for Claude Code: agents, skills, rules, and hooks. It is a set of local configuration files and shell scripts, not a service.

## What we collect

Nothing. dotclaude has no telemetry, no analytics, no accounts, and no servers. The author receives no data of any kind from your use of these plugins.

## How the components work

All components run locally inside your Claude Code installation:

- Hooks are shell scripts that read tool input on your machine to allow or block an action. They write nothing outside your project and send nothing over the network.
- Agents, skills, and rules are markdown instructions interpreted by Claude Code locally.

## Network access initiated by you

Some skills run commands that contact external services only when you invoke them and confirm the step, using credentials already on your machine:

- Skills like /ship, /pr-review, and /fix-issue use git and the GitHub CLI (gh) with your existing authentication. Data goes to your git host under its privacy policy.
- /context-budget with the --api flag sends the text of your configuration files to the Anthropic API using your own ANTHROPIC_API_KEY to count tokens. Without the flag, no network call is made.
- The notify hook shows a notification through your operating system. It contacts no external service.

Your use of Claude Code itself is governed by Anthropic's own terms and privacy policy, which are separate from this project.

## Changes

Changes to this policy will appear in this file's git history.

## Contact

Open an issue at https://github.com/poshan0126/dotclaude/issues.
