## **10x-cards** by BroneK

![Node](https://img.shields.io/badge/node-22.14.0-339933) ![Astro](https://img.shields.io/badge/Astro-5.x-BC52EE) ![React](https://img.shields.io/badge/React-19-61DAFB) ![TypeScript](https://img.shields.io/badge/TypeScript-5-3178C6) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Project description

10x-cards is a lightweight web application for creating and managing study flashcards. It uses LLMs (via API) to propose flashcard candidates from user-provided text, helping reduce the time required to prepare effective Q&A items for spaced repetition. Users can accept, edit, or reject proposed cards, and also create cards manually. A basic authentication flow and an external spaced-repetition algorithm are planned for the MVP.

- See the Product Requirements Document for details: `.ai/prd.md`.

## Tech stack

- Astro 5 — content-focused framework for fast sites
- React 19 — interactive UI components
- TypeScript 5 — type-safe development
- Tailwind CSS 4 — utility-first styling
- shadcn/ui components and Radix primitives (e.g., `@radix-ui/react-slot`)
- Supporting libraries: `class-variance-authority`, `clsx`, `lucide-react`, `tailwind-merge`, `tw-animate-css`
- Tooling: ESLint 9, Prettier (with `prettier-plugin-astro`), Husky, lint-staged

For a brief overview, see `.ai/tech-stack.md`.

## Getting started locally

### Prerequisites

- Node.js 22.14.0 (see `.nvmrc`)
- npm (bundled with Node.js)

### Setup

1. Clone the repository

```bash
git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>
```

2. Install dependencies

```bash
npm install
```

3. (Optional) Configure environment variables

```bash
cp .env.example .env
# Fill in required API keys/secrets for the LLM provider and storage if applicable
```

4. Start the development server

```bash
npm run dev
```

5. Build for production

```bash
npm run build
```

6. Preview the production build

```bash
npm run preview
```

## Available scripts

- `dev`: start the Astro dev server
- `build`: build the production site
- `preview`: preview the production build locally
- `astro`: run Astro CLI directly
- `lint`: run ESLint
- `lint:fix`: fix lint issues
- `format`: format files with Prettier

## Project scope

Planned MVP scope (from PRD):

- Automatic flashcard generation from pasted text via LLM API, with list review for accept/edit/reject
- Manual flashcard CRUD and “My flashcards” list
- Basic authentication (sign up, sign in) and account deletion on request
- Spaced-repetition learning session using an external algorithm (no custom algorithm in MVP)
- Basic statistics: number of AI-generated cards and acceptance ratio
- Data storage designed for scalability and security, compliant with GDPR (access and deletion rights)

## Project status

Version: 0.0.1 — MVP

## License

MIT License. See `https://opensource.org/licenses/MIT`.
