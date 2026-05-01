# Rd2typst: Modern PDF rendering for R help files using Typst

[![build-status](https://github.com/CGMossa/2026-rd2typst-isc-proposal/actions/workflows/publish-proposal.yaml/badge.svg)](https://github.com/CGMossa/2026-rd2typst-isc-proposal/actions/workflows/publish-proposal.yaml)

This repository contains the R Consortium ISC grant proposal for **Rd2typst**,
a Typst-based Rd converter for R's documentation system. Integration into
`R CMD Rd2pdf --backend=typst` is one of its deliverables.

## Project overview

R's help system currently renders `.Rd` documentation to PDF exclusively via
LaTeX: 1 to 4 GB for a TeX distribution, slow on CI runners, and broken on
minimal systems. CRAN package version drift is a recurring source of
`R CMD check` failures.

[Typst](https://typst.app) is a modern typesetting engine distributed as a
single ~25 MB binary with no external dependencies. It built its own PDF
renderer, font handling, and package system from scratch. Permissive
licensing means R-core can embed a complete Typst template, fonts, and
packages directly into r-source. No configuration required.

A working proof-of-concept `Rd2typst()` converter exists in a fork of
r-source. All 14 base R packages compile. The pipeline is 1.9x faster
than `pdflatex` across 257 help pages as a byproduct of single-pass
compilation. The proposal's emphasis is robustness and infrastructure:
no CTAN drift, embedded fonts and packages, no multi-gigabyte TeX
installation, and reproducible output across platforms. This proposal
funds four milestones:

1.  **Milestone 1 - CRAN-wide validation (\$2,500):** Run `Rd2typst`
    against all of CRAN ([23,734 packages as of writing](https://cran.r-project.org/web/packages/)).
    Fix failures. Expand the benchmark corpus.
2.  **Milestone 2 - Production integration: Rd2typst in `R CMD Rd2pdf`,
    embedded in r-source (\$2,500):** Ship a self-contained `Rd.typ`
    template with embedded fonts and Typst packages inside `share/typst/`
    of r-source. Implement `typst_binary()`. CI on Windows, macOS,
    Linux. Submit the r-source patch to r-devel.
3.  **Milestone 3 - Rd2md for LLM consumption (\$1,250):** Add
    `R CMD Rdconv -t md`. Deliver a Markdown export of R help pages for
    retrieval-augmented generation, coding-assistant context, and
    documentation MCP servers.
4.  **Milestone 4 - Rust/C port (stretch goal, \$750):** Rewrite the
    converter core in a compiled language for faster parsing and direct
    Typst crate integration. Ships as an r-source patch or standalone
    CRAN package depending on R-core's Rust/Cargo stance.

The code in `code/` contains the proof-of-concept implementation referenced
by the proposal:

| File | Description |
|------|-------------|
| `code/Rd2typst.R` | `Rd2typst()` converter: Rd tags to Typst markup |
| `code/RdConv2.R` | Shared Rd parsing infrastructure (refactored from r-source) |
| `code/test-Rd2typst.R` | 21-case unit test suite; smoke-tests all `base` help pages |
| `code/typst-benchmark.R` | Step-by-step benchmark: LaTeX vs. Typst pipeline timing |

**Author:** Mossa Merhi Reimert (mossa@a2-ai.com)  
**Total funding requested:** $7,000  
**Duration:** 6 to 12 months

## Building the proposal

Render `isc-proposal.qmd` to build the document locally:

```r
quarto::quarto_render("isc-proposal.qmd")
```

### Automatically render via GitHub Actions

This repository comes with a GitHub Actions workflow to automatically render
the proposal to HTML and PDF on every push to `main`. To enable it, publish
to GitHub Pages interactively the first time:

```sh
quarto publish gh-pages isc-proposal.qmd
```

After this, the action will run automatically. The rendered proposal is
viewable at `https://CGMossa.github.io/2026-rd2typst-isc-proposal/`.

## License

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons Licence" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br /><span xmlns:dct="http://purl.org/dc/terms/" property="dct:title">ISC Boilerplate</span> by <a xmlns:cc="http://creativecommons.org/ns#" href="https://github.com/stephlocke" property="cc:attributionName" rel="cc:attributionURL">Stephanie Locke</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.<br />Based on a work at <a xmlns:dct="http://purl.org/dc/terms/" href="https://github.com/RConsortium/isc-proposal" rel="dct:source">https://github.com/RConsortium/isc-proposal</a>.
