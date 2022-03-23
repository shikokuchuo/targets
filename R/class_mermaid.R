mermaid_init <- function(
  network,
  label = NULL,
  label_break = "<br>"
) {
  mermaid_new(
    network = network,
    label = label,
    label_break = label_break
  )
}

mermaid_new <- function(
  network = NULL,
  label = NULL,
  label_break = NULL
) {
  mermaid_class$new(
    network = network,
    label = label,
    label_break = label_break
  )
}

mermaid_class <- R6::R6Class(
  classname = "tar_mermaid",
  inherit = visual_class,
  class = FALSE,
  portable = FALSE,
  cloneable = FALSE,
  public = list(
    append_loops = function() {
      vertices <- self$network$vertices
      edges <- self$network$edges
      if (nrow(edges) > 0L) {
        edges$loop <- FALSE
      }
      disconnected <- setdiff(vertices$name, c(edges$from, edges$to))
      loops <- data_frame(from = disconnected, to = disconnected)
      if (nrow(loops)) {
        loops$loop <- TRUE
      }
      self$network$edges <- rbind(edges, loops)
    },
    produce_class_defs = function() {
      vertices <- self$network$vertices
      status <- c(unique(vertices$status), "none")
      color <- self$produce_colors(status)
      fill <- self$produce_fills(status)
      sprintf(
        "  classDef %s stroke:#000000,color:%s,fill:%s;",
        status,
        color,
        fill
      )
    },
    produce_link_styles = function() {
      hide <- c(rep(TRUE, nrow(self$legend) - 1L), self$network$edges$loop)
      index <- which(hide) - 1L
      sprintf("  linkStyle %s stroke-width:0px;", index)
    },
    produce_shape_open = function(type) {
      open <- c("{{", ">", "([", "[")
      names(open) <- c("object", "function", "stem", "pattern")
      unname(open[type])
    },
    produce_shape_close = function(type) {
      open <- c("}}", "]", "])", "]")
      names(open) <- c("object", "function", "stem", "pattern")
      unname(open[type])
    },
    produce_legend = function() {
      status <- tibble::tibble(
        name = unique(self$network$vertices$status),
        open = "([",
        close = "])"
      )
      status$status <- status$name
      type <- tibble::tibble(
        name = unique(self$network$vertices$type),
        status = "none"
      )
      type$open <- self$produce_shape_open(type$name)
      type$close <- self$produce_shape_close(type$name)
      legend <- rbind(status, type)
      legend$label <- gsub("uptodate", "Up to date", legend$name)
      legend <- legend[legend$label != "none",, drop = FALSE] # nolint
      legend$label <- sprintf("\"%s\"", capitalize(legend$label))
      legend
    },
    produce_mermaid_vertices = function(data) {
      sprintf(
        "%s%s%s%s:::%s",
        sprintf("x%s", digest_chr64(data$name)),
        data$open,
        sprintf("\"%s\"", data$label),
        data$close,
        data$status
      )
    },
    produce_mermaid_vertices_graph = function(side) {
      out <- self$network$edges
      other <- if_any(identical(side, "from"), "to", "from")
      out[[other]] <- NULL
      out$name <- out[[side]]
      out[[side]] <- NULL
      vertices <- self$network$vertices
      out$id <- seq_len(nrow(out))
      out <- merge(x = out, y = vertices, all = FALSE, sort = FALSE)
      out <- out[order(out$id),, drop = FALSE] # nolint
      out$id <- NULL
      out$open <- self$produce_shape_open(out$type)
      out$close <- self$produce_shape_close(out$type)
      self$produce_mermaid_vertices(out)
    },
    produce_mermaid_lines_graph = function() {
      self$append_loops()
      from <- produce_mermaid_vertices_graph(side = "from")
      to <- produce_mermaid_vertices_graph(side = "to")
      out <- sprintf("    %s --> %s", from, to)
      out <- c("  subgraph Graph", out, "  end")
    },
    produce_mermaid_lines_legend = function() {
      vertices <- produce_mermaid_vertices(self$legend)
      if (length(vertices) == 1L) {
        vertices <- c(vertices, vertices)
      }
      from <- vertices[-length(vertices)]
      to <- vertices[-1]
      out <- sprintf("    %s --- %s", from, to)
      out <- c("  subgraph Legend", out, "  end")
    },
    produce_visual = function() {
      if (nrow(self$network$vertices) < 1L) {
        return("")
      }
      graph <- self$produce_mermaid_lines_graph()
      legend <- self$produce_mermaid_lines_legend()
      class_defs <- self$produce_class_defs()
      link_styles <- self$produce_link_styles()
      c("graph LR", legend, graph, class_defs, link_styles)
    },
    update_extra = function() {
    },
    validate = function() {
      super$validate()
      if (!is.null(self$visual)) {
        tar_assert_chr(self$visual)
      }
    }
  )
)