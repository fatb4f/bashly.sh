# Generated Surface

Generated Bashly output is an artifact, not the implementation source of truth.

## Rules

- Generated CLI files may be inspected and tested.
- Generated CLI files may be regenerated.
- Generated CLI files should not become the primary edit target.
- Any durable change should land in Bashly source or bridge logic.

## Purpose

This repo uses generated output to verify the public CLI contract after source
changes. That keeps the write path small and the verification path explicit.
