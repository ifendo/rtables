## Rules for pagination
##
## 1. user defined number of lines per page
## 2. all lines have the same height
## 3. header always reprinted on all pages
## 4. "Label-rows", ie content rows above break in the nesting structure, optionaly reprinted (default TRUE)
## 5. Never (?) break on a "label"/content row
## 6. Never (?) break on the second (ie after the first) data row at a particular leaf Elementary table.
##
## Current behavior: paginate_ttree takes a TableTree object and
## returns a list of rtable (S3) objects for printing.







## this is where we will take wordwrapping
## into account when it is added
##
## ALL calculations of vertical space for pagination
## purposes must go through nlines and divider_height!!!!!!!!

## this will be customizable someday. I have foreseen it (spooky noises)
divider_height = function(cinfo) 1L

setGeneric("nlines",
           function(x, colwidths) standardGeneric("nlines"))

setMethod("nlines", "TableRow",
          function(x, colwidths) {
    1L
})

setMethod("nlines", "LabelRow",
          function(x, colwidths) {
    if(labelrow_visible(x))
        1L
    else
        0L
})


setMethod("nlines", "VTableTree",
          function(x, colwidths) {
    length(collect_leaves(x, TRUE, TRUE))
})

setMethod("nlines", "InstantiatedColumnInfo",
          function(x, colwidths) {
    lfs = collect_leaves(coltree(x))
    depths = sapply(lfs, function(l) length(pos_splits(l)))
    max(depths) + divider_height(x)

})

pagdfrow = function(row,
                    nm = obj_name(row),
                    lab = obj_label(row),
                    rnum,
                    pth ,
                    sibpos = NA_integer_,
                    nsibs = NA_integer_,
                    extent = nlines(row, colwidths),
                    colwidths = NULL,
                    repext = 0L,
                    repind = integer(),
                    indent = 0L,
                    rclass = class(row)
                    ) {

    data.frame(label = lab,
               name = nm,
               abs_rownumber = rnum,
               path = I(list(pth)),
               pos_in_siblings = sibpos,
               n_siblings = nsibs,
               self_extent = extent,
               par_extent = repext,
               reprint_inds = I(list(unlist(repind))),
               node_class = rclass,
               indent = max(0L, indent),

               stringsAsFactors = FALSE)
}


col_dfrow = function(col,
                    nm = obj_name(col),
                    lab = obj_label(col),
                    cnum,
                    pth = NULL,
                    sibpos = NA_integer_,
                    nsibs = NA_integer_,
                    leaf_indices = cnum,
                    span = length(leaf_indices)
                    ) {
    if(is.null(pth))
        pth <- pos_to_path(tree_pos(col))
    data.frame(stringsAsFactors = FALSE,
               name = nm,
               label = lab,
               abs_pos = cnum,
               path = I(list(pth)),
               pos_in_siblings = sibpos,
               n_siblings = nsibs,
               leaf_indices = I(list(leaf_indices)),
               total_span = span)
}


pos_to_path <- function(pos) {
    spls <- pos_splits(pos)
    vals <- pos_splvals(pos)

    path <- character()
    for(i in seq_along(spls)) {
        path <- c(path,
                  obj_name(spls[[i]]),
                  rawvalues(vals[[i]]))
    }
    path
}



#' Make row and column layout summary data.frames for use during pagination
#' @inheritParams gen_args
#' @param visible_only logical(1). Should only visible aspects of the table structure be reflected in this summary. Defaults to \code{TRUE}.
#' @param incontent logical(1). Internal detail do not set manually.
#' @param repr_ext integer(1). Internal detail do not set manually.
#' @param repr_inds integer. Internal detail do not set manually.
#' @param sibpos integer(1). Internal detail do not set manually.
#' @param nsibs integer(1). Internal detail do not set manually.
#' @param rownum numeric(1). Internal detail do not set manually.
#' @param indent integer(1). Internal detail do not set manually.

