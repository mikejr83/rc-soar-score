# Agent Guide for Soar Score

This document provides essential information for AI agents and developers working on the Soar Score codebase.

## Project Overview

Soar Score is an RC sailplane soaring contest scoring and management suite. It consists of multiple Flutter and Dart applications and shared packages, all managed as an NX monorepo.

**Tech Stack:**

- Flutter
- Dart
- NX
- Node

## Environment Setup

**Prerequisites:**

- Node.js
- Flutter (includes Dart)

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


### Test

```bash
# Test all projects
npm run test


### Lint/Analyze

```bash
# Analyze all projects
npm run lint


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

## Style guidelines

When creating files keep them targeted to the domain at hand. Do not place many classes in a single file. Test case files should be broken into manageable sizes.
