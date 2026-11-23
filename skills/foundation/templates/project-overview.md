---
name: project-overview
description: Use when locating code in {project}, adding a file, module, route or screen, or before searching the source tree. Layers, key directories, entry points, naming.
user-invocable: false
---

# {Project}: code map

Read this instead of exploring the tree. Paths and conventions only, each checked against the repository when written; behaviour and decisions stay in `wiki/architecture.md` and `wiki/tech-stack.md`. At most 80 lines. Updated in the same commit as any change that adds, moves or renames a top-level source directory, an entry point or a layer.

## Layers

{One line per layer, outermost first: name, directory, what it may import. Example: `ui → src/app/ → may import domain, never data`.}

## Key directories

| Path | Holds | A new … goes here |
|---|---|---|
| {`src/…`} | {what lives there} | {component, route, migration, test…} |

## Entry points

- {App start, route or screen registry, background jobs, configuration loading: path and one line each.}

## Naming

- {Files, components, tests, database objects: the rule and one real example from the tree.}

## Not to search or edit

- {Build output, generated code, vendored code, lock files: their paths.}
