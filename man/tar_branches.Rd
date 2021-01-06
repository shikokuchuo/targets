% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tar_branches.R
\name{tar_branches}
\alias{tar_branches}
\title{Reconstruct the branch names and the names of their dependencies.}
\usage{
tar_branches(name, pattern)
}
\arguments{
\item{name}{Symbol, name of the target.}

\item{pattern}{Language to define branching for a target.
For example, in a pipeline with numeric vector targets \code{x} and \code{y},
\code{tar_target(z, x + y, pattern = map(x, y))} implicitly defines
branches of \code{z} that each compute \code{x[1] + y[1]}, \code{x[2] + y[2]},
and so on. See the user manual for details.}
}
\value{
A \code{tibble} with one row per branch and one column for each target
(including the branched-over targets and the target with the pattern.)
}
\description{
Given a branching pattern, use available metadata
to reconstruct branch names and the names of each
branch's dependencies. The metadata of each target
must already exist and be consistent with the metadata
of the other targets involved.
}
\details{
The results from this function can help you retroactively
figure out correspondences between upstream branches and downstream
branches. However, it does not always correctly predict what the
names of the branches will be after the next run of the pipeline.
Dynamic branching happens while the pipeline is running,
so we cannot always know what the names of the branches will be
in advance (or even how many there will be).
}
\examples{
if (identical(Sys.getenv("TARGETS_LONG_EXAMPLES"), "true")) {
tar_dir({
tar_script(
  list(
    tar_target(x, seq_len(2)),
    tar_target(y, head(letters, 2)),
    tar_target(z, head(LETTERS, 2)),
    tar_target(dynamic, c(x, y, z), pattern = cross(z, map(x, y)))
  )
)
tar_make()
tar_branches(dynamic, pattern = cross(z, map(x, y)))
})
}
}