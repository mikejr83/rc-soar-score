# Agent Guide for Soar Score

This document provides essential information for AI agents and developers working on the Soar Score codebase.

## Project Overview

Soar Score is an RC sailplane soaring contest scoring and management suite. It consists of multiple Flutter and Dart applications and shared packages, all managed by Melos in a Dart monorepo.

**Tech Stack:**

- Flutter
- Dart
- Melos

## Environment Setup

**Prerequisites:**

- Melos
- Flutter (includes Dart)

## Testing Conventions

- Tests are located in `test/` directories within each app and package
- Flutter apps use `flutter_test` package
- Dart CLI/API projects use `test` package
- Run with: `melos test` or directly with `dart test` / `flutter test`

## Code Style & Linting

- All projects use `analysis_options.yaml` at their root
- Flutter apps include `package:flutter_lints/flutter.yaml`
- Dart CLI projects include `package:lints/recommended.yaml`
- Run `melos analyze` to check


## CI/CD

- GitHub Actions workflow in `.github/workflows/ci.yml`
- Runs on push/PR to `main` and `develop` branches
- Steps: install deps → analyze → test → build

## Important Conventions

1. **Path dependencies**: All shared packages use path-based dependencies in `pubspec.yaml`
2. **JSON serialization**: Use `json_annotation` and `json_serializable` for data models
3. **State management**: Follow Flutter best practices for the specific app
4. **API design**: RESTful endpoints on shelf-based server

## Business and Architecture Requirements

Documentation is provided in the `./plan` folder. This contains business, architecture, and ui requirements. Consult this documentation when determining the best course of action for implementing business logic.

## Getting Help

- Review `analysis_options.yaml` for linting rules
- Consult Flutter documentation: https://docs.flutter.dev/
- Consult Dart documentation: https://dart.dev/
- Consult Melos documentation: https://melos.invertase.dev/commands

## Style guidelines

When creating files keep them targeted to the domain at hand. Do not place many classes in a single file. Test case files should be broken into manageable sizes.
