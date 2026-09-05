# Contributing

Thanks for your interest in improving this project.

## Reporting an issue

Open an [Issue](../../issues) including:

- Exact Mac model (Air/Pro, M1/M2) and amount of RAM.
- macOS version you started from.
- Chosen distro (Kali or Parrot) and which script the process failed on.
- Full error output (use code blocks with ```).

## Proposing an improvement

1. Fork the repository.
2. Create a descriptive branch: `git checkout -b fix/external-partitioning`.
3. Test your changes on a real machine before opening the PR — given the
   risk involved in these scripts, changes without evidence of testing
   won't be accepted.
4. Open the Pull Request describing what problem it solves and on which
   Mac model you tested it.

## Script style

- Bash with `set -euo pipefail` at the top of every script.
- Comments explaining the *why*, not just the *what*.
- Any destructive step (partitioning, deleting) must ask for explicit user
  confirmation before executing.
