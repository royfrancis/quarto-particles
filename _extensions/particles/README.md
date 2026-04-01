# Quarto Particles Extension

## Purpose

The `particles` shortcode renders a particles.js container for HTML and revealjs outputs.

## Entry Point

- `particles.lua`: shortcode entrypoint that orchestrates argument parsing, config build, and output rendering.

## Module Layout

- `_modules/defaults.lua`: default particles.js config and reserved shortcode keys.
- `_modules/codec.lua`: value parsing, JSON encoding, and HTML attribute escaping helpers.
- `_modules/config.lua`: clone/merge logic and dotted-path override handling.
- `_modules/render.lua`: HTML and JavaScript output builders for html and revealjs formats.

## Resources

- `assets/js/particles.min.js`: bundled particles.js runtime.
- `particles.css`: base styles for the particles wrapper.

## Shortcode Notes

- Nested options use dot notation, for example `particles.move.speed=2`.
- `config` accepts a JSON string and supports `config-mode=merge|replace`.
- Container attributes handled specially are `id`, `class`, and `style`.
