# Score Soar

RC sailplane soaring contest scoring and management suite built with Flutter and managed with NX.

## Projects

- **score-soar-api** - API layer for backend services and data persistence
- **score-soar-contest** - Contest management web application for contest directors
- **score-soar-public** - Public-facing "RC Soar Score" website for viewing contests

## Quick Start

```bash
# Install NX dependencies
npm install

# Build all projects
npm run build

# Test all projects
npm run test

# Analyze all projects
npm run lint
```

## NX Commands

```bash
# Build individual project
npx nx build score-soar-api

# Run tests on a specific project
npx nx test score-soar-contest

# View dependency graph
npx nx graph
```

## Technology Stack

- Flutter 3.24.0
- NX 19.x
- Dart

## License

MIT