# particles

A quarto shortcode extension to add [Particles.JS](https://vincentgarreau.com/particles.js/) for html format.

![](preview.jpg)

## Install

- Requires Quarto >= 1.4.0
- In the root of the quarto project, run in terminal:

```
quarto add royfrancis/quarto-particles
```

This will install the extension under the `_extensions` subdirectory.

## Usage

```
---
title: Particles
filters:
  - particles
---

{{< particles >}}
```

For more examples and usage guide, see [here](https://royfrancis.github.io/quarto-particles).

## Acknowledgements

Built on [Particles.JS](https://vincentgarreau.com/particles.js/).

---

2025 • Roy Francis
