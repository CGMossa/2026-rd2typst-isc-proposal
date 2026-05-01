---
title: "Rd2typst: Modern PDF rendering for R help files using Typst"
author:
  - name: Mossa Merhi Reimert
    orcid: 0009-0007-9297-1523
    roles:
      - "Senior Scientific Software Engineer"
    affiliations:
      - "A2-AI"
      - "RSMF: Enabling the Next Generation of Contributors to R"

date: today
date-format: iso
format:
  html:
    embed-resources: true
    keep-md: true
  hikmah-pdf:
    geometry:
      - left=1.25in
      - right=1.25in
bibliography: references.bib
---

**Proposal repository:** <https://github.com/cgmossa/2026-rd2typst-isc-proposal>

# Executive Summary

```{=html}
<!--
This section provides a condensed view of the entire proposal, one page long.
It should be a comprehensive high-level overview that captures the essence of
the proposal, including its goals, methods, expected outcomes, deliverables, and budget.
-->
```

We propose **Rd2typst**: a Typst-based Rd converter for R's documentation
system. This proposal requests \$7,000 to complete it, validate it
against the full Comprehensive R Archive Network (CRAN) corpus, and upstream it into r-source. Integration
into `R CMD Rd2pdf --backend=typst` is the primary deliverable of
Milestone 2.

**Why Typst?** Typst is a modern typesetting engine, not just a LaTeX
replacement. The Typst project built its own PDF renderer, SVG renderer,
font handling, and package system from scratch. The result is a toolchain
with very few moving parts: one static binary, no external system
dependencies, and a permissive package ecosystem. Typst packages use
permissive licenses. R-core can embed a complete Typst template, fonts,
and any required Typst packages directly into r-source. No Comprehensive TeX Archive Network (CTAN)-equivalent
fragility. No user-side configuration. R ships with everything it needs.

Typst now offers modern HTML output with native equation and bibliography
typesetting. The R community pioneered reproducible scientific writing
(Sweave, knitr, R Markdown, Quarto). Adopting Typst as the documentation
engine is the next step in that legacy.

**Why now?** The existing LaTeX path depends on a working TeX Live or
MiKTeX install: 1 to 4 GB, slow on Continuous Integration (CI) runners, and brittle on minimal
systems. CTAN package version drift is a recurring source of `R CMD check`
failures. A Typst-based path eliminates this class of failure entirely.

**What exists already.** A working implementation of `Rd2typst` exists
in a fork of r-source. It handles the complete set of Rd tags. All 14
base R packages compile end-to-end with `--backend=typst`. A 21-case
test suite, man pages, and Command-Line Interface (CLI) integration (`R CMD Rdconv -t typst`,
`R CMD Rd2pdf --backend=typst`) are already in place. A benchmark across
257 help pages shows the Typst pipeline is 1.9x faster than `pdflatex`
as a side effect of single-pass compilation. Speed is not the pitch.
The pitch is infrastructure: no CTAN drift, embedded fonts and packages,
no multi-gigabyte TeX installation, reproducible output across platforms,
and a clean `R CMD check` experience.

**Four milestones over 6 to 12 months:**

