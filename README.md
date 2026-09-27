# brain-scripts

Colección curada de scripts autocontenidos para Brain CLI.

## Categorías

- `backup/` — Backups de configs, DBs, volúmenes
- `monitoring/` — CPU, RAM, disco, red
- `cleanup/` — Limpieza de sistemas y caches
- `dev/` — Git, proyectos, servidores locales
- `network/` — Conectividad, DNS, certificados
- `security/` — Crypto, hashing, SSH
- `data/` — Conversión CSV/JSON, dedupe
- `system/` — Info del sistema

## Convenciones

Cada script:
- Empieza con `#!/usr/bin/env bash` + `set -euo pipefail`
- Tiene un bloque de comentarios con `# Uso:` y `# Deps:`
- Sin self-update, sin instalación silenciosa
- Máximo 200 KB

## Licencia

MIT
