# Image measurements

| Image | Base | Size | Cold build | Rebuild after code change | Runs as |
|---|---|---|---|---|---|
| catalogue (upstream) | node:14 | <fill> | <fill> | <fill> | root |
| catalogue (naive) | node:22 | <fill> | <fill> | <fill> | root |
| catalogue (ours) | node:22-bookworm-slim@digest | <fill> | <fill> | <fill> | node (1000) |

## Tagging policy
- Tag = 7-char git SHA of the roboshop-app commit (`roboshop/<svc>:<sha7>`). Never `latest`.
- ECR repos are IMMUTABLE: a tag can never be overwritten.
- Deployments reference the DIGEST (`@sha256:...`); the tag is kept alongside for humans.
- Promotion dev → qa → prod moves the SAME digest; we never rebuild for an environment.
- Images carry org.opencontainers.image.revision = the commit, so any running container traces back to code.