1.  **Milestone 1 - CRAN-wide validation (\$2,500):** Run `Rd2typst`
    against all of CRAN ([23,734 packages as of writing](https://cran.r-project.org/web/packages/)).
    Fix failures. Expand the benchmark corpus.
2.  **Milestone 2 - Production integration: Rd2typst in `R CMD Rd2pdf`,
    embedded in r-source (\$2,500):** Ship a self-contained Typst
    template (`Rd.typ`, fonts, packages) inside `share/typst/` of
    r-source. Implement `typst_binary()`. CI matrix on Windows, macOS,
    Linux. Submit r-source patch to r-devel.
3.  **Milestone 3 - Rd2md for LLM consumption (\$1,250):** Add
    `R CMD Rdconv -t md`. Markdown is the universal format for feeding
    documentation to coding-assistant models. Every CRAN package gains
    a clean Markdown export of its help pages.
4.  **Milestone 4 - Rust/C port of the Rd converter (\$750, stretch
    goal):** Rewrite the converter core in a compiled language for
    faster parsing and direct Typst crate integration.

**Total: \$7,000.**


# Signatories

```{=html}
<!--
This section provides the ISC with a view of the support received from
the community for a proposal. Acceptance isn't predicated on
popularity but community acceptance is important. Willingness to
accept outside input is also a good marker for project delivery.

An optional section would be for R-Core signatories where changes to R
are proposed.
-->
```

## Project team

Mossa Merhi Reimert ([`github/CGMossa`](https://github.com/CGMossa/),
ORCID [0009-0007-9297-1523](https://orcid.org/0009-0007-9297-1523),
site: [ministats.dev](https://ministats.dev)).
Senior Scientific Software Engineer at A2-AI.
Core extendr maintainer, co-author of the `extendr` JOSS paper
[@Reimert2024], and author of the `Rd2typst` proof-of-concept.
Mossa will perform all development work.

**About me.** Mossa holds a PhD in Veterinary Epidemiology and is the
maintainer of [extendr](https://extendr.rs), the Rust-to-R bindings
project. He is a member of
[RSMF: Enabling the Next Generation of Contributors to R](https://www.heatherturner.net/posts/rsmf/),
the contributor mentorship initiative led by Heather Turner.
This membership reflects a sustained commitment to R's open-source
infrastructure and contributor community.

```{=html}
<!--
Who are the people responsible for actually delivering the project if
the proposal gets accepted and are already signed up and rearing to
go? Briefly describe all participants and the skills they will bring
to the project.
-->
```

## Prior ISC funding

Mossa received an ISC grant for the extendr Object-Oriented Programming
(OOP) project: vctrs/S3, S7, and R6 support for extendr bindings.
**The entire scope of that proposal has been implemented**, not only
the funded milestones. The work is in production in
**[miniextendr](https://a2-ai.github.io/miniextendr/)** (a separate
package), with the full set of class systems documented at
<https://a2-ai.github.io/miniextendr/manual/class-systems/>.
miniextendr is currently undergoing user testing before being
marshalled into extendr proper.
No follow-up funding was requested in the interim. The intent was to
complete the full extendr OOP proposal before returning to the ISC.


---
bibliography: references.bib
---

# The Problem

```{=html}
<!--
Outlining the issue / weak point / problem to be solved by this
proposal. This should be a compelling section that sets the reader up
for the next section - the proposed solution!

It is important to cover:

 - [x] What the problem is
 - [x] Who it affects
 - [x] Why is it a problem
 - [x] What will solving the problem enable (why should it be solved)
 - [x] Brief summary of existing work and previous attempts (e.g., relevant R packages)
 - [ ] If proposing changes to R itself: letter of support from R Core member
-->
```

## Typst is the right foundation

Typst is a modern typesetting engine. It is more than a LaTeX replacement.

The Typst project built its own infrastructure end to end: their own PDF
renderer, their own SVG renderer, their own font handling, and their own
package system. This means the Typst toolchain has very few moving parts.
It ships as a single static binary. It requires no external system packages.
It has no runtime dependencies beyond the binary itself.

Typst's package ecosystem uses permissive licenses. R-core can embed a
full Typst template, fonts, and any required Typst packages directly into
r-source. There is no Comprehensive TeX Archive Network (CTAN)-equivalent fragility. There is no user-side
configuration. R ships with everything it needs.

Typst now offers modern HTML output with native typesetting of equations
and bibliographies. The R community pioneered reproducible scientific
writing: Sweave, knitr, R Markdown, Quarto. Adopting Typst as the
documentation engine is the next generation of that legacy.

Typst currently offers experimental HTML support. It will be the engine
for modern HTML output of R documentation in the future.

The R community has already begun integrating Typst from several
angles. Joseph Barbier's [`r2typ`](https://github.com/y-sunflower/r2typ)
provides a Typst runner for R. Baptiste Auguié's
[`gridcetz`](https://baptiste.codeberg.page/gridcetz/) is an early
Typst-backed graphics device for R. This proposal addresses the
documentation pipeline, complementing those efforts. See the
Acknowledgements at the end of this proposal.

## The LaTeX dependency is cumbersome for end-users

R's documentation system is one of its great strengths. Every function
ships with structured, cross-referenced help. Help can be rendered to
HTML, plain text, or PDF. The PDF path is `tools::Rd2pdf`. It relies
entirely on LaTeX. This dependency is cumbersome for everyone in the
chain: package repositories like Bioconductor, R-package developers,
Continuous Integration (CI) systems, and end users.

Generating PDF documentation from an R package requires a working LaTeX
installation. TeX Live (the standard distribution on Linux and macOS) is
1 to 4 GB. MiKTeX on Windows adds its own installer and
package-management quirks. On a fresh Ubuntu CI runner, installing the
minimal `texlive-latex-base` plus the packages used by `Rd.sty` takes 30
to 60 seconds and 500 MB or more.

The `tinytex` package [@tinytex2019] provides a leaner alternative. It
introduces its own bootstrap step and can fail when proxy settings,
filesystem permissions, or network access are restricted.

CTAN package version drift is a recurring source of `R CMD check`
failures. When a Comprehensive R Archive Network (CRAN) package depends on LaTeX packages that ship in
different versions across distributions, check results become
non-reproducible.

**Who is affected.** Every R developer who runs `R CMD check --as-cran`.
Every CRAN submission. Every package that generates PDF vignettes or
reference manuals. Every CI/CD pipeline that produces documentation
artifacts. Windows developers without MiKTeX are blocked from producing
PDF manuals without third-party tooling. Minimal Docker images and
serverless CI runners often lack headroom for a TeX distribution.

## LaTeX compilation is slow

A typical `R CMD check` run on a medium-sized package compiles LaTeX
twice, plus a `makeindex` pass, to resolve cross-references and build
the index. For packages with large manuals (50 or more help pages) this
can account for 10 to 30 seconds of wall-clock time. It is often the
slowest step of the check pipeline. On CRAN's build infrastructure this
cost is multiplied across thousands of packages.

Typst compiles in a single pass with incremental re-compilation support.
An internal benchmark measures the Typst backend at
**1.9x faster end-to-end across 257 help pages** drawn from the base R
packages, versus the `Rd2latex` + `pdflatex` pipeline. The speedup comes
from the typesetting step itself: Typst compiles a multi-hundred-page
document in one pass with no auxiliary file reruns.

Speed is a useful side effect of single-pass compilation. The primary
value of this work is infrastructure: a documentation pipeline that does
not rely on a multi-gigabyte external toolchain, does not break when
CTAN packages drift, and produces reproducible output across platforms.

The Rd2typst converter is currently written in R. Further speedup is
attainable. Milestone 4 proposes a compiled-language port if performance
becomes a priority. Infrastructure robustness is the overall priority
of this proposal.

Typst could be added to Rtools, so Windows users would not need to
install it separately.

## The existing path has no competition

Because LaTeX is the only supported PDF backend, the Rd pipeline has
evolved around LaTeX's idioms and limitations: `Rd.sty`, manual index
handling, separate `makeindex` invocation. The absence of an alternative
backend means there is no forcing function to keep the Rd-to-PDF path
lean, portable, or testable in isolation from a TeX installation. A Typst
backend decouples the conversion step from the typesetting step, making
both independently testable and paving the way for future improvements.

## Prior work and existing implementation

The `Rd2typst` converter described in this proposal is not hypothetical.
A working implementation exists at `src/library/tools/R/Rd2typst.R` in
the author's r-source fork. The proof-of-concept files (the converter,
the shared parser, the test suite, and the benchmark harness) are
mirrored in this proposal repository at
https://github.com/CGMossa/2026-rd2typst-isc-proposal/tree/main/code .
It handles the full set of Rd block and
inline tags: `\itemize`, `\enumerate`, `\describe`, `\tabular`,
`\figure`, `\eqn`/`\deqn`, `\if{typst}{...}` conditionals,
`\code`/`\verb`/`\preformatted`, all link variants (`\link`,
`\linkS4class`, `\href`, `\url`), and concordance tracking.

The Typst-specific details are all in place: inline code via `#raw()`
with full string escaping, fenced ` ```r ` blocks for syntax-highlighted
code, native `#table()` rendering, definition lists for `\arguments` and
`\value`, escaping of every Typst special character, and centered display
equations via `block: true`. The toolchain is wired through
`R CMD Rdconv -t typst`, `R CMD Rd2pdf --backend=typst`, and a
`typst_compile()` utility. The `"typst"` format is registered as a
recognized Rd conditional format. A 21-case test suite verifies each
major construct. The converter compiles all 14 base R packages end-to-end
without errors.

The Typst project [@typst] has reached version 0.13 (2025) with a stable
markup specification, an active package ecosystem, and growing adoption
in academic writing. It ships as a single static binary for Linux,
macOS, and Windows.

The key gap is not the Rd to Typst conversion or the Command-Line Interface (CLI) integration.
Both already exist. The gap is production hardening: validating against
the wider CRAN corpus, handling Typst binary distribution across
platforms in a CRAN-acceptable way, polishing the output layout to match
R's documentation conventions, embedding a fully self-contained template
into r-source, and shepherding the patch through R-core review.

## A note on R-core engagement

This proposal targets changes to base R's `tools` package. A letter of
support from an R-core member is not yet attached. The patch path will
be opened with r-devel discussion early in Milestone 2, giving R-core
ample time to review and shape the work. The standalone CRAN-package
fallback (see Failure modes) ensures the deliverables reach R users
regardless of upstream timing.


# The proposal

```{=html}
<!--
How are you going to solve the problem? Include the concrete actions you
will take and an estimated timeline. What are likely failure modes and
how will you recover from them?

This is where the proposal should be outlined.
-->
```

## Overview

```{=html}
<!--
At a high-level address what your proposal is and how it will address
the problem identified. Highlight any benefits to the R Community that
follow from solving the problem.

Include concrete actions you will take and estimated timeline.
-->
```

We propose to complete the `Rd2typst` converter, integrate it as a
first-class backend in `tools::Rd2pdf`, and prepare it for upstream
submission to R-core. Work is structured as four milestones over
approximately 6 to 12 months. Each milestone delivers standalone value.
Together they produce a fully functional, Comprehensive R Archive Network (CRAN)-compatible alternative to
the LaTeX PDF rendering pipeline, a Markdown export path for LLM
consumption, and a compiled-language foundation for future performance.

## Detail

```{=html}
<!--
Go into more detail about the specifics of the project and how it
delivers against the problem.
-->
```

### Minimum Viable Product

```{=html}
<!--
What is the smallest thing you can build that delivers value to your
users?
-->
```

Milestones 1 and 2 together constitute the Minimum Viable Product.
Together they deliver `R CMD Rd2pdf --backend=typst` as a working,
CRAN-validated, TeX-Live-free PDF backend for R help files. Even if
Milestones 3 and 4 are not pursued, the MVP alone replaces the LaTeX
dependency for the entire R documentation pipeline. Milestone 3
(`Rd2md` for LLM consumption) and Milestone 4 (compiled-language port)
build on the MVP foundation but are independently scoped.

### Architecture

```{=html}
<!--
What does the high-level architecture look like?
-->
```

```
tools package (base R)
├── Rd2typst()              : Rd -> Typst markup converter   [done; CRAN-wide hardening]
├── Rd2md()                 : Rd -> Markdown converter       [Milestone 3]
├── typst_compile()         : Typst CLI wrapper              [done; needs binary mgmt]
├── R CMD Rdconv -t typst   : single-page Typst conversion   [done]
├── R CMD Rdconv -t md      : single-page Markdown conv.     [Milestone 3]
├── R CMD Rd2pdf            : orchestrator
│   ├── --backend=latex     : existing LaTeX path (unchanged)
│   └── --backend=typst     : Typst path                     [done; needs prod hardening]
│       ├── typst_binary()  : locate / vendor / download typst  [Milestone 2]
│       ├── Rd.typ          : embedded in share/typst/           [Milestone 2]
│       └── typst compile   : single-pass PDF generation
└── tests/                  : cross-platform CI for both engines  [Milestone 2]
```

<!-- Source commits: e2e8480a29, ea2f24352b, 2e9789d759 -->
#### What is already done

The existing implementation covers:

-   Rd-to-Typst converter handling all standard Rd tags (inline markup,
    lists, tables, figures, links, URLs, code blocks, math, conditionals)
-   Toolchain integration: `R CMD Rdconv -t typst`, `R CMD Rd2pdf
    --backend=typst`, and a `typst_compile()` wrapper in `utils.R`
-   `"typst"` registered as a recognized Rd conditional format in
    `RdConv2.R`, so `\if{typst}{...}` does not trigger `checkRd` warnings
-   Inline code via `#raw("...")` with proper string escaping. Fenced
    ` ```r ` blocks for syntax-highlighted code. Tables via `#table()`
    with `[...]` content-mode cell wrapping. Definition lists for
    `\arguments` and `\value`. Full escaping of every Typst special
    character. Display equations via `block: true`. Nested-markup
    stripping inside `\code`.
-   Inconsolata set as the monospace font via `#show raw: set
    text(font: "Inconsolata")` in `Rd2pdf.R`, with `--font-path` plumbed
    through `typst_compile()` to TeX Live's OpenType directory
-   Man pages: `Rd2HTML.Rd` updated to document `Rd2typst` alongside
    other converters. New `typst_compile.Rd`. `RdUtils.Rd` documents
    the `typst` format and `--backend=typst` option.
-   21-case unit test suite covering smoke test on all base Rd pages,
    plus structural output, inline markup, lists, tables, links,
    conditionals, escaping, and dots handling
-   All 14 base R packages compile end-to-end with the Typst backend
-   Benchmark across 257 help pages: Typst pipeline **1.9x faster
    end-to-end** than `Rd2latex` + `pdflatex`

The RdConv2 refactoring (`code/RdConv2.R`) provides the shared parsing
infrastructure (`RdTags`, `transformMethod`, `testRdConditional`, etc.)
used by both the LaTeX and Typst converters.

---

### Milestone 1: CRAN-wide validation

**Objective:** Run `Rd2typst` against all of CRAN
([23,734 packages as of writing](https://cran.r-project.org/web/packages/)).
Identify and fix failures. The current implementation passes the 14 base
R packages. CRAN is the next scale up.

M1 is not a performance milestone. Performance optimization lives in M4.
M1 is about establishing Rd2typst's robustness across the full CRAN
corpus.

**Implementation work:**

1.  **CRAN-wide run:** Run `R CMD Rdconv -t typst` across the full CRAN
    package corpus. Capture and triage failures by error type.
2.  **Bug fixes:** Fix parser failures, malformed output, and unhandled
    Rd macros found during the run.
3.  **Expanded test corpus:** Add test cases for edge cases found in the
    wild. Target at least 50 test cases total.
4.  **Math rendering:** Improve `\eqn`/`\deqn` handling. Translate
    common LaTeX math constructs to Typst's native math mode where
    possible (subscripts, superscripts, Greek letters, fractions).
5.  **Package index assembler:** Implement `.pkg2typst()` to concatenate
    all help pages into a single `.typ` file with a table of contents
    and index.
6.  **Updated benchmark:** Extend the existing benchmark beyond base R
    to the full CRAN corpus.

**Deliverables:**

-   Updated `Rd2typst.R` with fixes from CRAN-wide testing
-   `.pkg2typst()` function assembling a complete per-package Typst document
-   Expanded test suite (at least 50 test cases) covering edge cases
    found in the wild
-   Updated benchmark report across the full CRAN corpus
-   Blog post 1 on R Consortium blog

M1 is also a prerequisite for any future `R CMD Rd2html --backend=typst`
work. Without a CRAN-validated converter, an HTML backend cannot be
built on top.

---

### Milestone 2: Production integration: Rd2typst in `R CMD Rd2pdf`, embedded in r-source

**Objective:** Take the existing Rd2typst prototype to a
cross-platform, CRAN-acceptable production path. Ship a fully
self-contained Typst template embedded inside r-source. Integrate
Rd2typst as a first-class backend in `R CMD Rd2pdf`. Submit the
r-source patch.

Because Typst packages are permissively licensed, R-core can embed
the full template, fonts, and any required Typst packages directly into
`share/typst/` in the r-source tree. Users get PDF documentation working
out of the box with no configuration and no TeX Live installation.

**Implementation work:**

1.  **`typst_binary()` resolver:** Check for `typst` on PATH. Fall back
    to a per-user cache directory. Honor an `R_TYPST_BIN` environment
    variable for vendored binaries. Offer an opt-in auto-download of
    the official release binary.
2.  **Embedded Typst template:** Design `Rd.typ` to reproduce R's
    reference manual conventions: serif body font, monospace code,
    argument definition lists, page headers with package name, and an
    index. Ship it in `share/typst/` of r-source.
3.  **Embedded fonts:** Replace the current `--font-path` shortcut to
    TeX Live's OpenType directory. Bundle Inconsolata (OFL-licensed) in
    `share/typst/fonts/`. The result works on a system with no TeX
    installation at all.
4.  **Embedded Typst packages:** Identify any Typst packages required by
    the template. Embed them in `share/typst/packages/`. Permissive
    licenses make this straightforward.
5.  **Cross-platform CI matrix:** GitHub Actions matrix covering
    Windows, macOS, and Linux (Ubuntu 22.04 and 24.04), R at least 4.4.
    Verify `R CMD Rd2pdf --backend=typst` produces a valid PDF on each
    platform without a TeX installation.
6.  **`R CMD check` hook:** Investigate exposing the backend choice to
    `R CMD check --as-cran` via `_R_CHECK_RD_BACKEND_`, so Continuous Integration (CI) runs can
    opt into the LaTeX-free check path.
7.  **r-source patch:** Produce a clean patch against r-devel. Follow
    R's coding conventions. Include `NEWS` entry, updated
    `man/Rd2pdf.Rd`, and updated `INSTALL` notes.

**Deliverables:**

-   `typst_binary()` and binary management infrastructure
-   `Rd.typ` Typst stylesheet and embedded fonts in `share/typst/`
-   TeX-Live-free operation verified on a minimal Docker image
-   CI matrix (Windows, macOS, Linux) green
-   r-source patch submitted to r-devel
-   `NEWS` entry and updated man pages
-   Blog post 2 on R Consortium blog

Together with M1, M2 unlocks future `R CMD Rd2html --backend=typst`
work. The embedded template and binary management are reusable. Anyone,
the author or another contributor, can pick up the HTML backend on this
foundation.

---

### Milestone 3: Rd2md for LLM consumption

**Objective:** Add `R CMD Rdconv -t md`. Deliver a Markdown export of
R help pages, ready for LLM context windows, retrieval-augmented
generation, and documentation Model Context Protocol (MCP) servers.

**Why this matters.** R's documentation system was built for human
readers. The next generation of R users includes LLMs: Claude, Codex,
Qwen Code, Llama, and other coding-assistant models. Markdown is the
universal format for feeding documentation to these models. An
`R CMD Rdconv -t md` path gives every CRAN package a clean Markdown
export of its help pages.

Use cases:
-   Retrieval-Augmented Generation (RAG) over CRAN documentation
-   System-prompt context for coding assistants
-   Training data curation
-   Documentation MCP servers that serve live package help

**Why this is tractable.** The work done on `RdConv2.R` and
`Rd2typst.R` already provides the parsing infrastructure. Adding a
Markdown emitter is a retrofit. The Rd tag set is finite. A complete
Markdown emitter fits in approximately 300 to 400 lines of R.

**Implementation work:**

1.  **`Rd2md.R` converter:** Implement the Markdown emitter. Handle all
    standard Rd tags. Use fenced code blocks for `\preformatted` and
    `\code`. Use GitHub-Flavored Markdown tables for `\tabular`. Use
    definition lists or bold-label paragraphs for `\arguments` and
    `\value`. Pass through `\eqn`/`\deqn` as LaTeX math (compatible
    with MathJax and most LLM tokenizers).
2.  **`R CMD Rdconv -t md`:** Wire the new converter into the toolchain
    via `RdConv2.R`, matching the pattern used for `typst`.
3.  **Test suite:** At least 20 test cases covering the same construct
    categories as the Typst test suite.

**Deliverables:**

-   `Rd2md.R` converter
-   `R CMD Rdconv -t md` wired into the toolchain
-   Test suite (at least 20 cases)
-   Blog post 3 on R Consortium blog

---

### Milestone 4: Rust or C port of the Rd parser/converter (stretch goal)

**Objective:** Rewrite the converter core in a compiled language. Rust
is strongly preferred. C is the fallback for r-source acceptance.

Performance is the goal of this milestone. Performance is achievable.
But the proposal's primary thesis is infrastructure and robustness, not
speed. M4 is therefore positioned as a stretch goal that builds on the
foundation laid by M1 through M3.

**Why.** A compiled core brings faster Rd parsing, better integration
with the Typst Rust crate directly, and eliminates R-side parsing
overhead. It also opens the door to a `typst` Rust crate integration
that could render Typst documents without shelling out to a binary.

**Important caveat.** Rust and Cargo are still under evaluation by
R-core for inclusion in the official R build toolchain. See the open
Bugzilla discussion at
<https://bugs.r-project.org/show_bug.cgi?id=18669>. This milestone
may be implemented as a standalone CRAN package (`rd2typst` or similar)
rather than upstreamed, depending on R-core's stance at the time. The
Milestones 1, 2, and 3 deliverables are unaffected by this concern.
They are pure-R and do not depend on Rust or Cargo.

This milestone is explicitly marked as a **stretch goal**. It is lower
priority and lower cost. It will be pursued only after Milestones 1
through 3 are complete.

**Deliverables:**

-   Working Rust or C port of the Rd converter core
-   Benchmarks comparing R-side vs. compiled-side parsing performance
-   Packaging plan: r-source patch or standalone CRAN package, depending
    on R-core's Rust/Cargo stance
-   Blog post 4 (if completed)

---

### Assumptions

```{=html}
<!--
What assumptions are you making that, if proven false, would invalidate
the project?
-->
```

1.  **Typst feature stability**: The Typst features required for R
    documentation rendering have already landed and are unlikely to
    change for the foreseeable future. The Typst project has signaled
    its intent to avoid breaking changes (see
    <https://laurmaedje.github.io/posts/evolving-typst/>), though no
    formal stability promise is possible at this stage. We accept this
    as a calculated risk.
2.  **R-core engagement:** Milestone 2 depends on R-core willingness to
    review and ultimately merge the patch. We will engage early (start
    of Month 3) to surface any concerns before final implementation.
3.  **CRAN policy:** We assume CRAN will accept packages whose PDF
    manuals are generated by the Typst backend, provided output quality
    is comparable to the LaTeX backend. We will verify this with CRAN
    maintainers during Milestone 2.

If any assumption proves false, we will communicate with the ISC
immediately and adjust scope or timeline accordingly, prioritizing
the highest-value deliverables.

### External dependencies

```{=html}
<!--
What external dependencies does the project have (e.g. libraries,
services, other projects, etc.)?
-->
```

No new CRAN dependencies are introduced for the core implementation.
All work happens inside base R's `tools` package. Runtime dependency:
the `typst` binary (Apache-2.0 licensed), obtained from the system PATH
or downloaded on demand. Testing dependencies: a sample of CRAN packages
used for validation (no new package imports required).

## Technical concerns

Rust and Cargo are still under evaluation by R-core for inclusion in
the official R build toolchain. The trajectory for Rust in the broader
Linux ecosystem is clear: Rust adoption is ongoing at the kernel level,
in coreutils replacements, in sudo-rs, and in systemd components. The
open R Bugzilla discussion is at
<https://bugs.r-project.org/show_bug.cgi?id=18669>.

This concern affects only Milestone 4 (the Rust/C port). Milestones 1,
2, and 3 are pure-R and unaffected. If R-core declines Rust at the time
of upstream, Milestone 4 ships as a standalone CRAN package instead.

## Failure modes and recovery

1.  **Typst syntax changes:** Typst releases a breaking change.
    Recovery: pin to a tested Typst version; update when stable.
2.  **Math translation complexity:** Converting LaTeX math to Typst math
    proves intractable for general Rd.
    Recovery: ship a `\if{typst}{...}` opt-in convention. Document LaTeX
    math as a known limitation. Provide a passthrough mode.
3.  **R-core does not merge:** Patch is deferred or rejected.
    Recovery: ship as a standalone CRAN package (`rd2typst`) that patches
    `tools::Rd2pdf` at load time, similar to how `tinytex` augments the
    LaTeX path. The functional value is delivered regardless.
4.  **Milestone 4 Rust rejected by R-core:** Ship as a standalone CRAN
    package instead of an r-source patch.
5.  **Timeline slippage:** Milestones 1 to 2 exceed budget.
    Recovery: Milestone 3 and Milestone 4 are independent and can be
    deferred. Milestones 1 and 2 deliver the core technical value.

Across all failure modes, one outcome is guaranteed: shipping Rd2typst
as a standalone CRAN package. The package form delivers value to R users
regardless of whether the r-source patch is accepted. The patch path is
the preferred route, but it is not the only route to delivery.


# Project plan

## Start-up phase

The `Rd2typst` project has a substantial head-start: a working
converter, a test suite, a benchmark harness, and a fork of r-source
already exist. The start-up phase is minimal.

**Existing infrastructure:**

-   Working `Rd2typst()` converter (700 lines, r-source fork). All 14
    base packages compile end-to-end.
-   `R CMD Rdconv -t typst` and `R CMD Rd2pdf --backend=typst` wired
    through the toolchain.
-   `typst_compile()` wrapper utility in `utils.R`.
-   Shared `RdConv2.R` parsing layer with `"typst"` registered as an
    Rd conditional format.
-   21-case unit test suite (smoke test on all base Rd pages plus
    structural, inline, list, table, link, conditional, escaping, and
    dots cases).
-   Benchmark harness measuring 1.9x end-to-end speedup over `pdflatex`
    across 257 help pages.
-   Phase A man pages (`Rd2HTML.Rd`, `typst_compile.Rd`, `RdUtils.Rd`).
-   GitHub repository for the proposal.

**No setup needed for:**

-   Collaboration platform (GitHub already in use)
-   License (GPL-2 consistent with r-source)
-   Reporting framework (quarterly blog posts to R Consortium)

**Initial work (Week 1):**

-   Confirm Typst version to target (currently at least 0.11)
-   Set up the Milestone 1 validation pipeline: the corpus is the full Comprehensive R Archive Network (CRAN) package set, not a sample.
-   Open r-devel discussion thread to gauge R-core interest early

The project can begin immediately upon funding approval.

## Technical delivery

All implementation work targets `src/library/tools/R/` in r-source (and
the proposal's r-source fork). Development follows R's established
contribution patterns:

1.  Feature branches with test coverage
2.  Self-review plus community feedback via GitHub
3.  Merge to proposal fork and prepare r-source patch
4.  Test with a CRAN package corpus on Windows, macOS, and Linux
5.  Submit patch to R-core; announce on r-devel mailing list

The overall project targets a **6 to 12 month duration** from funding
approval to final milestone delivery.

---

**Milestone 1: CRAN-wide validation**

-   **Months:** 1 to 3
-   **Cost:** \$2,500
-   **Work:** CRAN-wide validation run and triage (approximately 3
    weeks), bug fixes for failures found (approximately 2 weeks), math
    rendering improvements for `\eqn`/`\deqn` (approximately 2 weeks),
    `.pkg2typst()` document assembler with table of contents and index
    (approximately 2 weeks), S4/R5 method documentation verification
    (approximately 1 week), expanded test suite to at least 50 cases
    (approximately 1 week), updated benchmark report
    (approximately 1 week).
-   **Payment trigger:** CRAN-wide validation run completed and bug
    fixes merged. Test suite at 50+ cases. Blog post 1 submitted to
    R Consortium.

---

**Milestone 2: Production integration: Rd2typst in `R CMD Rd2pdf`, embedded in r-source**

-   **Months:** 3 to 6
-   **Cost:** \$2,500
-   **Work:** Implement `typst_binary()` with PATH lookup, vendored
    binary support, and opt-in auto-download (approximately 2 weeks).
    Design and implement `Rd.typ` stylesheet (approximately 2 weeks).
    Bundle Inconsolata and any required Typst packages into
    `share/typst/` (approximately 1 week). Verify TeX-Live-free
    operation on minimal Docker images (approximately 1 week).
    Cross-platform Continuous Integration (CI) matrix (approximately 1 week). Produce clean
    r-source patch against r-devel including `NEWS` and `man` updates
    (approximately 2 weeks). R-core engagement and feedback integration
    (approximately 2 weeks). Blog post 2 (approximately 0.5 weeks).
-   **Payment trigger:** `R CMD Rd2pdf --backend=typst` produces a valid
    PDF on Windows, macOS, and Linux without a TeX Live installation.
    CI green. r-source patch submitted to r-devel or Bugzilla. Blog post
    2 submitted.

---

**Milestone 3: Rd2md for LLM consumption**

-   **Months:** 6 to 9
-   **Cost:** \$1,250
-   **Work:** Implement `Rd2md.R` Markdown emitter (approximately 2
    weeks). Wire `R CMD Rdconv -t md` through `RdConv2.R`
    (approximately 1 week). Write test suite of at least 20 cases
    (approximately 1 week). LLM context-window validation pass
    (approximately 0.5 weeks). Blog post 3 (approximately 0.5 weeks).
-   **Payment trigger:** `R CMD Rdconv -t md` produces valid Markdown
    for all base R packages. Test suite green. Blog post 3 submitted.

---

**Milestone 4: Rust or C port of the Rd converter (stretch goal)**

-   **Months:** 9 to 12 (if scope allows)
-   **Cost:** \$750
-   **Work:** Design the compiled-language interface (approximately 1
    week). Implement the Rust port of the Rd parser and converter core
    (approximately 4 weeks). Benchmark compiled vs. R-side performance
    (approximately 1 week). Produce packaging plan: r-source patch or
    standalone CRAN package (approximately 1 week). Blog post 4
    (approximately 0.5 weeks).
-   **Payment trigger:** Working port compiles the base R package corpus
    with equivalent output to the R implementation. Benchmarks
    published. Packaging plan documented.

---

## Other aspects

### Open source and accessibility

-   **License:** GPL-2 (consistent with r-source; proposal repo under
    CC-BY 4.0)
-   **Repository:** The Rd2typst implementation lives in an r-source
    fork. The r-source patch will be prepared from that fork and
    submitted to r-devel.
-   **Typst binary:** Apache-2.0 license; distributed by the Typst
    project at <https://github.com/typst/typst/releases>
-   **Standalone fallback:** If upstream integration is delayed, the
    converter will be published as a CRAN package so R users can benefit
    immediately

### Community engagement and publicity

**Blog posts on R Consortium blog:**

1.  **Month 3:** "Rd2typst: CRAN-wide validation results and what we
    found." Introduces the converter, shows CRAN pass-rate results,
    invites testing.
2.  **Month 6:** "Rd2pdf gets a Typst backend: self-contained, no LaTeX
    required." Demonstrates the `--backend=typst` flag, embedded
    template, and setup instructions.
3.  **Month 9:** "Rd2md: Markdown help pages for LLMs and RAG
    pipelines." Introduces the Markdown emitter and use cases.
4.  **Month 12 (if M4 complete):** "Rd2typst in Rust: a compiled core
    for R's documentation pipeline."

**Additional channels:**

-   Social media announcements (Mastodon, Bluesky, LinkedIn) at each
    milestone
-   Presentation at useR! 2026 or posit::conf 2026 (if timing aligns)
-   Post to r-devel mailing list at Milestone 2 and Milestone 3
-   Engagement with R developers whose packages currently fail
    `R CMD check` due to LaTeX issues

## Budget and funding plan

**Total funding requested: \$7,000**

All funding will be allocated to labor costs for development by Mossa
Merhi Reimert. No indirect costs, travel, or hardware are included.

**Milestone 1: CRAN-wide validation: \$2,500**

-   **Deliverables:** Updated `Rd2typst.R` with CRAN validation fixes.
    `.pkg2typst()` assembler. Expanded test suite (at least 50 cases).
    Updated benchmark report. Blog post 1.
-   **Payment trigger:** CRAN-wide validation run completed and fixes
    merged. Test suite at 50+ cases. Blog post 1 submitted to
    R Consortium.

**Milestone 2: Production integration: Rd2typst in `R CMD Rd2pdf`, embedded in r-source: \$2,500**

-   **Deliverables:** `typst_binary()` with binary management.
    `Rd.typ` stylesheet. Embedded fonts and Typst packages in
    `share/typst/`. TeX-Live-free operation verified. CI matrix
    (Windows, macOS, Linux). r-source patch submitted to r-devel.
    `NEWS` and `man` updates. Blog post 2.
-   **Payment trigger:** `R CMD Rd2pdf --backend=typst` produces a
    CRAN-clean PDF on Windows, macOS, and Linux without TeX Live. CI
    green. Patch submitted. Blog post 2 submitted.

**Milestone 3: Rd2md for LLM consumption: \$1,250**

-   **Deliverables:** `Rd2md.R` converter. `R CMD Rdconv -t md` wired
    into the toolchain. Test suite (at least 20 cases). Blog post 3.
-   **Payment trigger:** `R CMD Rdconv -t md` works for all base R
    packages. Test suite green. Blog post 3 submitted.

**Milestone 4: Rust or C port (stretch goal): \$750**

-   **Deliverables:** Working compiled port. Benchmarks. Packaging plan
    (r-source patch or CRAN package). Blog post 4.
-   **Payment trigger:** Port produces equivalent output to the R
    implementation for the base R corpus. Benchmarks published.


# Success

```{=html}
<!--
Projects should have a definition of done that is measurable, and a
thorough understanding going in of what the risks are to delivery
-->
```

## Definition of done

```{=html}
<!--
What does success look like?
-->
```

The project will be considered complete when all milestones deliver the
following concrete, measurable outcomes.

### Milestone 1: CRAN-wide validation

**Technical deliverables:**

-   `Rd2typst()` continues to produce valid, compilable Typst markup
    for all 14 base R packages (regression-tested baseline: all 14
    already compile in the current implementation)
-   `Rd2typst()` produces valid output for at least 95% of Comprehensive R Archive Network (CRAN)
    packages (remaining failures documented as known limitations)
-   `.pkg2typst()` assembler produces a complete `.typ` document with
    table of contents and alphabetical index
-   `\eqn` and `\deqn` render in Typst math mode for common LaTeX math
    constructs (superscripts, subscripts, Greek letters, fractions,
    `\sum`, `\prod`)
-   All 21 existing test cases continue to pass; at least 50 total test
    cases

**Documentation:**

-   Updated benchmark extending the existing 257-page, 1.9x-faster
    baseline to the full CRAN corpus

### Milestone 2: Production-ready `R CMD Rd2pdf --backend=typst` + r-source upstream

**Technical deliverables:**

-   `R CMD Rd2pdf --backend=typst` produces a PDF manual on Windows
    (R at least 4.4), macOS (arm64 and x86-64), and Linux (Ubuntu 22.04
    and 24.04) without requiring a TeX Live installation
-   `typst_binary()` locates the binary from PATH, an `R_TYPST_BIN`
    vendored path, or a user cache. Opt-in download works on all three
    platforms.
-   Self-contained font and Typst-package handling (no `--font-path` to
    TeX Live). Verified on a TeX-Live-free Docker image.
-   `Rd.typ` stylesheet produces output visually comparable to the
    LaTeX `Rd.sty` stylesheet: correct heading hierarchy, monospace
    code, argument definition lists, page headers, and index
-   At least 5 CRAN packages (covering a range of sizes and Rd
    complexity) produce equivalent page counts (within 10%) between the
    LaTeX and Typst backends
-   Continuous Integration (CI) matrix (GitHub Actions) runs both backends on Windows, macOS,
    and Linux for the test package corpus and remains green
-   r-source patch submitted to r-devel or R Bugzilla

**Documentation:**

-   Updated `man/Rd2pdf.Rd` describing the `--backend` argument
-   `NEWS` entry for the new option
-   Blog post 2 published on R Consortium blog

### Milestone 3: Rd2md for LLM consumption

**Technical deliverables:**

-   `Rd2md()` converter produces valid Markdown for all 14 base R
    packages
-   `R CMD Rdconv -t md` wired through `RdConv2.R`
-   At least 20 test cases

**Documentation:**

-   Blog post 3 published on R Consortium blog

### Milestone 4: Rust or C port (stretch goal)

-   Working port produces output equivalent to the R implementation for
    the base R corpus
-   Benchmarks showing compiled vs. R-side parsing performance
-   Packaging plan documented: r-source patch or standalone CRAN
    package, depending on R-core's Rust/Cargo stance at the time

### Overall project completion

The project will be considered complete when:

-   `Rd2typst()` is feature-complete and well-tested against the full
    CRAN corpus
-   `R CMD Rd2pdf --backend=typst` works on all three major platforms
    without a TeX Live or MiKTeX installation, with an embedded
    self-contained template
-   An r-source patch has been submitted for R-core review
-   `R CMD Rdconv -t md` is implemented and tested
-   Community outreach has been completed (blog posts, announcement,
    talk)

## Measuring success

| Metric                               | Target                | Measurement                              |
|--------------------------------------|----------------------|------------------------------------------|
| All 14 base R packages compile       | 0 errors             | Already met; CI guard                    |
| CRAN-wide pass rate                  | at least 95%         | Automated CRAN validation run            |
| Test cases (Rd2typst)                | at least 50          | Test file                                |
| Platform support                     | Win / macOS / Linux  | CI matrix                                |
| Embedded template self-contained     | Works on TeX-Live-free Docker image | CI on minimal images      |
| CRAN packages validated end-to-end   | at least 5           | Validation report                        |
| End-to-end speedup vs. LaTeX         | at least 1.9x        | Benchmark report (baseline already met)  |
| Rd2md base R coverage                | All 14 packages      | Test file                                |
| Blog posts                           | 3 (4 if M4 complete) | R Consortium blog                        |
| r-source patch submitted             | Yes                  | r-devel post or Bugzilla ticket          |
| Rust/C port completed                | Optional             | Completed if scope allows                |

## Future work

This project lays the groundwork for further improvements to R's
documentation toolchain.

**Short-term extensions (community-driven):**

-   **Typst package ecosystem:** Once the baseline is established, the
    `Rd.typ` stylesheet can be published as a Typst package, allowing
    package authors to customize their PDF documentation with Typst's
    theme system.
-   **Math improvements:** A LaTeX-to-Typst math transpiler (or use of
    an existing tool such as pandoc) could improve math rendering for
    packages that use complex LaTeX math in `\eqn`/`\deqn`.
-   **Full-fledged HTML output for R documentation.** Typst's HTML
    support is currently experimental. As it matures,
    `R CMD Rd2html --backend=typst` becomes feasible. The result is HTML
    help pages with native equation typesetting, native bibliography
    rendering, and a single unified template across PDF and HTML output.
    Milestones 1 and 2 of the present proposal are the necessary
    infrastructure to make this future work possible. The R community
    pioneered reproducible scientific writing through Sweave, knitr,
    R Markdown, and Quarto. A Typst-based HTML backend for R help pages
    is the next step.

**Medium-term opportunities (potential future grants):**

-   **Default backend switch:** If the Typst backend achieves full
    parity with LaTeX output and R-core is satisfied, a proposal to make
    `--backend=typst` the default could substantially reduce the
    dependency burden for the R ecosystem.
-   **Vignette rendering:** Extending the Typst path to vignettes would
    further reduce the LaTeX dependency surface.
-   **R on minimal platforms:** Removing the hard LaTeX dependency from
    `R CMD check` would make it practical to run full CRAN checks in
    environments like AWS Lambda, GitHub Codespaces free tier, and
    minimal container images.

**Long-term vision.** The ultimate goal is for R's documentation
toolchain to be fast, dependency-light, and accessible to developers on
any platform without a multi-GB TeX installation. This project takes a
focused, pragmatic step toward that goal.

### Community contributions

The `rd2typst` CRAN package will be published under the MIT license,
so any community member can inherit, fork, fold into their own
package, or otherwise build on this work without friction. Code that
lands in r-source follows R's standard GPL-2 license. Either way, the
implementation is openly available: any R developer can use and
improve the Typst backend, the work is not locked to a single
maintainer or organization, and the patch path and the CRAN-package
path both produce a permanent open-source artifact for the community.


# Acknowledgements

This proposal builds on a growing body of community work using Typst
with R. The author thanks the following contributors whose work has
informed and inspired this project.

**Kenneth Blake Vernon** (<https://www.kbvernon.io/>) for his ISC
proposal on community-focused development for scientific computing
with Rust and R at <https://github.com/kbvernon/isc-rextendr-proposal>.
That proposal has shaped thinking about how ISC grants and developer
tooling for R and Rust fit together.

**Joseph Barbier** (<https://barbierjoseph.com/>) for the
[`r2typ`](https://github.com/y-sunflower/r2typ) R package, a Typst
runner for R, and for cultivating a Typst-users-in-R community at
<https://y-sunflower.github.io/r2typ/>. r2typ demonstrates the
practical viability of Typst-based R workflows. It is direct
inspiration for taking the integration further into R's documentation
system.

**Baptiste Auguié** for
[`gridcetz`](https://baptiste.codeberg.page/gridcetz/), an early
effort to build a Typst-backed graphics device for R. gridcetz shows
the direction R and Typst can grow in beyond documentation rendering.


# References
::: refs
:::