#' @param colwidths numeric. Internal detail do not set manually.
#'
#' @details
#' When \code{visible_only} is \code{TRUE}, the resulting data.frame will have exactly one row per visible row in the table. This is useful when reasoning about how a table will print, but does not reflect the full pathing space of the structure (though the paths which are given will all work as is).
#'
#' When \code{visible_only} is \code{FALSE}, every structural element of the table (in row-space) will be reflected in the returned data.frame, meaning the full pathing-space will be represented but some rows in the layout summary will not represent printed rows in the table as it is displayed.
#'
#' @note the technically present root tree node is excluded from the summary returne dby
#' both \code{make_row_df} and \code{make_col_df}, as it is simply the
#' row/column structure of \code{tt} and thus not useful for pathing or pagination.
#' @export
#' @rdname make_row_df
setGeneric("make_row_df", function(tt, colwidths = NULL, visible_only = TRUE,
                                  rownum = 0,
                                  indent = 0L,
                                  path = character(),
                                  incontent = FALSE,
                                  repr_ext = 0L,
                                  repr_inds = integer(),
                                  sibpos = NA_integer_,
                                  nsibs = NA_integer_) standardGeneric("make_row_df"))

#' @exportMethod make_row_df
#' @rdname make_row_df
setMethod("make_row_df", "VTableTree",
          function(tt, colwidths = NULL, visible_only = TRUE,
                   rownum = 0,
                   indent = 0L,
                   path = character(),
                   incontent = FALSE,
                   repr_ext = 0L,
                   repr_inds = integer(),
                   sibpos = NA_integer_,
                   nsibs = NA_integer_) {

    indent <- indent + indent_mod(tt)
    orig_rownum <- rownum
    if(incontent)
        path <- c(path, "@content")
    else if (length(path) > 0 || nzchar(obj_name(tt))) ## don't add "" for root
        path <- c(path, obj_name(tt))

    ret <- list()
    if(!visible_only) {
        ret <- c(ret,
                 list(pagdfrow(rnum = NA,
                               nm = obj_name(tt),
                               lab = "",
                               pth = path,
                               colwidths = colwidths,
                               repext = repr_ext,
                               repind = list(repr_inds),
                               extent = 0,
                               indent = indent,
                               rclass = class(tt), sibpos = sibpos,
                               nsibs = nsibs)))
    }
    if(labelrow_visible(tt)) {
        lr = tt_labelrow(tt)
        newdf <- make_row_df(lr,
                            colwidths= colwidths,
                            visible_only = visible_only,
                            rownum = rownum,
                            indent = indent,
                            path = path,
                            incontent = TRUE,
                            repr_ext = repr_ext,
                            repr_inds = repr_inds)
        rownum <- max(newdf$abs_rownum,na.rm = TRUE)

        ret  =  c(ret,
                  list(newdf))
        repr_ext = repr_ext + 1L
        repr_inds = c(repr_inds, rownum)
        indent <- indent + 1L
    }

    if(NROW(content_table(tt)) > 0) {
        cind <- indent + indent_mod(content_table(tt))
        contdf <-  make_row_df(content_table(tt),
                              colwidths= colwidths,
                              visible_only = visible_only,
                              rownum = rownum,
                              indent = cind,
                              path = path,
                              incontent = TRUE,
                              repr_ext = repr_ext,
                              repr_inds = repr_inds)
        crnums <- contdf$abs_rownumber
        crnums <- crnums[!is.na(crnums)]

        newrownum <- max(crnums, na.rm = TRUE)
        if(is.finite(newrownum)) {
            rownum <- newrownum
            repr_ext <- repr_ext + length(crnums)
            repr_inds <- c(repr_inds, crnums)
        }
        ret <- c(ret, list(contdf))
        indent <- cind + 1
    }


    allkids <- tree_children(tt)
    newnsibs <- length(allkids)
    for(i in seq_along(allkids)) {
        kid <- allkids[[i]]
        kiddfs <- make_row_df(kid,
                            colwidths= colwidths,
                            visible_only = visible_only,
                            rownum = force(rownum),
                            indent = indent, ## + 1,
                            path = path,
                            incontent = incontent,
                            repr_ext = repr_ext,
                            repr_inds = repr_inds,
                            nsibs = newnsibs,
                            sibpos = i)

 #       print(kiddfs$abs_rownumber)

        rownum <- max(kiddfs$abs_rownumber, na.rm = TRUE) ##max(kiddfs[[length(kiddfs)]]$abs_rownumber, na.rm = TRUE)
        ret <- c(ret, list(kiddfs))
    }

    do.call(rbind, ret)
})

