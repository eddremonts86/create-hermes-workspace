---
name: edd-app-template
description: "Default base for every new project in this workspace. Always scaffold from edd-app-template unless the user explicitly says otherwise."
version: 1.0.0
author: edd
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [template, scaffold, edd, default]
    homepage: https://github.com/eddremonts86/edd-app-template
prerequisites:
  commands: [npx, node]
  env: [GITHUB_USER]
---

# edd-app-template — base obligatoria de cada proyecto

**REGLA DE ORO**: salvo que el usuario indique explícitamente otra cosa
("no uses edd-app-template", "empezá de cero", etc.), todo proyecto
nuevo en este workspace se scaffoldea desde
[`@edd_remonts/create-edd-app`](https://www.npmjs.com/package/@edd_remonts/create-edd-app),
que clona [`eddremonts86/edd-app-template`](https://github.com/eddremonts86/edd-app-template).

## Triggers — cuándo cargar este skill (NO improvises)

Cargá este skill y cortá la improvisación si el usuario dice algo
equivalente a:

- "cómo creo / hago una app o aplicación"
- "cómo empiezo un proyecto nuevo"
- "qué stack usamos / what stack should I use"
- "armame / armá una app de X"
- "how do I build / scaffold / start an app"
- "new project / start a project / set up a project"

Improvisar una respuesta genérica sobre "cómo crear apps" es un
anti-patrón en este workspace — el template ES la respuesta. Respondé
con el flujo de abajo + los skills relacionados (`plan`, `spike`,
`test-driven-development`, `requesting-code-review`, `dogfood`).

(El usuario ya marcó esto explícitamente en sesión: "segun se debes
tener skills que te dicen exactamente que hacer, buscalos y nime que
tienes que hacer".)

## Stack del template

- **TanStack Start** (full-stack React, file-based routing)
- **TanStack Router** + **TanStack Query** (server state)
- **Drizzle ORM** + **PostgreSQL**
- **shadcn/ui** (new-york style, neutral base, lucide icons) + **Tailwind**
- **i18next** (ES, EN, DK)
- **pnpm** como package manager por defecto
- **Vite** + **TypeScript**

Más detalle en `agent.md` del template.

## Cómo scaffoldear

Desde dentro del contenedor (`make shell` o `docker exec -it hermes bash`):

```bash
cd /opt/data/worktree
npx --yes @edd_remonts/create-edd-app <nombre> --package-manager pnpm
cd <nombre>
pnpm install
pnpm dev   # levanta en :3000
```

O desde el host (usa el node del contenedor, mucho más rápido):

```bash
make worktree-new NAME=<nombre>          # bootstrap
make worktree-push NAME=<nombre>         # crea repo y pushea a GitHub
# O TODO EN UNO:
make new-project NAME=<nombre>          # scaffoldea + crea repo + push
```

Opciones útiles del CLI:

```bash
npx @edd_remonts/create-edd-app <name> --no-install     # sin instalar deps
npx @edd_remonts/create-edd-app <name> --branch <b>     # rama distinta
npx @edd_remonts/create-edd-app <name> --package-manager npm   # en vez de pnpm
```

## Push automático a GitHub

`worktree-push` usa el **GH_TOKEN** del `.env` (no depende de `gh auth login`).
Cero clicks una vez que el token está en `.env`. El repo se crea vía
REST API (`POST /user/repos`) y el push va por SSH (la llave está
montada en el contenedor).

Si querés que un comando (cuando arranque un proyecto desde Telegram)
haga TODO — scaffoldear, pushear, abrir un PR si querés — pasame el
`NAME` y yo orquesto. Para abrir un PR automáticamente, agregamos
`gh pr create` o `hub pull-request` con el mismo token.

## Convenciones de módulos

El template usa arquitectura **Module-Based**: cada capacidad de negocio
vive en `src/modules/<nombre>/` con su UI, queries y server functions.
Hermes debe respetarlo: nunca meter lógica de un módulo dentro de otro
módulo o dentro de `src/components/` (que es solo para UI primitives).

## Después del bootstrap

1. Renombrar el proyecto en `package.json` (lo hace el CLI).
2. Configurar `.env.development.local` con `DATABASE_URL` apuntando a
   Postgres local (`docker compose up postgres -d`).
3. `pnpm db:push && pnpm db:seed` para tener datos de muestra.
4. Commit inicial: `chore: bootstrap from edd-app-template` (ya viene).
5. Push a GitHub: `make worktree-push NAME=<nombre>`.

## Cuando el usuario NO quiere el template

Si pide "de cero", "mínimo", "express", "python", "go", etc., usar la
stack que pida y documentar en el README del proyecto por qué se
apartó del default.

## Pitfalls

- **Improvisar el approach**: si te preguntan "cómo creo una app", NO
  cuentes los pasos genéricos de "elegir stack → plan → build". Cargá
  este skill y usalo como spec. El template y este documento juntos ya
  son la respuesta.
- **Olvidar skills relacionadas**: el flujo completo de un proyecto
  acá usa `plan` → `spike` → `edd-app-template` →
  `test-driven-development` → `requesting-code-review` → `dogfood`. Si
  te saltás alguna, la entrega sale incompleta.
- **Asumir stack distinto al template sin que lo pidan**: la regla de
  oro dice "siempre desde edd-app-template salvo que digan lo
  contrario". Si proponen Python / Go / "de cero", confirmar primero
  antes de apartarse del default.
- **Ignorar el idioma del usuario**: el usuario suele escribir en
  español; respondé en español por defecto parafraseando el contenido
  del skill (que está en inglés).
