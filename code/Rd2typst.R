#  File src/library/tools/R/Rd2typst.R
#  Part of the R package, https://www.R-project.org
#
#  Copyright (C) 2026 The R Core Team
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  https://www.R-project.org/Licenses/

### * .Rd_get_typst

# Return typst form of text, encoded in UTF-8.
.Rd_get_typst <-
function(x)
{
    tf <- tempfile()
    save <- options(useFancyQuotes = FALSE)
    on.exit({options(save); unlink(tf)})
    tryCatch(Rd2typst(x, tf, fragment = TRUE, outputEncoding = "UTF-8"),
             error = function(e) return(character()))
    enc2utf8(readLines(tf, warn = FALSE, encoding = "UTF-8"))
}


## 'encoding' is passed to parse_Rd, as the input encoding
Rd2typst <- function(Rd, out = "", defines = .Platform$OS.type,
                     stages = "render",
                     outputEncoding = "UTF-8", fragment = FALSE, ...,
                     concordance = FALSE)
{
    encode_warn <- FALSE
    WriteLines <-
        if(outputEncoding == "UTF-8" ||
           (outputEncoding == "" && l10n_info()[["UTF-8"]])) {
            function(x, con, outputEncoding, ...)
                writeLines(x, con, useBytes = TRUE, ...)
        } else {
            function(x, con, outputEncoding, ...) {
                y <- iconv(x, "UTF-8", outputEncoding,  mark = FALSE)
                if (anyNA(y)) {
                    y <- iconv(x, "UTF-8", outputEncoding,
                               sub = "byte", mark = FALSE)
                    encode_warn <<- TRUE
                }
                writeLines(y, con, useBytes = TRUE, ...)
            }
    }

    conc <- if(concordance) activeConcordance() # else NULL

    last_char <- ""
    skipNewline <- FALSE
    of0 <- function(...) of1(paste0(...))
    of1 <- function(text) {
        if (skipNewline) {
            skipNewline <<- FALSE
            if (text == "\n") return()
        }
    	if (concordance)
    	    conc$addToConcordance(text)
        nc <- nchar(text)
        last_char <<- substr(text, nc, nc)
        WriteLines(text, con, outputEncoding, sep = "")
    }

    trim <- function(x) {
        x <- psub1("^\\s*", "", as.character(x))
        psub1("\\s*$", "", x)
    }

    envTitles <- c("\\description"="Description", "\\usage"="Usage",
        "\\arguments"="Arguments",
        "\\format"="Format", "\\details"="Details", "\\note"="Note",
        "\\section"="", "\\author"="Author",
        "\\references"="References", "\\source"="Source",
        "\\seealso"="See Also", "\\examples"="Examples",
        "\\value"="Value")

    ## Sections rendered in code-block style
    codeSections <- c("\\usage", "\\examples")

    inCodeBlock <- FALSE
    inCode <- FALSE
    inEqn <- FALSE
    inPre <- FALSE
    inDefTerm <- FALSE  ## inside "/ term:" — newlines must be collapsed
    sectionLevel <- 0
    hasFigures <- FALSE

    startByte <- utils:::getSrcByte
    addParaBreaks <- function(x) {
        if (startByte(x) == 1L) psub1("^[[:blank:]]+", "", x)
        else x
    }

    ## Escape Typst markup characters: #, *, _, @, <, >, $, \, `
    ## In code blocks, less escaping is needed (raw blocks handle it).
    typstify <- function(x, code = inCodeBlock) {
        if(inEqn) return(x)
        if (inCode) {
            ## Inside #raw("...") string argument — escape \ and "
            x <- fsub("\\", "\\\\", x)
            x <- fsub("\"", "\\\"", x)
            return(x)
        }
        if (!code && !inPre) {
            ## Escape backslash first, then other special chars
            x <- fsub("\\", "\\\\", x)
            x <- fsub("#", "\\#", x)
            x <- fsub("*", "\\*", x)
            x <- fsub("_", "\\_", x)
            x <- fsub("@", "\\@", x)
            x <- fsub("<", "\\<", x)
            x <- fsub(">", "\\>", x)
            x <- fsub("$", "\\$", x)
            x <- fsub("`", "\\`", x)
            ## Typst uses ~ for non-breaking space
            x <- fsub("~", "\\~", x)
            ## Square brackets delimit content blocks in Typst
            x <- fsub("[", "\\[", x)
            x <- fsub("]", "\\]", x)
        }
        ## Definition list terms (/ term: desc) must be single-line in Typst
        if (inDefTerm) x <- gsub("\n", " ", x, fixed = TRUE)
        x
    }

    wrappers <- list("\\dQuote" = c("\u201c", "\u201d"),
                     "\\sQuote" = c("\u2018", "\u2019"),
                     "\\cite"   = c("#emph[", "]"))

    ## Typst function calls like #strong[content] will try to consume
    ## a following (...) as arguments.  Appending ";" terminates the
    ## expression so e.g. #strong[57];(1) is not a function call.
    hashFuncTags <- c("\\bold", "\\strong", "\\emph", "\\dfn",
                      "\\pkg", "\\var", "\\cite")

    ## Tags that use #raw("...") wrapping
    rawTags <- c("\\code", "\\command", "\\env", "\\kbd", "\\option", "\\samp")

    writeWrapped <- function(block, tag) {
        ## When already inside #raw("..."), don't nest code wrappers
        if (inCode && tag %in% rawTags) {
            writeContent(block, tag)
            return()
        }
    	wrapper <- wrappers[[tag]]
    	if (is.null(wrapper)) {
    	    ## Map remaining tags to Typst markup.
    	    ## Use #strong[] / #emph[] function syntax instead of *...* / _..._
    	    ## because the shorthand breaks when adjacent to non-space chars
    	    ## (e.g., \bold{symm}etrically → *symm*etrically is invalid Typst).
    	    wrapper <- switch(tag,
                "\\bold"    = c("#strong[", "]"),
                "\\strong"  = c("#strong[", "]"),
                "\\emph"    = c("#emph[", "]"),
                "\\dfn"     = c("#emph[", "]"),
                "\\code"    = c('#raw("', '")'),
                "\\command" = c('#raw("', '")'),
                "\\env"     = c('#raw("', '")'),
                "\\kbd"     = c('#raw("', '")'),
                "\\option"  = c('#raw("', '")'),
                "\\samp"    = c('#raw("', '")'),
                "\\file"    = c("\u2018", "\u2019"),
                "\\pkg"     = c("#strong[", "]"),
                "\\var"     = c("#emph[", "]"),
                "\\abbr"    = c("", ""),
                "\\acronym" = c("", ""),
                "\\email"   = c("#link(\"mailto:", "\")"),
                c("", ""))
    	}
    	if (concordance)
    	    conc$saveSrcref(block)
    	of1(wrapper[1L])
    	if (tag %in% rawTags) {
    	    savedInCode <- inCode
    	    inCode <<- TRUE
    	}
    	writeContent(block, tag)
    	if (tag %in% rawTags) inCode <<- savedInCode
    	of1(wrapper[2L])
    	## Terminate #func(...) / #func[...] expressions to prevent
    	## following (x) being parsed as arguments
    	## (e.g. \bold{57}(1) → #strong[57];(1),
    	##       \code{dqrdc2}(*) → #raw("dqrdc2");(\*))
    	if (tag %in% c(hashFuncTags, rawTags, "\\email")) of1(";")
    }

    writeURL <- function(block, tag) {
        if (tag == "\\url") {
            url <- as.character(block)
            url <- lines2str(url)
            if (concordance)
                conc$saveSrcref(block)
            if (inCode) {
                of1(typstify(url))
            } else {
                of0("#link(\"", url, "\");")
            }
        } else {
            ## \href{url}{text}
            url <- as.character(block[[1L]])
            url <- lines2str(url)
            if (concordance)
                conc$saveSrcref(block)
            if (inCode) {
                writeContent(block[[2L]], tag)
            } else {
                of0("#link(\"", url, "\")[")
                if (concordance)
                    conc$saveSrcref(block[[2L]])
                writeContent(block[[2L]], tag)
                of1("];")
            }
        }
    }

    writeLink <- function(tag, block) {
        parts <- get_link(block, tag, Rdfile)
        if (concordance)
            conc$saveSrcref(block)
        ## In Typst, we render links as code-style text using #raw()
        ## Cross-package links are not resolvable here
        if (inCode) {
            ## Already inside #raw("...") — just emit text directly
            if (all(RdTags(block) == "TEXT"))
                of1(typstify(parts$topic))
            else
                writeContent(block, tag)
        } else {
            if (all(RdTags(block) == "TEXT")) {
                txt <- gsub("\\\\", "\\\\\\\\", parts$topic)
                txt <- gsub("\"", "\\\\\"", txt)
                of0('#raw("', txt, '");')
            } else {
                inCode <<- TRUE
                of1('#raw("')
                writeContent(block, tag)
                of1('");')
                inCode <<- FALSE
            }
        }
    }

    writeDR <- function(block, tag) {
    	if (concordance)
    	    conc$saveSrcref(block)
        if (length(block) > 1L) {
            of1('## Not run: ')
            writeContent(block, tag)
            of1('\n## End(Not run)')
        } else {
            of1('## Not run: ')
            writeContent(block, tag)
       }
    }

    typststriptitle <- function(x) x  # Typst needs no special title escaping

    writeBlock <- function(block, tag, blocktag) {
    	if (concordance)
    	    conc$saveSrcref(block)
	switch(tag,
               UNKNOWN =,
               VERB = of1(typstify(block, TRUE)),
               RCODE = of1(typstify(block, TRUE)),
               TEXT = of1(addParaBreaks(typstify(block))),
               USERMACRO =,
               "\\newcommand" =,
               "\\renewcommand" = {},
               COMMENT = if (startByte(block) == 1L ||
                             (!inCodeBlock && last_char == ""))
                             skipNewline <<- TRUE,
               LIST = writeContent(block, tag),
               "\\describe"= {
                   of1("\n")
                   writeContent(block, tag)
                   of1("\n")
               },
               "\\enumerate"={
                   of1("\n")
                   writeContent(block, tag)
                   of1("\n")
               },
               "\\itemize"= {
                   of1("\n")
                   writeContent(block, tag)
                   of1("\n")
               },
               "\\command"=,
               "\\env" =,
               "\\kbd"=,
               "\\option" =,
               "\\samp" = writeWrapped(block, tag),
               "\\url"=,
               "\\href"= writeURL(block, tag),
               "\\code"= {
                   if (inCode) {
                       ## Already inside #raw("...") — no double-wrap
                       writeContent(block, tag)
                   } else {
                       writeWrapped(block, tag)
                   }
               },
               "\\abbr" =,
               "\\acronym" =,
               "\\bold"=,
               "\\dfn"=,
               "\\dQuote"=,
               "\\email"=,
               "\\emph"=,
               "\\file" =,
               "\\pkg" =,
               "\\sQuote" =,
               "\\strong"=,
               "\\var" =,
               "\\cite" =
                   if (inCode || inCodeBlock) writeContent(block, tag)
                   else writeWrapped(block, tag),
               "\\preformatted"= {
                   if (inCode) {
                       writeContent(block, tag)
                   } else {
                       inPre <<- TRUE
                       of1("\n```\n")
                       writeContent(block, tag)
                       of1("\n```\n")
                       inPre <<- FALSE
                   }
               },
               "\\Sexpr"= {
                   of1("\n```\n")
                   of0(as.character.Rd(block, deparse=TRUE))
                   of1("\n```\n")
               },
               "\\verb"= {
                   if (inCode) {
                       writeContent(block, tag)
                   } else {
                       inCode <<- TRUE
                       of1('#raw("')
                       writeContent(block, tag)
                       of1('");')
                       inCode <<- FALSE
                   }
               },
               "\\special"= writeContent(block, tag),
               "\\linkS4class" =,
               "\\link" = writeLink(tag, block),
               "\\cr" = of1("\\\n"),  # Typst line break
               "\\dots" =,
               "\\ldots" = of1(if(inCode || inCodeBlock) "..."  else "\u2026"),
               "\\R" = of1("R"),
               "\\donttest" =, "\\dontdiff" = writeContent(block, tag),
               "\\dontrun"= writeDR(block, tag),
               "\\enc" = {
                   if (outputEncoding == "ASCII")
                       writeContent(block[[2L]], tag)
                   else
                       writeContent(block[[1L]], tag)
               },
               "\\eqn" =,
               "\\deqn" = {
                   ## Rd \eqn{latex}{ascii} — Typst math syntax differs
                   ## from LaTeX, so use ASCII form when available; otherwise
                   ## render the LaTeX source as inline code.
                   if (inCode) {
                       ## Already inside #raw("...") — just emit text
                       if (length(block) > 1L && length(block[[2L]]) > 0L)
                           writeContent(block[[2L]], tag)
                       else
                           writeContent(block[[1L]], tag)
                   } else if (length(block) > 1L && length(block[[2L]]) > 0L) {
                       ## ASCII representation available
                       if (concordance)
                           conc$saveSrcref(block[[2L]])
                       if (tag == "\\deqn") of1("\n\n")
                       inCode <<- TRUE
                       of1(if (tag == "\\deqn") '#raw("' else '#raw("')
                       writeContent(block[[2L]], tag)
                       of1(if (tag == "\\deqn") '", block: true);' else '");')
                       inCode <<- FALSE
                       if (tag == "\\deqn") of1("\n\n")
                   } else {
                       ## LaTeX-only: render as code
                       if (concordance)
                           conc$saveSrcref(block[[1L]])
                       if (tag == "\\deqn") of1("\n\n")
                       inEqn <<- TRUE
                       inCode <<- TRUE
                       of1('#raw("')
                       writeContent(block[[1L]], tag)
                       of1(if (tag == "\\deqn") '", block: true);' else '");')
                       inCode <<- FALSE
                       inEqn <<- FALSE
                       if (tag == "\\deqn") of1("\n\n")
                   }
               },
               "\\figure" = {
               	   if (concordance)
               		conc$saveSrcref(block[[1L]])
                   of0('#image("')
                   writeContent(block[[1L]], tag)
                   of0('"')
                   if (length(block) > 1L) {
                       if (concordance)
                           conc$saveSrcref(block[[2L]])
                       includeoptions <- .Rd_get_typst(block[[2L]])
                       if (length(includeoptions))
                           for (z in includeoptions)
                               if(startsWith(z, "options: "))
                                   of0(", ", sub("^options: ", "", z))
                   }
                   of1(")")
                   hasFigures <<- TRUE
               },
               "\\dontshow" =,
               "\\testonly" = {},
               "\\method" =,
               "\\S3method" =,
               "\\S4method" = {
                   ## should not get here
               },
               "\\tabular" = writeTabular(block),
               "\\subsection" = writeSection(block, tag),
               "\\if" =,
               "\\ifelse" =
		    if (testRdConditional("typst", block, Rdfile))
               		writeContent(block[[2L]], tag)
               	    else if (tag == "\\ifelse")
               	    	writeContent(block[[3L]], tag),
               "\\out" = for (i in seq_along(block)) {
               	   if (concordance)
               		conc$saveSrcref(block[[i]])
		   of1(block[[i]])
		   },
               stopRd(block, Rdfile, "Tag ", tag, " not recognized")
               )
    }

    writeTabular <- function(table) {
    	format <- table[[1L]]
    	content <- table[[2L]]
    	if (length(format) != 1L || RdTags(format) != "TEXT")
    	    stopRd(table, Rdfile, "\\tabular format must be simple text")
        fmt <- as.character(format)
        ncols <- nchar(fmt)
        ## Map lcr format to Typst column alignment
        aligns <- character(ncols)
        for (j in seq_len(ncols)) {
            ch <- substr(fmt, j, j)
            aligns[j] <- switch(ch,
                "l" = "left",
                "c" = "center",
                "r" = "right",
                "left")
        }
        of0("\n#table(\n  columns: ", ncols,
            ",\n  align: (", paste(aligns, collapse = ", "), "),\n")
        if (concordance)
            conc$saveSrcref(table[[1L]])
        tags <- RdTags(content)
        ## Each cell is wrapped in [...] to use content mode inside
        ## the #table() code context so that #raw(), #strong[] etc. work.
        cellOpen <- FALSE
        for (i in seq_along(tags)) {
            if (concordance)
                conc$saveSrcref(content[[i]])
            switch(tags[i],
                   "\\tab" = {
                       if (cellOpen) of1("]")
                       cellOpen <- FALSE
                       of1(", ")
                   },
                   "\\cr" = {
                       if (cellOpen) of1("]")
                       cellOpen <- FALSE
                       of1(",\n")
                   },
                   {
                       if (!cellOpen) { of1("["); cellOpen <- TRUE }
                       writeBlock(content[[i]], tags[i], "\\tabular")
                   })
        }
        if (cellOpen) of1("]")
        of1("\n)\n")
    }

    writeContent <- function(blocks, blocktag) {
        inList <- FALSE
        itemskip <- FALSE

	tags <- RdTags(blocks)

	i <- 0
	while (i < length(tags)) {
	    i <- i + 1
            block <- blocks[[i]]
            tag <- attr(block, "Rd_tag")
            if(!is.null(tag))
            switch(tag,
                   "\\method" =,
                   "\\S3method" =,
                   "\\S4method" = {
                   	blocks <- transformMethod(i, blocks, Rdfile)
                   	tags <- RdTags(blocks)
                   	i <- i - 1
                   },
                   "\\item" = {
                       if (blocktag %in% c("\\value", "\\arguments") && !inList) {
                           inList <- TRUE
                       }
                       switch(blocktag,
                              "\\describe" = {
                              	  if (concordance)
                              	      conc$saveSrcref(block[[1L]])
                                  of1("\n/ ")
                                  inDefTerm <<- TRUE
                                  writeContent(block[[1L]], tag)
                                  inDefTerm <<- FALSE
                                  of1(": ")
                                  if (concordance)
                                      conc$saveSrcref(block[[2L]])
                                  writeContent(block[[2L]], tag)
                              },
                              "\\value"=,
                              "\\arguments"={
                              	  if (concordance)
                              	      conc$saveSrcref(block[[1L]])
                                  of1("\n/ ")
                                  inDefTerm <<- TRUE
                                  inCode <<- TRUE
                                  writeItemAsCode(tag, block[[1L]])
                                  inCode <<- FALSE
                                  inDefTerm <<- FALSE
                                  of1(": ")
                                  if (concordance)
                                      conc$saveSrcref(block[[2L]])
                                  writeContent(block[[2L]], tag)
                              },
                              "\\enumerate" =,
                              "\\itemize"= {
                                  if (blocktag == "\\enumerate")
                                      of1("\n+ ")
                                  else
                                      of1("\n- ")
                                  itemskip <- TRUE
                              })
                       itemskip <- TRUE
                   },
                   "\\cr" = of1("\\\n"),
               { # default
                   if (inList && tag != "COMMENT"
                              && !(tag == "TEXT" && isBlankRd(block))) {
                       inList <- FALSE
                   }
                   if (itemskip) {
                       itemskip <- FALSE
                       if (tag == "TEXT") {
                           txt <- psub("^ ", "", as.character(block))
                           of1(typstify(txt))
                       } else writeBlock(block, tag, blocktag)
                   } else writeBlock(block, tag, blocktag)
               })
	}
    }

    writeSectionInner <- function(section, tag)
    {
        if (length(section)) {
	    nxt <- section[[1L]]
	    if (is.null(nxttag <- attr(nxt, "Rd_tag")))
		return()
	    if (nxttag %notin% c("TEXT", "RCODE") ||
		!startsWith(as.character(nxt), "\n")) of1("\n")
	    writeContent(section, tag)
	    if (last_char != "\n") of1("\n")
	}
    }

    writeSection <- function(section, tag) {
        if (tag == "\\encoding")
            return()
    	if (concordance)
    	    conc$saveSrcref(section)
        save <- sectionLevel
        sectionLevel <<- sectionLevel + 1
        if (tag == "\\alias") {
            ## Typst doesn't have index aliases; emit as label
            alias <- trim(as.character(section))
            if (alias != name)
                of0("// alias: ", alias, "\n")
        }
        else if (tag == "\\keyword") {
            key <- trim(section)
            if(any(key %in% .Rd_keywords_auto))
                return()
            of0("// keyword: ", key, "\n")
        }
        else if (tag == "\\concept") {
            key <- trim(section)
            of0("// concept: ", key, "\n")
        }
        else if (tag == "\\section" || tag == "\\subsection") {
            ## Typst headings: = level1, == level2, === level3
            level <- min(sectionLevel + 1, 4)  # +1 because page title is =
            prefix <- paste(rep("=", level), collapse = "")
    	    of0("\n", prefix, " ")
            writeContent(section[[1L]], tag)
            of1("\n")
    	    writeSectionInner(section[[2L]], tag)
    	} else {
            title <- envTitles[tag]
            level <- min(sectionLevel + 1, 4)
            prefix <- paste(rep("=", level), collapse = "")
            of0("\n", prefix, " ", title, "\n")
            if(tag %in% codeSections) {
                inCodeBlock <<- TRUE
                of1("\n```r\n")
            }
            writeSectionInner(section, tag)
 	    inCodeBlock <<- FALSE
            if(tag %in% codeSections)
                of1("```\n")
        }
        sectionLevel <<- save
    }

    writeItemAsCode <- function(blocktag, block) {
        for(i in which(RdTags(block) == "\\code"))
            attr(block[[i]], "Rd_tag") <- "Rd"

        s <- as.character.Rd(block)
        s[s %in% c("\\dots", "\\ldots")] <- "..."
        s <- trimws(strsplit(paste(s, collapse = ""), ",", fixed = TRUE)[[1]])
        s <- s[nzchar(s)]
        ## Escape \ and " for #raw("...") string syntax
        s <- gsub("\\\\", "\\\\\\\\", s)
        s <- gsub("\"", "\\\\\"", s)
        s <- sprintf('#raw("%s");', s)
        s <- paste0(s, collapse = ", ")
        of1(s)
    }

    Rd <- prepare_Rd(Rd, defines=defines, stages=stages, fragment=fragment, ...)
    Rdfile <- attr(Rd, "Rdfile")
    sections <- RdTags(Rd)

    if (is.character(out)) {
        if(out == "") {
            con <- stdout()
        } else {
	    con <- file(out, "wt")
	    on.exit(close(con))
	}
    } else {
    	con <- out
    	out <- summary(con)$description
    }

    if (fragment) {
    	if (sections[1L] %in% names(sectionOrder))
    	    for (i in seq_along(sections))
    	    	writeSection(Rd[[i]], sections[i])
    	else
    	    for (i in seq_along(sections))
    	    	writeBlock(Rd[[i]], sections[i], "")
    } else {
	nm <- character(length(Rd))
	isAlias <- sections == "\\alias"
	sortorder <- if (any(isAlias)) {
	    nm[isAlias] <- sapply(Rd[isAlias], as.character)
	    order(sectionOrder[sections], toupper(nm), nm)
	} else  order(sectionOrder[sections])
	Rd <- Rd[sortorder]
	sections <- sections[sortorder]

	title <- .Rd_get_typst(.Rd_get_section(Rd, "title"))
	title <- paste(title[nzchar(title)], collapse = " ")

	name <- Rd[[2L]]
	if (concordance)
	    conc$saveSrcref(name)
	name <- trim(as.character(Rd[[2L]][[1L]]))

        ## Typst document header
        of0("= ", title, "\n")
        of0("// name: ", name, "\n")

	for (i in seq_along(sections)[-(1:2)])
	    writeSection(Rd[[i]], sections[i])
    }
    if (encode_warn)
	warnRd(Rd, Rdfile, "Some input could not be re-encoded to ",
	       outputEncoding)
    if (concordance) {
    	conc$srcFile <- Rdfile
        concdata <- followConcordance(conc$finish(), attr(Rd, "concordance"))
        attr(out, "concordance") <- concdata
    }

    invisible(structure(out, hasFigures = hasFigures))
}
