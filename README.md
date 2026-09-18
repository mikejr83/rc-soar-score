# Soar Score

RC sailplane soaring contest scoring and management suite built with Flutter and managed with NX.

## Projects

- **soar-score-api** - API layer for backend services and data persistence
- **soar-score-contest** - Contest management web application for contest directors
- **soar-score-public** - Public-facing "RC Soar Score" website for viewing contests

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
npx nx build soar-score-api

# Run tests on a specific project
npx nx test soar-score-contest

# View dependency graph
npx nx graph
```

## Technology Stack

- Flutter 3.24.0
- NX 19.x
- Dart

## License

MIT