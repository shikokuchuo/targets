settings_init <- function(
  name = character(0L),
  description = character(0L),
  format = "rds",
  repository = "local",
  pattern = NULL,
  iteration = "vector",
  error = "stop",
  memory = "persistent",
  garbage_collection = FALSE,
  deployment = "worker",
  priority = 0,
  resources = list(),
  storage = "main",
  retrieval = "main"
) {
  pattern <- settings_produce_pattern(pattern)
  dimensions <- settings_produce_dimensions(pattern)
  settings_validate_pattern(name, pattern, dimensions)
  settings_new(
    name = name,
    description = description,
    format = format,
    repository = repository,
    pattern = pattern,
    dimensions = dimensions,
    iteration = iteration,
    error = error,
    memory = memory,
    garbage_collection = garbage_collection,
    deployment = deployment,
    priority = priority,
    resources = resources,
    storage = storage,
    retrieval = retrieval
  )
}

settings_new <- function(
  name = NULL,
  description = NULL,
  format = NULL,
  repository = NULL,
  pattern = NULL,
  dimensions = NULL,
  iteration = NULL,
  error = NULL,
  memory = NULL,
  garbage_collection = NULL,
  deployment = NULL,
  priority = NULL,
  resources = NULL,
  storage = NULL,
  retrieval = NULL
) {
  out <- new.env(parent = emptyenv(), hash = FALSE)
  out$name <- name
  out$description <- description
  out$format <- format
  out$repository <- repository
  out$pattern <- pattern
  out$dimensions <- dimensions
  out$iteration <- iteration
  out$error <- error
  out$memory <- memory
  out$garbage_collection <- garbage_collection
  out$deployment <- deployment
  out$priority <- priority
  out$resources <- resources
  out$storage <- storage
  out$retrieval <- retrieval
  out
}

settings_clone <- function(settings) {
  settings_new(
    name = .subset2(settings, "name"),
    description = .subset2(settings, "description"),
    format = .subset2(settings, "format"),
    repository = .subset2(settings, "repository"),
    pattern = .subset2(settings, "pattern"),
    dimensions = .subset2(settings, "dimensions"),
    iteration = .subset2(settings, "iteration"),
    error = .subset2(settings, "error"),
    memory = .subset2(settings, "memory"),
    garbage_collection = .subset2(settings, "garbage_collection"),
    deployment = .subset2(settings, "deployment"),
    priority = .subset2(settings, "priority"),
    resources = .subset2(settings, "resources"),
    storage = .subset2(settings, "storage"),
    retrieval = .subset2(settings, "retrieval")
  )
}

settings_produce_pattern <- function(pattern) {
  pattern <- as.expression(pattern)
  if_any(is.null(pattern[[1]]), NULL, pattern)
}

settings_produce_dimensions <- function(pattern) {
  all.vars(pattern, functions = FALSE, unique = FALSE)
}

settings_produce_store <- function(settings) {
  store_init(
    format = settings$format,
    repository = settings$repository,
    resources = settings$resources
  )
}

settings_validate_pattern <- function(name, pattern, dimensions) {
  if (is.null(pattern)) {
    return()
  }
  tar_assert_expr(pattern)
  tar_assert_chr(dimensions)
  tar_assert_nonempty(dimensions)
  tar_assert_not_in(name, dimensions)
  tar_assert_unique(dimensions, "duplicate grouping variable in pattern.")
  symbols <- all.vars(pattern, functions = TRUE, unique = TRUE)
  non_functions <- all.vars(pattern, functions = FALSE, unique = TRUE)
  functions <- setdiff(symbols, non_functions)
  illegal <- fltr(
    functions,
    ~!exists(.x, envir = dynamic_methods$self) & !exists(.x, envir = baseenv())
  )
  if (length(illegal) > 0L) {
    string <- string_sub_expression(tar_deparse_safe(pattern))
    tar_throw_validate(
      "invalid dynamic branching pattern: ",
      string,
      ". Illegal symbols found: ",
      paste(illegal, collapse = ", "),
      ". Patterns must be valid choices from tar_pattern() such as map(), ",
      "and the arguments must be names of upstream targets or ",
      "expressions using only the base environment."
    )
  }
}

settings_validate_pattern_names <- c(
  ls(dynamic_init()$self, all.names = FALSE)
)

settings_validate <- function(settings) {
  tar_assert_correct_fields(settings, settings_new)
  tar_assert_name(settings$name)
  tar_assert_chr(settings$description)
  tar_assert_scalar(settings$description %||% "x")
  tar_assert_none_na(settings$description)
  tar_assert_format(settings$format)
  tar_assert_repository(settings$repository)
  settings_validate_pattern(
    settings$name,
    settings$pattern,
    settings$dimensions
  )
  tar_assert_chr(settings$iteration)
  tar_assert_in(
    settings$error,
    c("stop", "continue", "abridge", "workspace", "null")
  )
  tar_assert_in(settings$memory, c("auto", "persistent", "transient"))
  tar_assert_lgl(settings$garbage_collection)
  tar_assert_scalar(settings$garbage_collection)
  tar_assert_in(settings$deployment, c("main", "worker"))
  tar_assert_scalar(settings$priority)
  tar_assert_ge(settings$priority, 0)
  tar_assert_le(settings$priority, 1)
  tar_assert_list(settings$resources)
  tar_assert_in(settings$storage, c("main", "worker"))
  tar_assert_in(settings$retrieval, c("auto", "main", "worker"))
  invisible()
}
