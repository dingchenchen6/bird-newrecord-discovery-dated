#!/usr/bin/env Rscript
# ============================================================
# setup_workspace.R — 建立脚本所需的工作目录布局
# Build the working directory layout the analysis scripts expect
# ============================================================
# 仓库以扁平、可浏览的布局存放文件(data/ tables/ figures/), 而 code/ 中的
# 脚本沿用开发期的工作布局:
#
#   analysis_v2/{data,tables,figures,figures_future,docs,logs}/
#   analysis_rebuilt/data/
#   analysis_final/data/
#   analysis_species_specific/{data,tables}/
#
# 本脚本从扁平布局构建工作布局, 使脚本无需修改即可运行。能硬链接就硬链接,
# 不能则复制, 因此多数系统上不占额外磁盘。
#
# 克隆后运行一次 / Run once after cloning:
#   Rscript --no-init-file setup_workspace.R
# 随后验证 / Then verify:
#   Rscript --no-init-file tests/smoke_test.R
# ============================================================

msg <- function(...) cat(sprintf("[setup %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

ROOT <- normalizePath(".", mustWork = TRUE)
if (!dir.exists(file.path(ROOT, "code")) || !dir.exists(file.path(ROOT, "data")))
  stop("Run this from the repository root (the folder containing code/ and data/).")

DIRS <- c("analysis_v2/data", "analysis_v2/tables", "analysis_v2/figures",
          "analysis_v2/figures_future", "analysis_v2/docs", "analysis_v2/logs",
          "analysis_rebuilt/data", "analysis_final/data",
          "analysis_species_specific/data", "analysis_species_specific/tables")
for (d in DIRS) dir.create(file.path(ROOT, d), recursive = TRUE, showWarnings = FALSE)
msg("created ", length(DIRS), " working directories")

# 工作布局路径 <- 仓库路径 / working path <- repository path
MAP <- c(
  "analysis_v2/data/events_discovery_dated.csv"                  = "data/events_discovery_dated.csv",
  "analysis_v2/data/effort_panel_v2.csv"                         = "data/effort_panel_v2.csv",
  "analysis_v2/data/model_v2_thr50.parquet"                      = "data/model_v2_thr50.parquet",
  "analysis_v2/data/components_v2_tavg_annual_W15.parquet"       = "data/components_v2_tavg_annual_W15.parquet",
  "analysis_rebuilt/data/effort_province_year_rebuilt.csv"       = "data/effort_province_year_rebuilt.csv",
  "analysis_rebuilt/data/grid_province_lookup.csv"               = "data/grid_province_lookup.csv",
  "analysis_final/data/panel_full_species.csv"                   = "data/panel_full_species.csv",
  "analysis_species_specific/data/model_thr50.parquet"           = "data/model_thr50.parquet",
  "analysis_species_specific/data/model_thr100.parquet"          = "data/model_thr100.parquet",
  "analysis_species_specific/data/model_thr200.parquet"          = "data/model_thr200.parquet",
  "analysis_species_specific/tables/tbl_F_cmip6_delta.csv"       = "data/tbl_F_cmip6_delta.csv"
)

link_or_copy <- function(from, to) {
  if (file.exists(to)) return("exists")
  if (isTRUE(suppressWarnings(file.link(from, to)))) return("linked")
  if (file.copy(from, to)) return("copied")
  "FAILED"
}

n <- c(linked = 0L, copied = 0L, exists = 0L, missing = 0L, FAILED = 0L)
for (i in seq_along(MAP)) {
  from <- file.path(ROOT, MAP[[i]]); to <- file.path(ROOT, names(MAP)[i])
  if (!file.exists(from)) { n["missing"] <- n["missing"] + 1L
    msg("  MISSING in repository: ", MAP[[i]]); next }
  r <- link_or_copy(from, to); n[r] <- n[r] + 1L
}
msg("data files: ", n["linked"], " linked, ", n["copied"], " copied, ",
    n["exists"], " already present, ", n["missing"], " missing")

# panel_full_grid.csv 以 gzip 存放(16 MB -> 5.8 MB); 就地解压一次
# 分块读取, 不预估解压后大小 / chunked, so no need to guess the inflated size
gz  <- file.path(ROOT, "data", "panel_full_grid.csv.gz")
out <- file.path(ROOT, "analysis_final", "data", "panel_full_grid.csv")
if (file.exists(gz) && !file.exists(out)) {
  inc <- gzfile(gz, "rb"); outc <- file(out, "wb")
  repeat {
    buf <- readBin(inc, "raw", 4L * 1024L * 1024L)
    if (!length(buf)) break
    writeBin(buf, outc)
  }
  close(inc); close(outc)
  msg("decompressed panel_full_grid.csv (", round(file.size(out) / 1048576, 1), " MB)")
}

# 结果表供图件脚本读取 / result tables are read by the figure scripts
tb <- list.files(file.path(ROOT, "tables"), pattern = "\\.csv$", full.names = TRUE)
for (f in tb) link_or_copy(f, file.path(ROOT, "analysis_v2/tables", basename(f)))
msg("result tables staged: ", length(tb))

msg("workspace ready. Next: Rscript --no-init-file tests/smoke_test.R")
msg("NOTE: the 16 climate-component files are not shipped; script 132 regenerates all of them")
msg("      from panel_full_grid.csv and panel_full_species.csv in about 30 seconds.")
