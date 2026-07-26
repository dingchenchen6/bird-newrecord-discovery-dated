# ============================================================
# config.R — 未随仓库分发的外部数据路径
# Paths to external archives that are NOT redistributed here
# ============================================================
# 脚本 130 与 141 需要以下外部数据; 它们体量大或受第三方许可限制,
# 因此不包含在本仓库中。把下面的路径改成你自己的副本即可。
#
# 脚本 131-139 不需要任何外部数据: 运行 setup_workspace.R 之后,
# 它们完全依赖仓库内已分发的数据。
#
# 同名环境变量会覆盖这里的默认值, 因此也可以不改这个文件:
#   export CBNR_RELEASE=/path/to/CBNR_EN.xlsx
# ============================================================

.p <- function(var, default) {
  v <- Sys.getenv(var, unset = "")
  if (nzchar(v)) v else default
}

CFG <- list(

  # --- CBNR 发布版记录表 / released record compilation -----------------------
  # 脚本 130 的唯一输入。含 Discovery_date 与 Source_publication_year。
  # 配套数据描述符见 docs/MANUSCRIPT_v2.md 参考文献 25。
  CBNR_RELEASE = .p("CBNR_RELEASE",
                    "~/data/CBNR/CBNR_EN.xlsx"),

  # --- 官方标准地图 GS(2019)1822 / official base map -------------------------
  # 省界、国界与南海九段线; 仅脚本 141 的地图需要。
  # 来源: 自然资源部标准地图服务 http://bzdt.ch.mnr.gov.cn/
  # 期望的文件: 省(等积投影).shp | 中国轮廓线.shp | 九段线.shp
  BASEMAP = .p("CBNR_BASEMAP",
               "~/data/basemap_GS2019_1822"),

  # --- 以下仅在你想从最原始数据重建上游面板时才需要 -------------------------
  # 本仓库已分发 panel_full_grid.csv.gz 与 panel_full_species.csv,
  # 脚本 132 由它们重算全部气候分量, 因此常规复现无需以下路径。

  # 物种分布区多边形 (BirdLife International, 裁剪至中国)
  # 不可再分发。申请: http://datazone.birdlife.org/species/requestdis
  BOTW = .p("CBNR_BOTW", "~/data/BOTW_clean.gpkg"),

  # WorldClim 2.1 对 CRU TS 4.09 的降尺度 (10 角分月值)
  # https://www.worldclim.org/data/monthlywth.html
  WORLDCLIM_10M = .p("CBNR_WORLDCLIM", "~/data/worldclim_10m/unzipped"),

  # CMIP6 未来生物气候面 (WorldClim 降尺度)
  # https://www.worldclim.org/data/cmip6/cmip6climate.html
  CMIP6 = .p("CBNR_CMIP6", "~/data/cmip6_worldclim"),

  # 中国 100 km 分析网格 (sf 对象, EPSG:4326), 可重新生成
  GRID_100KM = .p("CBNR_GRID", "~/data/china_grid_100km_v2.rds")
)

# 报告哪些外部输入实际可用, 不报错 / report availability without failing
cfg_status <- function() {
  x <- vapply(CFG, function(p) file.exists(path.expand(p)), logical(1))
  data.frame(input = names(CFG), path = unlist(CFG), available = x, row.names = NULL)
}

if (identical(Sys.getenv("CFG_VERBOSE"), "1")) print(cfg_status())
