# Búsqueda de Juan

Tablero semanal de la búsqueda laboral de Juan: plan de 8 semanas (12 oct – 6 dic 2026), postulaciones, contactos y guías.

Página estática (HTML + JS) en Vercel, datos en Supabase. Sin cuentas: se entra con una clave compartida.

## Estructura

```
index.html            la página
config.js             URL y clave pública de Supabase
supabase/schema.sql   tablas, seguridad y funciones
supabase/seed.sql     las 28 tareas del plan con sus fichas
CLAVES.local.md       claves del proyecto (no se sube a GitHub)
```

Las claves están en `CLAVES.local.md`, que `.gitignore` deja afuera del repo. No las pegues en este README ni en ningún archivo que se suba.

## Puesta en marcha

### 1. Supabase (10 min)

1. Creá un proyecto en [supabase.com](https://supabase.com) (plan gratis). Región: São Paulo, la más cercana.
2. Abrí **SQL Editor**.
3. Abrí `supabase/schema.sql`, buscá `CAMBIAR-ESTA-CLAVE` y reemplazala por la clave que van a usar con Juan.
4. Pegá el archivo entero y tocá **Run**.
5. Hacé lo mismo con `supabase/seed.sql`.
6. En **Table Editor → tasks** tendrían que aparecer las 26 tareas.

### 2. Configurar la página

En Supabase, **Project Settings → API**, copiá:

- **Project URL** → `supabaseUrl` en `config.js`
- **anon public** → `supabaseAnonKey` en `config.js`

La anon key es pública por diseño. Las tablas están cerradas: sin la clave del tablero no se puede leer ni escribir nada.

### 3. GitHub + Vercel (5 min)

1. Subí la carpeta a un repo nuevo en GitHub (puede ser privado).
2. En [vercel.com](https://vercel.com): **Add New → Project**, elegí el repo.
3. Framework: **Other**. No hace falta build command.
4. **Deploy**. Vercel te da el link para mandarle a Juan.

Cada push a `main` actualiza la página sola.

## Mantenimiento

- **Corregir un texto o una tarea:** Supabase → Table Editor → `tasks`.
- **Cambiar la clave:** SQL Editor → `update app_secret set pass = 'nueva-clave' where id = 1;` Juan la tiene que ingresar de nuevo.
- **Agregar semanas o fichas:** editá `supabase/seed.sql` (o pedíselo a Claude Code) y volvé a correrlo. No pisa los tildes.

## Cómo funciona la seguridad

Las tablas tienen RLS activado sin políticas: el público no puede tocarlas. La página solo usa funciones (`get_board`, `set_task_done`, etc.) que chequean la clave antes de hacer nada. Es protección suficiente para un tablero entre dos personas; no guardes ahí datos sensibles.
