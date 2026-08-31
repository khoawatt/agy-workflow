# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| main    | ✅        |

## Reporting a Vulnerability

Do not open a public issue for security vulnerabilities. Contact the maintainer via GitHub (@khoawatt) or open a private security advisory at `https://github.com/khoawatt/agy-workflow/security/advisories/new`.

Include a description, reproduction steps, and potential impact. We will acknowledge receipt within 48 hours.

## Secrets Handling

This repository is **secrets-free by design**. No real credentials are committed. Browser profiles (`~/.gemini/chatgpt-bridge/profile/`, `~/.gemini/gemini-bridge/profile/`), `chats.json`, and `projects.json` are gitignored. If you accidentally commit a secret, rotate it immediately.
