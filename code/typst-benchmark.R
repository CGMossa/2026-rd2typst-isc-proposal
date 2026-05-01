# Benchmark: Rd -> PDF pipeline, step-by-step timing
# Compares LaTeX vs Typst backends

library(tools)

cat("=== R Documentation Pipeline Benchmark ===\n")
cat("Date:", format(Sys.time()), "\n")
cat("R version:", R.version.string, "\n")
cat("typst:", system("typst --version", intern=TRUE), "\n")
cat("pdflatex:", system("pdflatex --version 2>/dev/null | head -1", intern=TRUE), "\n")
cat("Platform:", R.version$platform, "\n\n")
flush.console()

src_base <- "/Users/elea/Documents/GitHub/rrly/src/library"
test_pkgs <- c("splines", "grDevices", "graphics", "grid")

results <- list()

for (pkg in test_pkgs) {
  cat("========================================\n")
  cat("Package:", pkg, "\n")
  cat("========================================\n")
  flush.console()

  pkg_src <- file.path(src_base, pkg)
  man_dir <- file.path(pkg_src, "man")
  rd_files <- list.files(man_dir, "\\.Rd$", full.names = TRUE)
  n_pages <- length(rd_files)
  cat("  Rd pages:", n_pages, "\n\n")
  flush.console()

  # ---- STEP 1: Parse ----
  cat("  [1] Parse .Rd files...\n"); flush.console()
  t1 <- proc.time()
  parsed_rds <- list()
  for (f in rd_files) {
    rd <- tryCatch(
      tools::parse_Rd(f, macros = file.path(R.home("share"), "Rd", "macros", "system.Rd")),
      error = function(e) NULL)
    if (!is.null(rd)) parsed_rds[[basename(f)]] <- rd
  }
  t_parse <- (proc.time() - t1)[3]
  n_ok <- length(parsed_rds)
  cat(sprintf("      %.3fs (%d/%d pages, %.1f ms/page)\n",
      t_parse, n_ok, n_pages, 1000*t_parse/n_ok))
  flush.console()

  # ---- STEP 2a: Convert Rd -> LaTeX ----
  cat("  [2a] Rd -> LaTeX...\n"); flush.console()
  tex_dir <- tempfile("tex")
  dir.create(tex_dir)
  t2a <- proc.time()
  for (nm in names(parsed_rds)) {
    outf <- file.path(tex_dir, sub("\\.Rd$", ".tex", nm))
    tryCatch(tools::Rd2latex(parsed_rds[[nm]], outf, defines = .Platform$OS.type),
             error = function(e) NULL)
  }
  t_conv_latex <- (proc.time() - t2a)[3]
  cat(sprintf("      %.3fs (%.1f ms/page)\n", t_conv_latex, 1000*t_conv_latex/n_ok))
  flush.console()

  # ---- STEP 2b: Convert Rd -> Typst ----
  cat("  [2b] Rd -> Typst...\n"); flush.console()
  typ_dir <- tempfile("typ")
  dir.create(typ_dir)
  t2b <- proc.time()
  for (nm in names(parsed_rds)) {
    outf <- file.path(typ_dir, sub("\\.Rd$", ".typ", nm))
    tryCatch(tools::Rd2typst(parsed_rds[[nm]], outf, defines = .Platform$OS.type),
             error = function(e) NULL)
  }
  t_conv_typst <- (proc.time() - t2b)[3]
  cat(sprintf("      %.3fs (%.1f ms/page)\n", t_conv_typst, 1000*t_conv_typst/n_ok))
  flush.console()

  # ---- STEP 3a: Full pipeline LaTeX ----
  cat("  [3a] Full pipeline: R CMD Rd2pdf --backend=latex...\n"); flush.console()
  latex_pdf <- tempfile(fileext = ".pdf")
  t3a <- proc.time()
  t_full_latex <- NA; latex_ok <- FALSE; latex_size <- NA
  tryCatch({
    tools:::..Rd2pdf(
      args = c("--batch", "--no-preview", "--no-clean",
               paste0("--output=", latex_pdf),
               "--backend=latex", pkg_src),
      quit = FALSE)
    t_full_latex <- (proc.time() - t3a)[3]
    latex_ok <- file.exists(latex_pdf) && file.size(latex_pdf) > 0
    latex_size <- if(latex_ok) file.size(latex_pdf) else NA
    cat(sprintf("      %.3fs [%s]\n", t_full_latex,
        if(latex_ok) paste0("OK, ", round(latex_size/1024), "KB") else "FAILED"))
    flush.console()
  }, error = function(e) {
    t_full_latex <<- (proc.time() - t3a)[3]
    cat(sprintf("      %.3fs [ERROR]\n", t_full_latex)); flush.console()
  })

  # ---- STEP 3b: Full pipeline Typst ----
  cat("  [3b] Full pipeline: R CMD Rd2pdf --backend=typst...\n"); flush.console()
  typst_pdf <- tempfile(fileext = ".pdf")
  t3b <- proc.time()
  t_full_typst <- NA; typst_ok <- FALSE; typst_size <- NA
  tryCatch({
    tools:::..Rd2pdf(
      args = c("--batch", "--no-preview", "--no-clean",
               paste0("--output=", typst_pdf),
               "--backend=typst", pkg_src),
      quit = FALSE)
    t_full_typst <- (proc.time() - t3b)[3]
    typst_ok <- file.exists(typst_pdf) && file.size(typst_pdf) > 0
    typst_size <- if(typst_ok) file.size(typst_pdf) else NA
    cat(sprintf("      %.3fs [%s]\n", t_full_typst,
        if(typst_ok) paste0("OK, ", round(typst_size/1024), "KB") else "FAILED"))
    flush.console()
  }, error = function(e) {
    t_full_typst <<- (proc.time() - t3b)[3]
    cat(sprintf("      %.3fs [ERROR]\n", t_full_typst)); flush.console()
  })

  # ---- STEP 4: Isolated compile-only ----
  # Generate the typst doc, then time only the typst compile step
  cat("  [4a] Typst compile-only...\n"); flush.console()
  typst_comp_dir <- tempfile("typst_comp")
  dir.create(typst_comp_dir)
  t_compile_typst <- NA; typst_comp_size <- NA
  tryCatch({
    tools:::.pkg2typst(pkg_src, file.path(typst_comp_dir, "Rd2.typ"))
    typ_file <- file.path(typst_comp_dir, "Rd2.typ")
    typst_out <- file.path(typst_comp_dir, "Rd2.pdf")
    t4a <- proc.time()
    system2("typst", c("compile", shQuote(typ_file), shQuote(typst_out)),
            stdout = FALSE, stderr = FALSE)
    t_compile_typst <- (proc.time() - t4a)[3]
    typst_comp_size <- if(file.exists(typst_out)) file.size(typst_out) else NA
    cat(sprintf("      %.3fs [%s]\n", t_compile_typst,
        if(!is.na(typst_comp_size)) paste0("OK, ", round(typst_comp_size/1024), "KB") else "FAILED"))
    flush.console()
  }, error = function(e) {
    cat(sprintf("      Error: %s\n", conditionMessage(e))); flush.console()
  })

  # Generate the latex doc, then time only pdflatex compile step (2 passes + makeindex)
  cat("  [4b] LaTeX compile-only (pdflatex 2x + makeindex)...\n"); flush.console()
  latex_comp_dir <- tempfile("latex_comp")
  dir.create(latex_comp_dir)
  t_compile_latex <- NA; latex_comp_size <- NA
  tryCatch({
    old_wd <- getwd()
    setwd(latex_comp_dir)
    # Build a complete LaTeX document (preamble + body + footer)
    texfile <- file.path(latex_comp_dir, "Rd2.tex")
    out <- file(texfile, "w")
    writeLines(c(
      "\\nonstopmode{}",
      "\\documentclass[a4paper]{book}",
      paste0("\\usepackage[", Sys.getenv("R_RD4PDF", "times,inconsolata,hyper"), "]{Rd}"),
      "\\usepackage{makeidx}",
      "\\makeatletter\\@ifl@t@r\\fmtversion{2018/04/01}{}{\\usepackage[utf8]{inputenc}}\\makeatother",
      "\\makeindex{}",
      "\\begin{document}",
      paste0("\\chapter*{}\\begin{center}{\\textbf{\\huge Package `", pkg, "'}}\\end{center}"),
      "\\Rdcontents{Contents}"
    ), out)
    close(out)
    tools:::.Rdfiles2tex(man_dir, texfile, encoding = "UTF-8",
                         outputEncoding = "UTF-8", append = TRUE,
                         internals = FALSE, silent = TRUE)
    cat("\\printindex{}\\n\\end{document}\n",
        file = texfile, append = TRUE)
    # Set TEXINPUTS so pdflatex can find Rd.sty
    old_texinputs <- Sys.getenv("TEXINPUTS", unset = NA)
    Sys.setenv(TEXINPUTS = paste0(file.path(R.home("share"), "texmf", "tex", "latex"),
                                  ":", if(!is.na(old_texinputs)) old_texinputs else ""))
    t4b <- proc.time()
    system2("pdflatex", c("-interaction=nonstopmode", "Rd2.tex"),
            stdout = FALSE, stderr = FALSE)
    if (file.exists("Rd2.idx"))
      system2("makeindex", "Rd2", stdout = FALSE, stderr = FALSE)
    system2("pdflatex", c("-interaction=nonstopmode", "Rd2.tex"),
            stdout = FALSE, stderr = FALSE)
    if (!is.na(old_texinputs)) Sys.setenv(TEXINPUTS = old_texinputs)
    else Sys.unsetenv("TEXINPUTS")
    t_compile_latex <- (proc.time() - t4b)[3]
    latex_comp_size <- if(file.exists("Rd2.pdf")) file.size("Rd2.pdf") else NA
    cat(sprintf("      %.3fs [%s]\n", t_compile_latex,
        if(!is.na(latex_comp_size)) paste0("OK, ", round(latex_comp_size/1024), "KB") else "FAILED"))
    flush.console()
    setwd(old_wd)
  }, error = function(e) {
    cat(sprintf("      Error: %s\n", conditionMessage(e))); flush.console()
    try(setwd(old_wd), silent = TRUE)
  })

  results[[pkg]] <- list(
    pages = n_ok,
    t_parse = t_parse,
    t_conv_latex = t_conv_latex,
    t_conv_typst = t_conv_typst,
    t_compile_latex = t_compile_latex,
    t_compile_typst = t_compile_typst,
    t_full_latex = t_full_latex,
    t_full_typst = t_full_typst,
    latex_ok = latex_ok,
    typst_ok = typst_ok,
    latex_size = latex_size,
    typst_size = typst_size,
    latex_comp_size = latex_comp_size,
    typst_comp_size = typst_comp_size
  )

  # Cleanup
  unlink(c(tex_dir, typ_dir, typst_comp_dir, latex_comp_dir), recursive = TRUE)
  if(file.exists(latex_pdf)) unlink(latex_pdf)
  if(file.exists(typst_pdf)) unlink(typst_pdf)
  rd2pdf_dirs <- list.files("/Users/elea/Documents/GitHub/rrly", "^\\.Rd2pdf",
                            full.names = TRUE)
  if (length(rd2pdf_dirs) > 0) unlink(rd2pdf_dirs, recursive = TRUE)
  cat("\n"); flush.console()
}

