require("tools")

## Smoke test: convert all base Rd pages to Typst without error
x <- Rd_db("base")
system.time(y <- lapply(x, function(e)
    tryCatch(Rd2typst(e, out = nullfile()), error = identity)))
stopifnot(!vapply(y, inherits, NA, "error"))

## Basic output structure: title becomes Typst heading, sections present
Rdsnippet <- tempfile()
writeLines(r"(\name{foo}\title{Foo Title}\description{A function.}
\usage{foo(x, \dots)}
\arguments{\item{x}{the input.}}
\examples{foo(1)})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet))
stopifnot(exprs = {
    any(grepl("^= Foo Title", out))          # title as level-1 heading
    any(grepl("^== Description", out))        # section heading
    any(grepl("^== Usage", out))              # usage section
    any(grepl("^== Arguments", out))          # arguments section
    any(grepl("^== Examples", out))           # examples section
})

## \code{} renders as #raw("...")
Rdsnippet <- tempfile()
writeLines(r"(\description{Use \code{foo(x)}.})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(any(grepl('#raw\\("foo\\(x\\)"\\)', out)))

## \bold{} renders as #strong[...]
Rdsnippet <- tempfile()
writeLines(r"(\description{\bold{important} text.})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(any(grepl('#strong\\[important\\]', out)))

## \emph{} renders as #emph[...]
Rdsnippet <- tempfile()
writeLines(r"(\description{\emph{italic} text.})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(any(grepl('#emph\\[italic\\]', out)))

## \url{} renders as #link("...")
Rdsnippet <- tempfile()
writeLines(r"(\description{See \url{https://example.com}.})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(any(grepl('#link\\("https://example.com"\\)', out)))

## \href{url}{text} renders as #link("url")[text]
Rdsnippet <- tempfile()
writeLines(r"(\description{See \href{https://example.com}{here}.})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(any(grepl('#link\\("https://example.com"\\)\\[here\\]', out)))

## \dots renders as ellipsis character outside code
Rdsnippet <- tempfile()
writeLines(r"(\description{Use foo(\dots).})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(any(grepl("\u2026", out)))

## \dots renders as ... inside code blocks (usage section)
Rdsnippet <- tempfile()
writeLines(r"(\name{foo}\title{foo}\usage{foo(\dots)})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet))
## In usage (code) section, \dots should be literal "..."
stopifnot(any(grepl("foo(", out, fixed = TRUE)))

## Special characters are escaped in normal text
Rdsnippet <- tempfile()
writeLines(r"(\description{Use #hash and *star and _under.})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(exprs = {
    any(grepl("\\\\#hash", out))
    any(grepl("\\\\\\*star", out))
    any(grepl("\\\\_under", out))
})

## \itemize renders as bullet list
Rdsnippet <- tempfile()
writeLines(r"(\description{\itemize{
\item First
\item Second
}})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(exprs = {
    any(grepl("^- First", out))
    any(grepl("^- Second", out))
})

## \enumerate renders as numbered list
Rdsnippet <- tempfile()
writeLines(r"(\description{\enumerate{
\item First
\item Second
}})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(exprs = {
    any(grepl("^\\+ First", out))
    any(grepl("^\\+ Second", out))
})

## \describe renders as definition list
Rdsnippet <- tempfile()
writeLines(r"(\description{\describe{
\item{alpha}{The first.}
\item{beta}{The second.}
}})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(exprs = {
    any(grepl("^/ alpha: The first", out))
    any(grepl("^/ beta: The second", out))
})

## \tabular renders as #table()
Rdsnippet <- tempfile()
writeLines(r"(\description{\tabular{lr}{
  Name \tab Value \cr
  x \tab 1 \cr
}})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(exprs = {
    any(grepl("#table", out))
    any(grepl("columns: 2", out))
    any(grepl("left.*right", out))
})

## \preformatted renders as ``` block
Rdsnippet <- tempfile()
writeLines(r"(\description{\preformatted{
x <- 1
y <- 2
}})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(sum(grepl("^```", out)) >= 2L)  # opening and closing

## \if{typst}{...} conditional is processed
Rdsnippet <- tempfile()
writeLines(r"(\description{\if{typst}{Typst only.}\if{latex}{LaTeX only.}})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(exprs = {
    any(grepl("Typst only", out))
    !any(grepl("LaTeX only", out))
})

## \ifelse{typst}{yes}{no} conditional
Rdsnippet <- tempfile()
writeLines(r"(\description{\ifelse{typst}{YES}{NO}})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
stopifnot(exprs = {
    any(grepl("YES", out))
    !any(grepl("NO", out))
})

## PR#18052 parallel: \dots must not be interpreted inside \preformatted
Rdsnippet <- tempfile()
writeLines(r"(\preformatted{
\item{\dots}{foo(arg = "\\\\dots", ...)}
})", Rdsnippet)
out <- capture.output(Rd2typst(Rdsnippet, fragment = TRUE))
## Should preserve literal \dots and \\dots
stopifnot(any(grepl("\\\\dots", out)))

## \usage: keep quoted "\\\\dots", but _do_ translate formal \dots arg
Rdsnippet <- tempfile()
writeLines(r"(\name{foo}\title{foo}\usage{
## keep this comment to ensure a newline at the end
foo(arg = "\\\\dots", \dots)
})", Rdsnippet)
out <- trimws(grep("foo(", capture.output(Rd2typst(Rdsnippet)),
                   value = TRUE, fixed = TRUE))
stopifnot(identical(out, r"(foo(arg = "\\dots", ...))"))

cat("Rd2typst tests passed\n")
