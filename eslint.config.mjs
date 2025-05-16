// eslint.config.js
import js from '@eslint/js';
import globals from 'globals';
import tseslint from 'typescript-eslint';
import { defineConfig } from 'eslint/config';

export default defineConfig([
  // Fichiers ignorés
  {
    ignores: ['node_modules/**', 'dist/**', 'coverage/**', '.env', 'bun.lockb'],
  },

  // Config JS
  {
    files: ['**/*.{js,mjs,cjs}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: globals.node,
    },
    plugins: { js },
    extends: ['js/recommended'],
  },

  // Config TS
  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {
        project: './tsconfig.json',
        tsconfigRootDir: process.cwd(),
        sourceType: 'module',
      },
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
    plugins: {
      '@typescript-eslint': tseslint.plugin,
    },
    rules: {
      ...tseslint.configs.recommended.rules,

      // Useless optimisation
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/ban-ts-comment': 'warn',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/consistent-type-imports': 'warn',
      '@typescript-eslint/no-floating-promises': 'warn',
      '@typescript-eslint/no-misused-promises': [
        'warn',
        {
          checksVoidReturn: false,
        },
      ],

      // Bests pratics
      'no-console': 'warn',
      'eqeqeq': ['warn', 'always'],
      'curly': ['warn', 'all'],
      'no-implicit-coercion': 'warn',
      'no-return-await': 'warn',

      // Code Quality 
      'no-multi-spaces': 'warn',
      'no-unneeded-ternary': 'warn',
      'prefer-const': 'warn',
      'no-else-return': 'warn',

      // Security
      'no-async-promise-executor': 'error',
      'no-new-func': 'warn',
    },
  },
]);
