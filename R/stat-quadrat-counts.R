#' Count the number of observations in each quadrat of a plot.
#'
#' \code{stat_quadrat_counts} counts the number of observations in each quadrat
#' of a plot panel. By default it adds a text label to the far corner of each
#' quadrat. It can also be used to obtain the total number of observations in
#' each of two pairs of quadrats or in the whole panel. Grouping is ignored, so
#' en every case a single count is computed for each quadrat in a plot panel.
#'
#' @param mapping The aesthetic mapping, usually constructed with
#'   \code{\link[ggplot2]{aes}} or \code{\link[ggplot2]{aes_string}}. Only needs
#'   to be set at the layer level if you are overriding the plot defaults.
#' @param data A layer specific dataset - only needed if you want to override
#'   the plot defaults.
#' @param geom The geometric object to use display the data
#' @param position The position adjustment to use for overlapping points on this
#'   layer
#' @param show.legend logical. Should this layer be included in the legends?
#'   \code{NA}, the default, includes if any aesthetics are mapped. \code{FALSE}
#'   never includes, and \code{TRUE} always includes.
#' @param inherit.aes If \code{FALSE}, overrides the default aesthetics, rather
#'   than combining with them. This is most useful for helper functions that
#'   define both data and aesthetics and should not inherit behaviour from the
#'   default plot specification, e.g. \code{\link[ggplot2]{borders}}.
#' @param ... other arguments passed on to \code{\link[ggplot2]{layer}}. This
#'   can include aesthetics whose values you want to set, not map. See
#'   \code{\link[ggplot2]{layer}} for more details.
#' @param na.rm	a logical indicating whether NA values should be stripped before
#'   the computation proceeds.
#' @param quadrats integer vector indicating which quadrats are of interest,
#'   with a \code{OL} indicating the whole plot.
#' @param pool.along character, one of "none", "x" or "y", indicating which
#'   quadrats to pool to calculate counts by pair of quadrats.
#' @param origin.x,origin.y numeric the coordinates of the origin of the
#'   quadrats.
#' @param labels.range.x,labels.range.y \code{numeric} Coordinates (in data
#'   units) to be used for absolute positioning of the labels.
#'
#' @details This stat can be used to automatically count observations in each of
#'   the four quadrats of a plot, and by default add these counts as text
#'   labels.
#'
#' @section Computed variables: Data frame with one to four rows, one for each
#'   quadrat for which observations are present in \code{data}. \describe{
#'   \item{quadrat}{integer, one of 0:4} \item{x}{extreme x value in the
#'   quadrat} \item{y}{extreme y value in the quadrat} \item{count}{number of
#'   ovserbations} }
#'
#' @note Values exactly equal to zero are counted as belonging to the positve
#'   quadrat. An argument value of zero, passed to formal parameter
#'   \code{quadrats} is interpreted as a request for the count of all
#'   observations in each plot panel. By default, which quadrats to compute
#'   counts for is decided based on which quadrats are expected to be visible in
#'   the plot. In the current implementation, the default positions of the
#'   labels is based on the range of the data ploted in a given panel.
#'   Consequently, when using facets unless using free limits for x and y axes,
#'   the location of the labels will need supplied by the user when consistent
#'   placement accross panels is desired.
#'
#' @examples
#' library(ggplot2)
#' # generate artificial data
#' set.seed(4321)
#' x <- 1:100
#' y <- rnorm(length(x), mean = 10)
#' my.data <- data.frame(x, y)
#'
#' ggplot(my.data, aes(x, y)) +
#'   geom_point() +
#'   stat_quadrat_counts()
#'
#' ggplot(my.data, aes(x - 50, y - 10)) +
#'   geom_hline(yintercept = 0, colour = "blue") +
#'   geom_vline(xintercept = 0, colour = "blue") +
#'   geom_point() +
#'   stat_quadrat_counts(colour = "blue")
#'
#' ggplot(my.data, aes(x - 50, y - 10)) +
#'   geom_hline(yintercept = 0, colour = "blue") +
#'   geom_point() +
#'   stat_quadrat_counts(colour = "blue", pool.along = "x")
#'
#' ggplot(my.data, aes(x - 50, y - 10)) +
#'   geom_vline(xintercept = 0, colour = "blue") +
#'   geom_point() +
#'   stat_quadrat_counts(colour = "blue", pool.along = "y")
#'
#' ggplot(my.data, aes(x - 50, y - 10)) +
#'   geom_point() +
#'   stat_quadrat_counts(quadrats = 0)
#'
#' @export
#'
stat_quadrat_counts <- function(mapping = NULL, data = NULL, geom = "text",
                                position = "identity",
                                quadrats = NULL,
                                pool.along = "none",
                                origin.x = 0, origin.y = 0,
                                labels.range.x = NULL, labels.range.y = NULL,
                                na.rm = FALSE, show.legend = FALSE,
                                inherit.aes = TRUE, ...) {
  ggplot2::layer(
    stat = StatQuadratCounts, data = data, mapping = mapping, geom = geom,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(na.rm = na.rm,
                  quadrats = quadrats,
                  pool.along = pool.along,
                  origin.x = origin.x,
                  origin.y = origin.y,
                  labels.range.x = labels.range.x,
                  labels.range.y = labels.range.y,
                  ...)
  )
}

