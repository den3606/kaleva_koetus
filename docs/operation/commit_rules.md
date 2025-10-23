# Commit Rules

There are no mandatory requirements for commit messages, but one of the following styles is **recommended**.
Among them, **option 1 (Conventional Commits)** is **preferred**, since emojis can be interpreted differently by each person.

## 1. Follow Conventional Commits

As suggested on [conventionalcommits.org](https://www.conventionalcommits.org), include a prefix such as `fix` or `feat` in your commit message.

| Prefix | Description |
|---------|-------------|
| **feat** | New feature or addition |
| **fix** | Bug fix |
| **refactor** | Code refactoring (no functional changes) |
| **chore** | Very small or minor change |
| **inspect** | Temporary commit for verification (not intended for PR submission) |
| **docs** | Editing a document |

If necessary, you may use `other:` or any clear, descriptive prefix.

---

## 2. Use Emojis

We don’t adopt the full [gitmoji](https://gitmoji.dev) set since it’s too extensive, but you may use simple equivalents:

| Emoji | Equivalent to |
|--------|----------------|
| `:sparkles:` ✨ | `feat` |
| `:hammer:` 🔨 | `fix` |
| `:recycle:` ♻️ | `refactor` / `chore` |
| `:construction:` 🚧 | `inspect` |