# ---- SUMMARY TABLES ----
fmt_time <- function(t) if(!is.na(t)) sprintf("%.3fs", t) else "N/A"
fmt_size <- function(s) if(!is.na(s)) paste0(round(s/1024), "KB") else "N/A"
safe_ratio <- function(a, b) if(!is.na(a) && !is.na(b) && b > 0) a/b else NA
fmt_ratio <- function(r) if(!is.na(r)) sprintf("%.1fx", r) else "N/A"

cat("\n============================================================\n")
cat("SUMMARY\n")
cat("============================================================\n\n")

# Table 1: Conversion only
cat("--- 1. Conversion Only (Rd -> markup, no compilation) ---\n\n")
cat(sprintf("  %-12s %5s  %9s %9s  %7s\n", "Package", "Pages", "Rd2latex", "Rd2typst", "Speedup"))
cat(sprintf("  %s\n", paste0(rep("-", 52), collapse="")))
tot_p <- 0; tot_cl <- 0; tot_ct <- 0
for (pkg in names(results)) {
  r <- results[[pkg]]
  tot_p <- tot_p + r$pages; tot_cl <- tot_cl + r$t_conv_latex; tot_ct <- tot_ct + r$t_conv_typst
  cat(sprintf("  %-12s %5d  %8.3fs %8.3fs  %6s\n", pkg, r$pages,
      r$t_conv_latex, r$t_conv_typst, fmt_ratio(safe_ratio(r$t_conv_latex, r$t_conv_typst))))
}
cat(sprintf("  %s\n", paste0(rep("-", 52), collapse="")))
cat(sprintf("  %-12s %5d  %8.3fs %8.3fs  %6s\n\n", "TOTAL", tot_p,
    tot_cl, tot_ct, fmt_ratio(safe_ratio(tot_cl, tot_ct))))

