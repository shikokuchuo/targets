tar_test("tar_path() outside a pipeline with no arguments", {
  skip_cran()
  expect_warning(tar_path(), class = "tar_condition_deprecate")
  expect_true(is.character(suppressWarnings(tar_path())))
  expect_true(is.na(suppressWarnings(tar_path())))
  expect_length(suppressWarnings(tar_path()), 1L)
  expect_equal(suppressWarnings(tar_path(default = "x")), "x")
})

tar_test("tar_path() with a name arg", {
  skip_cran()
  expect_equal(
    suppressWarnings(tar_path(x)),
    file.path("_targets", "objects", "x")
  )
})

tar_test("tar_path() inside a pipeline", {
  skip_cran()
  x <- target_init("x", quote(suppressWarnings(targets::tar_path())))
  tar_runtime$store <- path_store_default()
  on.exit(tar_runtime$store <- NULL)
  pipeline <- pipeline_init(list(x))
  local_init(pipeline)$run()
  path <- file.path("_targets", "objects", "x")
  expect_equal(target_read_value(x, pipeline)$object, path)
})

tar_test("custom script and store args", {
  skip_cran()
  expect_equal(tar_config_get("script"), path_script_default())
  expect_equal(tar_config_get("store"), path_store_default())
  expect_false(file.exists("example/store"))
  out <- suppressWarnings(tar_path(x, store = "example/store"))
  expect_equal(out, "example/store/objects/x")
  expect_false(file.exists("example/store"))
  expect_false(file.exists("_targets.yaml"))
  expect_equal(tar_config_get("script"), path_script_default())
  expect_equal(tar_config_get("store"), path_store_default())
  expect_false(file.exists(path_script_default()))
  expect_false(file.exists(path_store_default()))
  expect_false(file.exists("example/script.R"))
  tar_config_set(script = "x")
  expect_equal(tar_config_get("script"), "x")
  expect_true(file.exists("_targets.yaml"))
})

tar_test("tar_path() idempotently creates dir if create_dir is TRUE", {
  skip_cran()
  for (index in seq_len(2)) {
    out <- suppressWarnings(tar_path("x", create_dir = TRUE))
    expect_true(file.exists(dirname(out)))
  }
})

tar_test("tar_path() does not create dir if create_dir is FALSE", {
  skip_cran()
  out <- suppressWarnings(tar_path("x", create_dir = FALSE))
  expect_false(file.exists(dirname(out)))
})

tar_test("tar_path() returns non-cloud path for non-cloud storage formats", {
  skip_cran()
  skip_on_os("windows")
  x <- tar_target(x, 1, format = "parquet")
  on.exit({
    tar_runtime$store <- NULL
    tar_runtime$target <- NULL
  })
  tar_runtime$store <- path_store_default()
  tar_runtime$target <- x
  out <- suppressWarnings(tar_path(create_dir = FALSE))
  expect_false(file.exists(dirname(out)))
  out <- suppressWarnings(tar_path(create_dir = TRUE))
  expect_true(file.exists(dirname(out)))
  expect_equal(out, path_objects(path_store_default(), "x"))
})

tar_test("tar_path() returns stage for cloud formats", {
  skip_cran()
  skip_on_os("windows")
  x <- tar_target(x, 1, format = "parquet", repository = "aws")
  store_update_stage_early(
    x$store,
    x$file,
    x$settings$name,
    path_store_default()
  )
  dir <- dirname(x$file$stage)
  unlink(dir, recursive = TRUE)
  on.exit(tar_runtime$target <- NULL)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  tar_runtime$target <- x
  out <- suppressWarnings(tar_path(create_dir = FALSE))
  expect_false(file.exists(dirname(out)))
  out <- suppressWarnings(tar_path(create_dir = TRUE))
  expect_true(file.exists(dirname(out)))
  expect_equal(dirname(out), file.path(path_scratch_dir_network()))
  expect_equal(out, x$file$stage)
})

tar_test("tar_path() with alternative data store in tar_make()", {
  skip_cran()
  skip_on_os("windows")
  tar_script(tar_target(x, suppressWarnings(tar_path())))
  store <- "example_store"
  tar_make(callr_function = NULL, store = store)
  expect_equal(
    tar_read(x, store = store),
    path_objects(store, "x")
  )
})
