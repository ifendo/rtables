
context("rtables")

test_that("rtable design decisions", {
  
  
  # An rtable gets created with header amd body specification
  t1 <- rtable(
    header = c("A", "B"),
    rrow("row 1", 1, 2),
    rrow("row 2", 3, 4),
    rrow("row 3", 5, 6)
  )
  
  # t1
  # t1[c(),]
  # t1[1,]
  # t1[1:2,]
  # t1[c(1,3),]

  
  t1 <- rtable(header = c("A", "B"), format = "xx", rrow("row 1", 1, 2))
  
  expect_identical(names(t1), c("A", "B"))
  expect_equal(dim(t1), c(1, 2))
  expect_identical(row.names(t1), "row 1")
  expect_identical(as.vector(t1[1,1]), 1)
  expect_identical(as.vector(t1[1,2]), 2)

  tbl <- rtable(
    header = c("Treatment\nN=100", "Comparison\nN=300"),
    format = "xx (xx.xx%)",
    rrow("A", c(104, .2), c(100, .4)),
    rrow("B", c(23, .4), c(43, .5)),
    rrow(),
    rrow("this is a very long section header"),
    rrow("estimate", rcell(55.23, "xx.xx", colspan = 2)),
    rrow("95% CI", indent = 1, rcell(c(44.8, 67.4), format = "(xx.x, xx.x)", colspan = 2)))
  
  tbl
    ## see redesign/breaking_changes.md
    ## expect_identical(names(tbl), c("Treatment\nN=100", "Comparison\nN=300"))
    expect_identical(names(tbl), c("Treatment", "Comparison"))
    
    ## replace once the colspan rows are uncommented
    expect_equal(dim(tbl) , c(6, 2))
    ##expect_equal(dim(tbl) , c(4, 2))
  expect_identical(row.names(tbl), c("A", "B", "", "this is a very long section header", "estimate", "95% CI"))
  
  expect_identical(as.vector(tbl[1,1]), c(104, .2))
  expect_identical(as.vector(tbl[1,2]), c(100, .4))
  
  expect_identical(as.vector(tbl[2,1]), c(23, .4))
  expect_identical(as.vector(tbl[2,2]), c(43, .5))
  
  ## I think these tests were wrong/enforced
  ## bad behavior before
  ## expect_true(is.null(tbl[3,1]))
  ## expect_true(is.null(tbl[3,2]))
  
  ## expect_true(is.null(tbl[4,1]))
  ## expect_true(is.null(tbl[4,2]))

  expect_true(is.null(as.vector(tbl[3,1])))
  expect_true(is.null(as.vector(tbl[3,2])))
  
  expect_true(is.null(as.vector(tbl[4,1])))
  expect_true(is.null(as.vector(tbl[4,2])))


  ## XXX todo
  ## expect_identical(as.vector(tbl[5,1]), 55.23)
  ## expect_identical(as.vector(tbl[5,2]), 55.23)
  
  ## expect_identical(as.vector(tbl[6,1]), c(44.8, 67.4))
  ## expect_identical(as.vector(tbl[6,2]), c(44.8, 67.4))
  
  t3 <- rtable(
    header = "B",
    format = "xx (xx.xx%)",
    rrow("group 1", c(1.1234, .20222)),
    rrow("group 2", c(4.3214, .432132))
  )
  t3
  
})


test_that("multi-header tables work", {
  
  t1 <- rtable(
    header = rheader(
      rrow(NULL, rcell("A", colspan = 2), rcell("B", colspan = 2)),
      rrow(NULL, "x", "y", "x", "y")
    ),
    rrowl(row.name = "row 1", 1:4),
    rrowl(row.name = "row 2", 4:1)
  )
    ## printing it works
    t1
  expect_equal(nrow(t1), 2)
  expect_equal(ncol(t1), 4)
  expect_equal(names(t1), c("A", "A", "B", "B"))
  
})


test_that("test sprintf based format", {
  
  expect_equal(format_rcell(rcell(12.213743534, sprintf_format("%.3f"))), "12.214")
  expect_equal(format_rcell(rcell(12.2134543534, sprintf_format("%.3f"))), "12.213")
  
  expect_equal(format_rcell(rcell(c(12.21, 7.321), sprintf_format("%.1f and %.2f"))), "12.2 and 7.32")
  
})

test_that("test p-value format", {
  
  expect_equal(format_rcell(rcell(0.02, "x.xxxx | (<0.0001)")), "0.0200")
  expect_equal(format_rcell(rcell(0.0234934, "x.xxxx | (<0.0001)")), "0.0235")
  expect_equal(format_rcell(rcell(0.00000001, "x.xxxx | (<0.0001)")), "<0.0001")

})

test_that("test 3d format (estimate and CI)", {
  
  expect_equal(format_rcell(rcell(c(0.02, -0.05, 0.0434235), "xx.xx (xx.xx - xx.xx)")), "0.02 (-0.05 - 0.04)")
  expect_equal(format_rcell(rcell(c(12.34590, 3.2359, 324.2492), "xx.xx (xx.xx - xx.xx)")), "12.35 (3.24 - 324.25)")

})