#' @exportMethod make_row_df
#' @rdname make_row_df
setMethod("make_row_df", "TableRow",
          function(tt, colwidths = NULL, visible_only = TRUE,
                   rownum = 0,
                   indent = 0L,
                   path = "root",
                   incontent = FALSE,
                   repr_ext = 0L,
                   repr_inds = integer(),
                   sibpos = NA_integer_,
                   nsibs = NA_integer_) {
    indent <- indent + indent_mod(tt)
    rownum <- rownum + 1
    ret <- pagdfrow(tt, rnum = rownum,
                  colwidths = colwidths,
                  sibpos = sibpos,
                  nsibs = nsibs,
                  pth = c(path, obj_name(tt)),
                  repext = repr_ext,
                  repind = repr_inds,
                  indent = indent)
    ret
})

#' @exportMethod make_row_df
#' @rdname make_row_df
setMethod("make_row_df", "LabelRow",
          function(tt, colwidths = NULL, visible_only = TRUE,
                   rownum = 0,
                   indent = 0L,
                   path = "root",
                   incontent = FALSE,
                   repr_ext = 0L,
                   repr_inds = integer(),
                   sibpos = NA_integer_,
                   nsibs = NA_integer_) {
    rownum <- rownum + 1
    indent <- indent + indent_mod(tt)
    ret <- pagdfrow(tt, rnum = rownum,
                    colwidths = colwidths,
                    sibpos = sibpos,
                    nsibs = nsibs,
                    pth = path,
                    repext = repr_ext,
                    repind = repr_inds,
                    indent = indent)
    if(!labelrow_visible(tt))
        ret <- ret[0,]
    ret
})


setGeneric("inner_col_df", function(ct, colwidths = NULL, visible_only = TRUE,
                                   colnum = 0L,
                                   sibpos = NA_integer_,
                                   nsibs = NA_integer_) standardGeneric("inner_col_df"))


#' Column Layout Summary
#'
#' Used for Pagination
#' @inheritParams make_row_df
#' @rdname make_row_df
#' @export
make_col_df <-    function(tt,
                           visible_only = TRUE) {
    rows <- inner_col_df(coltree(tt), ## this is a null op if its already a coltree object
                 colwidths = propose_column_widths(tt),
                 visible_only = visible_only,
                 colnum = 1L,
                 sibpos = 1L,
                 nsibs = 1L) ## nsiblings includes current so 1 means "only child"
    do.call(rbind, rows)
}

setMethod("inner_col_df", "LayoutColLeaf",
          function(ct, colwidths, visible_only,
                   colnum,
                   sibpos,
                   nsibs) {
    list(col_dfrow(col = ct,
              cnum = colnum,
              sibpos = sibpos,
              nsibs = nsibs,
              leaf_indices = colnum))
})


setMethod("inner_col_df", "LayoutColTree",
          function(ct, colwidths, visible_only,
                   colnum,
                   sibpos,
                   nsibs) {

    kids <- tree_children(ct)
    ret <- vector("list", length(kids))
    for(i in seq_along(kids)) {
        k <- kids[[i]]
        nleaves <- length(collect_leaves(k))
        newrows <- do.call(rbind,
                           inner_col_df(k,
                                        colnum = colnum,
                                        sibpos = i,
                                        nsibs = length(kids),
                                        visible_only = visible_only))
        colnum <- max(newrows$abs_pos, colnum, na.rm = TRUE) + 1
        ret[[i]] = newrows
    }

    if(!visible_only) {
        allindices <- unlist(lapply(ret, function(df) df$abs_pos[!is.na(df$abs_pos)]))
        thispth <- pos_to_path(tree_pos(ct))
        if(any(nzchar(thispth))) {
            thisone  <- list(col_dfrow(col = ct,
                                       cnum = NA_integer_,
                                       leaf_indices = allindices,
                                       sibpos = sibpos,
                                       nsibs = nsibs,
                                       pth = thispth))
            ret <- c(thisone, ret)
        }
    }

    ret
})

