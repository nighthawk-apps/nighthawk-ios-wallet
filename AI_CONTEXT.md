# Coding Instructions for AI Agents

These rules apply when writing code in the Nighthawk iOS Wallet repository.

## General
- Never add inline comments. Always use a new line.
- Always check for missing imports before executing changes.

## Rust Code (darkfi-mobile-ffi)
- Struct field comments should use `///`.
- Always prefer f-strings where applicable or modern formatting.
- Import crates first, newline, then `crate::` and `super::`.

## Swift Code (iOS Client)
- Follow standard Swift iOS UI guidelines for TCA (The Composable Architecture) if applicable, or SwiftUI best practices.
- Ensure all view states are strictly separated from logic.
- Keep `import` statements sorted alphabetically.
