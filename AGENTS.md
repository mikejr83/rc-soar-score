# Agent Guide for Soar Score

This document provides essential information for AI agents and developers working on the Soar Score codebase.

## Project Overview

Soar Score is an RC sailplane soaring contest scoring and management suite. It consists of multiple Flutter and Dart applications and shared packages, all managed as an NX monorepo.

**Tech Stack:**
- Flutter 3.24.0
- Dart 3.13.3
- NX 19.x
- Node 20.x

## Repository Structure

```
soar-score/
├── apps/                    # Application entry points
│   ├── soar-score-api/      # REST API server (Dart CLI + shelf)
│   ├── soar-score-contest/  # Contest management web app (Flutter)
│   └── soar-score-public/   # Public viewing web app (Flutter)
├── packages/                # Shared packages
│   ├── soar_score_api/      # API client/server code
│   ├── soar_score_core/     # Domain models, business logic, scoring engine
│   ├── soar_score_data/     # Data access layer (SQLite, HTTP)
│   └── soar_score_ui/       # Shared Flutter UI components
├── .github/workflows/       # CI/CD configuration
├── nx.json                  # NX workspace configuration
└── package.json             # Root package.json (NX scripts)
```

### Project Naming

Note that NX project names use `score-soar-*` while directory names use `soar-score-*`:

| Directory | NX Project Name |
|-----------|-----------------|
| `apps/soar-score-api` | `score-soar-api` |
| `apps/soar-score-contest` | `score-soar-contest` |
| `apps/soar-score-public` | `score-soar-public` |

## Dependency Graph

```
soar-score-api (app)
└── uses shelf framework directly

soar-score-contest (app)
├── soar_score_core
├── soar_score_data
├── soar_score_ui
└── soar_score_api

soar-score-public (app)
├── uses Flutter directly
└── (no shared package dependencies)

soar_score_api (package)
├── soar_score_core
└── soar_score_data

soar_score_data (package)
└── soar_score_core

soar_score_ui (package)
└── soar_score_core
```

## Environment Setup

**Prerequisites:**
- Node.js 20.x
- Flutter 3.24.0 (includes Dart)

**Initial setup:**
```bash
# Install NX dependencies
npm install

# Install Flutter/Dart dependencies for all projects
npx nx run-many --target=pub-get --all
```

## Development Workflow

### Build
```bash
# Build all projects
npm run build

# Build individual project
npx nx build score-soar-api
npx nx build score-soar-contest
npx nx build score-soar-public
```

### Run/Dev Servers
```bash
# API server
npm run serve:api
# Or: cd apps/soar-score-api && dart run lib/main.dart

# Contest app (Chrome)
npm run serve:contest
# Or: cd apps/soar-score-contest && flutter run -d chrome

# Public app (Chrome)
npm run serve:public
# Or: cd apps/soar-score-public && flutter run -d chrome
```

### Test
```bash
# Test all projects
npm run test

# Test individual project
npx nx test score-soar-api
npx nx test score-soar-contest
npx nx test score-soar-public
```

### Lint/Analyze
```bash
# Analyze all projects
npm run lint

# Analyze individual project
npx nx analyze score-soar-api
npx nx analyze score-soar-contest
npx nx analyze score-soar-public
```

### NX Run Many
```bash
# Run target across all projects
npx nx run-many --target=test --all --parallel=3
npx nx run-many --target=analyze --all --parallel=3
```

## Testing Conventions

- Tests are located in `test/` directories within each app and package
- Flutter apps use `flutter_test` package
- Dart CLI/API projects use `test` package
- Run with: `npx nx test <project-name>` or directly with `dart test` / `flutter test`

## Code Style & Linting

- All projects use `analysis_options.yaml` at their root
- Flutter apps include `package:flutter_lints/flutter.yaml`
- Dart CLI projects include `package:lints/recommended.yaml`
- Run `npx nx analyze <project-name>` to check

## Build System (NX)

- NX manages build dependencies and caching
- Target dependencies are defined in `nx.json` and individual `project.json` files
- `pub-get` runs before build, test, and analyze targets
- Build outputs are cached for performance
- Use `npx nx graph` to visualize the dependency graph

## CI/CD

- GitHub Actions workflow in `.github/workflows/ci.yml`
- Runs on push/PR to `main` and `develop` branches
- Steps: install deps → analyze → test → build
- Uses `ubuntu-latest`, Node 20, Flutter 3.24.0

## Important Conventions

1. **Path dependencies**: All shared packages use path-based dependencies in `pubspec.yaml`
2. **No pub flag**: NX commands use `--no-pub` for Flutter commands (pub-get is a separate target)
3. **JSON serialization**: Use `json_annotation` and `json_serializable` for data models
4. **State management**: Follow Flutter best practices for the specific app
5. **API design**: RESTful endpoints on shelf-based server

## Business and Architecture Requirements

Documentation is provided in the `./plan` folder. This contains business, architecture, and ui requirements. Consult this documentation when determining the best course of action for implementing business logic.

## Getting Help

- Run `npx nx help` for NX command reference
- Check individual `project.json` files for project-specific targets
- Review `analysis_options.yaml` for linting rules
- Consult Flutter documentation: https://docs.flutter.dev/
- Consult Dart documentation: https://dart.dev/