make_row_df_old = function(tt, colwidths = NULL, visible_only = TRUE) {
    rownum = 0
    indent = 0L


    pag_df = function(tree, path, incontent = FALSE,
                      cwidths,
                      repr_ext = 0L,
                      repr_inds = integer(),
                      indent = 0L) {
        ret = list()
        if(labelrow_visible(tree)) {
            lr = tt_labelrow(tree)
            rownum <<- rownum + 1L
            ret  =  c(ret,
                      list(pagdfrow(row = lr,
                                    rnum = rownum,
                                    nm = obj_name(tree),
                                    pth = path,
                                    colwidths = cwidths,
                                    repext = repr_ext,
                                    repind = list(repr_inds),
                                    indent = indent)))
            repr_ext = repr_ext + 1L
            repr_inds = c(repr_inds, rownum)
            indent <- indent + 1L
        } else if (!visible_only) {
            ret <- c(ret,
                     list(pagdfrow(rnum = NA,
                                   nm = obj_name(tree),
                                   lab = "",
                                   pth = path,
                                   colwidths = cwidths,
                                   repext = repr_ext,
                                   repind = list(repr_inds),
                                   extent = 0,
                                   indent = indent,
                                   rclass = class(tree))))

        }
        if(is(tree, "TableTree") &&
           nrow(content_table(tree)) > 0) {
            ctab = content_table(tree)
            ## already put rownum in there if necessary
            rnbef = rownum + 1L
            crows = pag_df(ctab,
                           path = c(path, "@content"),
                           cwidths = cwidths,
                           repr_ext = repr_ext,
                           repr_inds = repr_inds,
                           indent = indent)
            if(is(crows, "data.frame"))
                crows = list(crows)
            ret = c(ret, crows)
            repr_ext = repr_ext + nlines(ctab)
            repr_inds = c(repr_inds, rnbef:rownum)
            indent = indent + 1L
        }
        kids = tree_children(tree)
        nk = length(kids)
        for(i in seq_along(kids)) {
            k = kids[[i]]
            stopifnot(identical(unname(obj_name(k)), names(kids)[i]))
            if(is(k, "TableRow")) {
                rownum <<- rownum + 1
                ret = c(ret, list(pagdfrow(k, rnum = rownum,
                                         colwidths = cwidths,
                                         sibpos = i,
                                         nsibs = nk,
                                         pth = c(path, obj_name(k)),
                                         repext = repr_ext,
                                         repind = repr_inds,
                                         indent = indent)))
            } else {

                newrows = pag_df(k, path = c(path, obj_name(k)),
                                 cwidths = cwidths, repr_ext = repr_ext,
                                 repr_inds = repr_inds,
                                 indent = indent)
                if(is(newrows, "data.frame")) {
                    newrows = list(newrows)
                }
                ret = c(ret, newrows)
            }
        }
        ret

    }
    rws = pag_df(tt, path = "root", cwidths = colwidths)
    do.call(rbind.data.frame, rws)
}



valid_pag = function(pagdf,
                     guess,
                     min_sibs,
                     nosplit = NULL,
                     verbose = FALSE) {
    rw = pagdf[guess,]

    if(verbose)
        message("Checking pagination after row ", guess)
    if(rw[["node_class"]] %in% c("LabelRow", "ContentRow")) {
        if(verbose)
            message("\t....................... FAIL: last row is a label or content row")
        return(FALSE)
    }

    sibpos = rw[["pos_in_siblings"]]
    nsib = rw[["n_siblings"]]
    okpos = min(min_sibs + 1, rw[["n_siblings"]])
    if( sibpos != nsib){
        retfalse = FALSE
        if(sibpos < min_sibs + 1) {
            retfalse = TRUE
            if(verbose)
                message("\t....................... FAIL: last row had only ", sibpos - 1, "preceeding siblings, needed ", min_sibs)
        } else if (nsib - sibpos < min_sibs + 1) {
            retfalse = TRUE
            if(verbose)
                message("\t....................... FAIL: last row had only ", nsib - sibpos - 1, "following siblings, needed ", min_sibs)
        }
        if(retfalse)
            return(FALSE)
    }
    if(guess < nrow(pagdf)) {
        curpth = unlist(rw$path)
        nxtpth = unlist(pagdf$path[[guess+1]])
        inplay = nosplit[(nosplit %in% intersect(curpth, nxtpth))]
        if(length(inplay) > 0) {
            curvals = curpth[match(inplay, curpth) + 1]
            nxtvals = nxtpth[match(inplay, nxtpth) + 1]
            if(identical(curvals, nxtvals)) {
                if(verbose)
                    message("\t....................... FAIL: values of unsplitable vars before [", curvals, "] and after [", nxtvals, "] match")
                return(FALSE)
            }
        }
    }
    if(verbose)
        message("\t....................... OK")
    TRUE
}