# Table 2: Compilation only
cat("--- 2. Compilation Only (pre-generated markup -> PDF) ---\n")
cat("    Note: pdflatex runs 2 passes + makeindex; typst runs 1 pass\n\n")
cat(sprintf("  %-12s %5s  %12s %9s  %7s  %6s %6s\n",
    "Package", "Pages", "pdflatex(2x)", "typst", "Speedup", "PDF-L", "PDF-T"))
cat(sprintf("  %s\n", paste0(rep("-", 66), collapse="")))
tot_comp_l <- 0; tot_comp_t <- 0
for (pkg in names(results)) {
  r <- results[[pkg]]
  cl <- if(!is.na(r$t_compile_latex)) r$t_compile_latex else 0
  ct <- if(!is.na(r$t_compile_typst)) r$t_compile_typst else 0
  tot_comp_l <- tot_comp_l + cl; tot_comp_t <- tot_comp_t + ct
  cat(sprintf("  %-12s %5d  %11s %8s  %6s  %5s %5s\n", pkg, r$pages,
      fmt_time(r$t_compile_latex), fmt_time(r$t_compile_typst),
      fmt_ratio(safe_ratio(r$t_compile_latex, r$t_compile_typst)),
      fmt_size(r$latex_comp_size), fmt_size(r$typst_comp_size)))
}
cat(sprintf("  %s\n", paste0(rep("-", 66), collapse="")))
cat(sprintf("  %-12s %5d  %11s %8s  %6s\n\n", "TOTAL", tot_p,
    fmt_time(tot_comp_l), fmt_time(tot_comp_t), fmt_ratio(safe_ratio(tot_comp_l, tot_comp_t))))

