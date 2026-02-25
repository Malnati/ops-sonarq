// mock-app/eslint.config.cjs (CommonJS para ESLint 8.x)
const tseslint = require("@typescript-eslint/eslint-plugin");
const tsParser = require("@typescript-eslint/parser");
const sonarjs = require("eslint-plugin-sonarjs");

/** @type {import("eslint").Linter.FlatConfig} */
module.exports = [
  {
    ignores: [
      "node_modules/**",
      ".sonarq/**",
      ".scannerwork/**",
      "dist/**",
      "build/**",
      "coverage/**",
      "eslint.config.cjs",
    ],
  },
  // Regras base removidas: use apenas plugins e regras customizadas
  {
    files: ["**/*.ts", "**/*.tsx"],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
        project: ["./tsconfig.json"],
      },
    },
    plugins: {
      "@typescript-eslint": tseslint,
      sonarjs,
    },
    rules: {
      ...tseslint.configs.recommended.rules,
      "@typescript-eslint/no-unsafe-declaration-merging": "off",
      "@typescript-eslint/no-magic-numbers": [
        "error",
        {
          ignoreArrayIndexes: true,
          ignoreEnums: true,
          detectObjects: true,
          ignoreReadonlyClassProperties: true,
          enforceConst: true,
          ignore: [-1, 0, 1],
        },
      ],
      "no-restricted-syntax": [
        "error",
        {
          selector: "ExportNamedDeclaration > VariableDeclaration[kind='const']",
          message:
            "Constantes exportadas devem ser definidas APENAS em 'src/util/constants.ts'.",
        },
      ],
      "sonarjs/no-duplicate-string": ["error", { threshold: 2 }],
    },
  },
  {
    files: ["src/util/constants.ts"],
    rules: {
      "no-restricted-syntax": "off",
      "@typescript-eslint/no-magic-numbers": "off",
      "sonarjs/no-duplicate-string": "off",
    },
  },
  {
    files: ["**/*.spec.ts", "**/*.test.ts"],
    rules: {
      "@typescript-eslint/no-magic-numbers": "off",
      "sonarjs/no-duplicate-string": "off",
    },
  },
];