#' @rdname ggpmisc-ggproto
#'
#' @format NULL
#' @usage NULL
#'
compute_counts_fun <- function(data,
                               scales,
                               quadrats,
                               pool.along,
                               origin.x,
                               origin.y,
                               labels.range.x,
                               labels.range.y) {

  which_quadrat <- function(x, y) {
    z <- ifelse(x >= origin.x & y >= origin.y,
                1L,
                ifelse(x >= origin.x & y < origin.y,
                       2L,
                       ifelse(x < origin.x & y < origin.y,
                              3L,
                              4L)))
    if (pool.along == "x") {
      z <- ifelse(z %in% c(1L, 4L), 1L, 2L)
    } else if(pool.along == "y") {
      z <- ifelse(z %in% c(1L, 2L), 1L, 4L)
    }
    z
  }

  stopifnot(pool.along %in% c("none", "x", "y"))
  stopifnot(length(origin.x) == 1 && length(origin.y) == 1)
  stopifnot(length(quadrats) <= 4)
  stopifnot(is.null(labels.range.x) || is.numeric(labels.range.x))
  stopifnot(is.null(labels.range.y) || is.numeric(labels.range.y))

  force(data)
  # compute range of whole data
  range.x <- range(data$x)
  range.y <- range(data$y)
  # compute postion for labels
  if (is.null(labels.range.x)) {
    if (pool.along == "x") {
      labels.range.x <- rep(origin.x, 2)
    } else {
    labels.range.x <- range.x
    }
  } else {
    labels.range.x <- range(labels.range.x)
  }

  if (is.null(labels.range.y)) {
    if (pool.along == "y") {
      labels.range.y <- rep(origin.y, 2)
    } else {
      labels.range.y <- range.y
    }
  } else {
    labels.range.y <- range(labels.range.y)
  }

  # dynamic default based on data range
  if (is.null(quadrats)) {
    if (all(range.x >= origin.x) && all(range.y >= origin.y)) {
      quadrats = 1L
    } else if (all(range.x < origin.x) && all(range.y < origin.y)) {
      quadrats = 3L
    } else if (all(range.x >= origin.x)) {
      quadrats = c(1L, 2L)
    } else if (all(range.y >= origin.y)) {
      quadrats = c(1L, 4L)
    } else {
      quadrats = c(1L, 2L, 3L, 4L)
    }
  }
  if (pool.along == "x") {
    quadrats <- intersect(quadrats, c(1L, 2L))
  }
  if (pool.along == "y") {
    quadrats <- intersect(quadrats, c(1L, 4L))
  }

  if (all(is.na(quadrats)) || 0L %in% quadrats) {
  # total count
    tibble::tibble(quadrat = 0,
                   count = nrow(data),
                   x = labels.range.x[2],
                   y = labels.range.y[2],
                   hjust = 1,
                   vjust = 1)
  } else {
  # counts for the selected quadrats
    data %>%
      dplyr::mutate(quadrat = which_quadrat(.data$x, .data$y)) %>%
      dplyr::filter(.data$quadrat %in% quadrats) %>%
      dplyr::group_by(.data$quadrat) %>%
      dplyr::summarise(count = length(.data$x)) %>% # dplyr::n() triggers error
      dplyr::ungroup() -> data

    zero.count.quadrats <- setdiff(quadrats, data$quadrat)

    if (length(zero.count.quadrats) > 0) {
      data <-
        rbind(data, tibble::tibble(quadrat = zero.count.quadrats, count = 0L))
    }

    data %>%
      dplyr::mutate(x = ifelse(.data$quadrat %in% c(1L, 2L),
                               labels.range.x[2],
                               labels.range.x[1]),
                    y = ifelse(.data$quadrat %in% c(1L, 4L),
                               labels.range.y[2],
                               labels.range.y[1]),
                    hjust = ifelse(.data$quadrat %in% c(1L, 2L), 1, 0),
                    vjust = ifelse(.data$quadrat %in% c(1L, 4L), -0.1, 1.1))
   }
}

#' @rdname ggpmisc-ggproto
#' @format NULL
#' @usage NULL
#' @export
StatQuadratCounts <-
  ggplot2::ggproto("StatQuadratCounts", ggplot2::Stat,
                   compute_panel = compute_counts_fun,
                   default_aes =
                     ggplot2::aes(label = paste("n=", ..count.., sep = ""),
                                  hjust = ..hjust..,
                                  vjust = ..vjust..),
                   required_aes = c("x", "y")
  )