# Table 3: Full pipeline
cat("--- 3. Full Pipeline (R CMD Rd2pdf equivalent: parse+convert+compile) ---\n\n")
cat(sprintf("  %-12s %5s  %10s %10s  %7s  %6s %6s\n",
    "Package", "Pages", "latex", "typst", "Speedup", "PDF-L", "PDF-T"))
cat(sprintf("  %s\n", paste0(rep("-", 64), collapse="")))
tot_fl <- 0; tot_ft <- 0
for (pkg in names(results)) {
  r <- results[[pkg]]
  fl <- if(!is.na(r$t_full_latex)) r$t_full_latex else 0
  ft <- if(!is.na(r$t_full_typst)) r$t_full_typst else 0
  tot_fl <- tot_fl + fl; tot_ft <- tot_ft + ft
  cat(sprintf("  %-12s %5d  %9s %9s  %6s  %5s %5s\n", pkg, r$pages,
      fmt_time(r$t_full_latex), fmt_time(r$t_full_typst),
      fmt_ratio(safe_ratio(r$t_full_latex, r$t_full_typst)),
      fmt_size(r$latex_size), fmt_size(r$typst_size)))
}
cat(sprintf("  %s\n", paste0(rep("-", 64), collapse="")))
cat(sprintf("  %-12s %5d  %9s %9s  %6s\n\n", "TOTAL", tot_p,
    fmt_time(tot_fl), fmt_time(tot_ft), fmt_ratio(safe_ratio(tot_fl, tot_ft))))

# Where time goes in the full pipeline
cat("--- 4. Time Breakdown (conversion vs compilation) ---\n\n")
cat(sprintf("  %-12s  %9s %9s %5s  |  %9s %9s %5s\n",
    "Package", "ConvLaTeX", "CompLaTeX", "%%Comp", "ConvTypst", "CompTypst", "%%Comp"))
cat(sprintf("  %s\n", paste0(rep("-", 70), collapse="")))
for (pkg in names(results)) {
  r <- results[[pkg]]
  pct_l <- if(!is.na(r$t_compile_latex) && !is.na(r$t_full_latex) && r$t_full_latex > 0)
    100 * r$t_compile_latex / r$t_full_latex else NA
  pct_t <- if(!is.na(r$t_compile_typst) && !is.na(r$t_full_typst) && r$t_full_typst > 0)
    100 * r$t_compile_typst / r$t_full_typst else NA
  cat(sprintf("  %-12s  %8.3fs %8.3fs %4s  |  %8.3fs %8.3fs %4s\n",
      pkg,
      r$t_conv_latex,
      if(!is.na(r$t_compile_latex)) r$t_compile_latex else 0,
      if(!is.na(pct_l)) paste0(round(pct_l), "%") else "N/A",
      r$t_conv_typst,
      if(!is.na(r$t_compile_typst)) r$t_compile_typst else 0,
      if(!is.na(pct_t)) paste0(round(pct_t), "%") else "N/A"))
}

cat("\nSpeedup > 1.0 means Typst is faster\n")

# Save raw results
saveRDS(results, "/tmp/rd_benchmark_results.rds")
cat("\nRaw results saved to /tmp/rd_benchmark_results.rds\n")
