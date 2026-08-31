# Contributing to Antigravity Workflow (agy-workflow)

Thank you for your interest in contributing to `agy-workflow`! This project provides workflow automation and independent web-review bridges for Google Antigravity (AGY) using ChatGPT Plus and Google Gemini Web.

---

## Code of Conduct

Please be respectful and constructive when reporting issues, discussing proposals, or reviewing PRs.

---

## Development Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/khoawatt/agy-workflow.git
   cd agy-workflow
   ```

2. **Install dependencies**:
   ```bash
   bash install.sh --deps
   ```

3. **Install skills & config locally**:
   ```bash
   bash install.sh --config
   ```

4. **Verify tests pass**:
   ```bash
   bash tests/test.sh
   ```

---

## Pull Request Guidelines

1. **Keep it focused**: One bugfix or feature per PR.
2. **Backward compatibility**: Ensure existing workflows (`chatgpt-review`, `gemini-review`, `agy-work`) are not broken.
3. **Safe permissions**: All state and temporary files containing session or chat history must maintain `0600` permissions (`0700` for private directories).
4. **Independent Scrapers**: Gemini review bridge must remain advisory-only (no automated PR approval mutations).
5. **Run test suite**: Before pushing, run `bash tests/test.sh` and make sure it passes.

---

## Author & Maintainer

* **Quách Võ Anh Khoa** ([@khoawatt](https://github.com/khoawatt)) - *Author & Lead Maintainer*
