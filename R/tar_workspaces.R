#' @title List locally saved target workspaces.
#' @export
#' @family debug
#' @description List target workspaces currently saved to
#'   `_targets/workspaces/` locally.
#'   Does not include workspaces saved to the cloud.
#'   See [tar_workspace()] and [tar_workspace_download()]
#'   for more information.
#' @return Character vector of available workspaces to load with
#'   [tar_workspace()].
#' @inheritParams tar_validate
#' @param names Optional `tidyselect` selector to return
#'   a tactical subset of workspace names.
#'   If `NULL`, all names are selected.
#'   The object supplied to `names` should be `NULL` or a
#'   `tidyselect` expression like [any_of()] or [starts_with()]
#'   from `tidyselect` itself, or [tar_described_as()] to select target names
#'   based on their descriptions.
#' @examples
#' if (identical(Sys.getenv("TAR_EXAMPLES"), "true")) { # for CRAN
#' tar_dir({ # tar_dir() runs code from a temp dir for CRAN.
#' tar_script({
#'   library(targets)
#'   library(tarchetypes)
#'   tar_option_set(workspace_on_error = TRUE)
#'   list(
#'     tar_target(x, "value"),
#'     tar_target(y, x)
#'   )
#' }, ask = FALSE)
#' tar_make()
#' tar_workspaces()
#' tar_workspaces(contains("x"))
#' })
#' }
tar_workspaces <- function(
  names = NULL,
  store = targets::tar_config_get("store")
) {
  tar_assert_allow_meta("tar_workspaces", store)
  dir <- path_workspaces_dir(path_store = store)
  choices <- if_any(
    dir.exists(dir),
    sort_chr(list.files(dir, all.files = TRUE, no.. = TRUE)),
    character(0)
  )
  names_quosure <- rlang::enquo(names)
  sort_chr(
    as.character(tar_tidyselect_eval(names_quosure, choices) %|||% choices)
  )
}