find_pag = function(pagdf,
                    start,
                    guess,
                    rlpp,
                    min_siblings,
                    nosplitin = character(),
                    verbose = FALSE) {
    origuess = guess
    while(guess >= start && !valid_pag(pagdf, guess, min_sibs = min_siblings, nosplit = nosplitin, verbose)) {
        guess = guess - 1
    }
    if(guess < start)
        stop("Unable to find any valid pagination between ", start, " and ", origuess)
    guess
}

#' Pagination of a TableTree
#' 
#' 
#' @note This is our first take on pagination. We will refine pagination in subsequent releases. Currently only
#'   pagination in the row space work. Pagination in the column space will be added in the future.
#' 
#' 
#' @inheritParams gen_args
#' @param lpp numeric. Maximum lines per page including (re)printed header and context rows
#' @param min_siblings  numeric. Minimum sibling rows which must appear on either side of pagination row for a
#'   mid-subtable split to be valid. Defaults to 2.
#' @param nosplitin character. List of names of sub-tables where page-breaks are not allowed, regardless of other
#'   considerations. Defaults to none.
#'   
#' @export
#' @rdname paginate
#' 
#' @examples 
#' 
#' s_summary <- function(x) {
#'  if (is.numeric(x)) {
#'      in_rows(
#'          "n" = rcell(sum(!is.na(x)), format = "xx"),
#'          "Mean (sd)" = rcell(c(mean(x, na.rm = TRUE), sd(x, na.rm = TRUE)), 
#'                              format = "xx.xx (xx.xx)"),
#'          "IQR" = rcell(IQR(x, na.rm = TRUE), format = "xx.xx"),
#'          "min - max" = rcell(range(x, na.rm = TRUE), format = "xx.xx - xx.xx")
#'      )
#'  } else if (is.factor(x)) {
#'      
#'      vs <- as.list(table(x))
#'      do.call(in_rows, lapply(vs, rcell, format = "xx"))
#'      
#'  } else (
#'      stop("type not supported")
#'  )
#' }
#' 
#' 
#' lyt <- basic_table() %>% 
#' split_cols_by(var = "ARM") %>%
#'     analyze(c("AGE", "SEX", "BEP01FL", "BMRKR1", "BMRKR2", "COUNTRY"), afun = s_summary) 
#' 
#' tbl <- build_table(lyt, ex_adsl)
#' tbl
#' 
#' nrow(tbl)
#' 
#' row_paths_summary(tbl)
#' 
#' tbls <- paginate_table(tbl)
#' 
#' w_tbls <- propose_column_widths(tbl) # so that we have the same column widths
#' 
#' tmp <- lapply(tbls, print, widths = w_tbls)
#' 
#' tmp <- lapply(tbls, function(tbli) {
#'   cat(toString(tbli, widths = w_tbls))
#'   cat("\n\n")
#'   cat("~~~~ PAGE BREAK ~~~~")
#'   cat("\n\n")
#' })
#' 
#' 
pag_tt_indices = function(tt, lpp = 15,
                           min_siblings = 2,
                           nosplitin = character(),
                           colwidths = NULL,
                           verbose = FALSE) {


    hlines = nlines(col_info(tt))
    ## row lines per page
    rlpp = lpp - hlines
    pagdf = make_row_df(tt, colwidths)


    start = 1
    nr = nrow(pagdf)
    ret = list()
    while(start < nr) {
        adjrlpp = rlpp - pagdf$par_extent[start]
        stopifnot(adjrlpp > 0)
        guess = min(nr, start + adjrlpp - 1)
        end = find_pag(pagdf, start, guess,
                       rlpp = adjrlpp,
                       min_siblings = min_siblings,
                       nosplitin = nosplitin,
                       verbose = verbose)
        ret = c(ret, list(c(pagdf$reprint_inds[[start]],
                            start:end)))
        start = end + 1
    }
    ret
}

#' @export
#' @aliases paginate_table
#' @rdname paginate
paginate_table = function(tt, lpp = 15,
                           min_siblings = 2,
                           nosplitin = character(),
                           colwidths = NULL,
                           verbose = FALSE) {
    inds = pag_tt_indices(tt, lpp = lpp,
                          min_siblings = min_siblings,
                          nosplitin = nosplitin,
                          colwidths = colwidths,
                          verbose = verbose)
    lapply(inds, function(x) tt[x,,keep_topleft = TRUE])
}
