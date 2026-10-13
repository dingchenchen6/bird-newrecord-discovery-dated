#!/usr/bin/env Rscript
# ============================================================
# Script 151: 物种性状主表(1445 种中国鸟类物种库 + BIRDBASE + AVONET + 随机森林插补)
# Master trait table on the 1445-species Chinese bird pool
# ============================================================
# 物种池 / Species pool:
#   以【中国鸟类生态学性状数据库】的 1445 个中国鸟种为物种池, 而非早前的
#   1289 个"物种概念"。该库对全部字段无缺失, 且性状为中国境内口径。
#
# 数据源与优先级 / Sources, in order of precedence:
#   1. 中国鸟类性状库(主源, 1445 种)
#      体重、体长、嘴峰、翅长、尾长、跗蹠长(雌雄分列, 多为区间 -> 取中点)
#      食性(多类别)、窝卵数、卵大小与体积、巢型、巢址、集群
#      迁徙状态(R 留 / S 夏候 / W 冬候 / P 旅 / V 迷, 可组合)、特有性、分布省数
#   2. BIRDBASE v2025.1 (Şekercioğlu et al. 2025, 11589 种)
#      HB  栖息地宽度 = 使用的主要生境数(1-11)
#      DB  食性宽度   = 取食的主要食物类型数(0-7)
#      ESI 生态特化指数 = log10(100 / (DB x HB))
#      2024 IUCN 红色名录等级
#   3. AVONET(BirdLife 版) 手翼指数 HWI(扩散能力, 前两源均无)、
#      栖息地密闭度、营养生态位、全球分布区面积
#   4. missForest 随机森林插补, 逐字段标记, 供敏感性分析剔除
#
# 名称解析的三级级联 / Three-tier name resolution:
#   T1 规范化后精确匹配
#   T2 BIRDBASE 同义名桥接(该库同时给出 BirdLife / IOC / Clements / AviList
#      四套名字, 一行内互为同义)
#   T3 【同科】内种加词匹配 —— 只用于属级改名(Curruca <- Sylvia、
#      Pterorhinus <- Garrulax、Spilopelia <- Streptopelia、Urile <- Phalacrocorax)。
#      ★ 必须加同科约束: 不加约束会把 Ardenna pacifica(鹱) 错配到
#        Gavia pacifica(潜鸟)、Lanius borealis(伯劳) 错配到
#        Phylloscopus borealis(柳莺)。实测无约束时 17 个"命中"里过半是错的。
#   每个物种记录解析层级, 可审计。
#
# Input / 输入:
#   supplFile_art_20220117115032 (1).xlsx        中国鸟类生态学性状数据库
#   BIRDBASE v2025.1 Sekercioglu et al. Final.xlsx
#   AVONET1_BirdLife.csv
#   summary_dated_clements_Aves_1.4_Clements2023.nex   系统发育树
#   analysis_v2/data/events_discovery_dated.csv        v2 事件
# Output / 输出:
#   analysis_v2/data/species_traits_harmonised_v2.csv
#   analysis_v2/tables/tbl_v2_trait_{coverage,resolution,imputation_oob}.csv
#
# Main packages / 主要包: data.table, readxl, ape, missForest
# 运行 / Run: Rscript --no-init-file code/151_harmonise_species_traits.R
# ============================================================

suppressPackageStartupMessages({ library(data.table); library(readxl); library(ape) })
options(warn = 1); set.seed(42)

OUT  <- file.path(normalizePath(".", mustWork = TRUE), "analysis_v2")
CNDB <- "/Users/dingchenchen/Downloads/supplFile_art_20220117115032 (1).xlsx"
BBF  <- "/Users/dingchenchen/Downloads/BIRDBASE v2025.1 Sekercioglu et al. Final.xlsx"
AVOF <- "/Users/dingchenchen/Downloads/AVONET/ELEData/TraitData/AVONET1_BirdLife.csv"
TREE <- "/Users/dingchenchen/Documents/New project/bird_phylogeny_new_records_mctavish_work/data/external/summary_dated_clements_Aves_1.4_Clements2023.nex"
msg  <- function(...) cat(sprintf("[151 %s] ", format(Sys.time(), "%H:%M:%S")), ..., "\n")

norm  <- function(x) { x <- trimws(gsub("_", " ", as.character(x))); x <- gsub("\\s+", " ", x)
                       paste0(toupper(substr(x, 1, 1)), tolower(substr(x, 2, nchar(x)))) }
epith <- function(x) tolower(sub("^\\S+\\s+", "", norm(x)))
famnm <- function(x) tolower(gsub("[^A-Za-z]", "", sub(".*\\s", "", as.character(x))))

# ---- 1. 物种池: 中国鸟类性状库 1445 种 ----
cn <- as.data.table(read_excel(CNDB, sheet = "Chinesebirdsdata", skip = 1))
setnames(cn, c("order_cn", "family_cn", "name_cn", "name_en", "latin", "endemic_cn",
               "mass_m", "mass_f", "len_m", "len_f", "culmen_m", "culmen_f",
               "wing_m", "wing_f", "tail_m", "tail_f", "tarsus_m", "tarsus_f",
               "diet_cn", "clutch_cn", "egg_size", "egg_vol", "nest_type", "nest_site",
               "flocking", "migration_cn", "dist_region", "n_provinces_cn"))
cn <- cn[!is.na(latin) & nzchar(trimws(latin))]
cn[, `:=`(sp_key = norm(latin), ep = epith(latin), fam = famnm(family_cn), row_id = .I)]
msg("物种池(中国鸟类性状库): ", nrow(cn), " 种 | 科 ", uniqueN(cn$fam))

mid <- function(x) {
  s <- gsub("~", "-", gsub("[^0-9.~\\-]", "", as.character(x)))
  vapply(strsplit(s, "-"), function(p) { v <- suppressWarnings(as.numeric(p[nzchar(p)]))
    if (!length(v) || all(is.na(v))) NA_real_ else mean(v, na.rm = TRUE) }, numeric(1))
}
for (v in c("mass_m", "mass_f", "len_m", "len_f", "culmen_m", "culmen_f", "wing_m", "wing_f",
            "tail_m", "tail_f", "tarsus_m", "tarsus_f", "clutch_cn"))
  cn[[paste0(v, "_n")]] <- mid(cn[[v]])
cn[, `:=`(mass_g_final = rowMeans(cbind(mass_m_n, mass_f_n), na.rm = TRUE),
          length_cn    = rowMeans(cbind(len_m_n, len_f_n), na.rm = TRUE),
          wing_cn      = rowMeans(cbind(wing_m_n, wing_f_n), na.rm = TRUE),
          tarsus_cn    = rowMeans(cbind(tarsus_m_n, tarsus_f_n), na.rm = TRUE),
          clutch_final = clutch_cn_n)]
split_n <- function(x) vapply(strsplit(gsub("[，、,]", "|", trimws(as.character(x))), "|", fixed = TRUE),
                              function(p) length(unique(trimws(p[nzchar(trimws(p))]))), integer(1))
cn[, diet_n_china := split_n(diet_cn)][is.na(diet_cn) | !nzchar(trimws(diet_cn)), diet_n_china := NA_integer_]
cn[, mig_str := toupper(gsub("[^RSWPV]", "", as.character(migration_cn)))]
cn[, migration_final := fifelse(mig_str == "R", "Resident",
                        fifelse(grepl("R", mig_str), "Partial migrant",
                        fifelse(nzchar(mig_str), "Migratory", NA_character_)))]
cn[, endemic_final := fifelse(trimws(endemic_cn) == "是", "Endemic",
                       fifelse(trimws(endemic_cn) == "否", "Non-endemic", NA_character_))]
first_code <- function(x) { v <- vapply(strsplit(trimws(gsub("[^0-9]", " ", as.character(x))), "\\s+"),
                                        function(p) p[1], character(1)); v[!nzchar(v)] <- NA; v }
cn[, `:=`(nest_type_c = first_code(nest_type), nest_site_c = first_code(nest_site),
          flocking_c = first_code(flocking),
          provinces_final = suppressWarnings(as.numeric(n_provinces_cn)))]
cn[, n_congeners := .N, by = sub(" .*", "", sp_key)]

# ---- 2. 三级名称解析器 ----
resolve <- function(target_names, target_fams, tag) {
  # target_*: 外部源的名字与科; 返回 pool row_id -> 外部行号
  tn <- data.table(idx = seq_along(target_names), nm = norm(target_names),
                   ep = epith(target_names), fam = famnm(target_fams))
  tn <- tn[nzchar(nm) & nm != "Na"]
  t1 <- merge(cn[, .(row_id, sp_key)], unique(tn, by = "nm"), by.x = "sp_key", by.y = "nm")[
    , .(row_id, idx, tier = "T1 exact")]
  rest <- setdiff(cn$row_id, t1$row_id)
  t3 <- if (length(rest)) {
    cand <- merge(cn[row_id %in% rest, .(row_id, ep, fam)], tn, by = c("ep", "fam"),
                  allow.cartesian = TRUE)
    cand[, n := .N, by = row_id]
    cand[n == 1L, .(row_id, idx, tier = "T3 epithet within family")]   # 仅唯一解才接受
  } else NULL
  out <- rbindlist(list(t1, t3), fill = TRUE)
  msg("  ", tag, ": ", nrow(out), " / ", nrow(cn),
      sprintf(" (%.1f%%) | %s", 100 * nrow(out) / nrow(cn),
              paste(sprintf("%s=%d", names(table(out$tier)), table(out$tier)), collapse = " ")))
  out
}

# BIRDBASE(自带四套分类名, 天然承担 T2 桥接)
bb <- suppressWarnings(as.data.table(read_excel(BBF, sheet = "Data", skip = 1)))
setnames(bb, make.unique(names(bb)))
BB_NM  <- grep("^(Latin|HBW/BirdLife|IOC World|eBird/Clements|AviList)", names(bb), value = TRUE)
BB_FAM <- grep("^Family", names(bb), value = TRUE)[1]
bb_long <- rbindlist(lapply(BB_NM, function(c)
  data.table(nm = bb[[c]], fam = bb[[BB_FAM]], idx = seq_len(nrow(bb)))))
bb_long <- unique(bb_long[nzchar(norm(nm)) & norm(nm) != "Na"], by = "nm")
msg("BIRDBASE ", nrow(bb), " 行 | 展开同义名 ", nrow(bb_long))
h_bb <- resolve(bb_long$nm, bb_long$fam, "BIRDBASE")
h_bb[, idx := bb_long$idx[idx]]

# 中国库把缺失写成字符串 "NA", 故体重与窝卵数实际覆盖只有 89.6% / 87.1%,
# 用 BIRDBASE 的 Average Mass 与 Clutch_Min/Max 补齐, 再不足才交给随机森林。
# NB: the Chinese database encodes missing values as the literal string "NA".
num_bb <- function(x) suppressWarnings(as.numeric(ifelse(as.character(x) == "NA", NA, as.character(x))))
bb[, `:=`(habitat_breadth = num_bb(HB),
          diet_breadth    = num_bb(DB),
          esi             = num_bb(ESI),
          iucn            = as.character(`2024 IUCN Red List category`),
          mass_bb         = num_bb(`Average Mass`),
          clutch_bb       = rowMeans(cbind(num_bb(Clutch_Min), num_bb(Clutch_Max)), na.rm = TRUE),
          flightless_bb   = as.character(Flightlessness))]
bb[!is.finite(clutch_bb), clutch_bb := NA_real_]
BB_KEEP <- c("habitat_breadth", "diet_breadth", "esi", "iucn", "mass_bb", "clutch_bb", "flightless_bb")
d <- merge(cn, cbind(h_bb[, .(row_id, bb_tier = tier)], bb[h_bb$idx, ..BB_KEEP]),
           by = "row_id", all.x = TRUE)

# AVONET
av <- fread(AVOF); setnames(av, c("Hand-Wing.Index", "Mass"), c("hwi_final", "mass_av"))
h_av <- resolve(av$Species1, av$Family1, "AVONET")
AV_KEEP <- c("hwi_final", "mass_av", "Habitat.Density", "Trophic.Niche", "Range.Size")
d <- merge(d, cbind(h_av[, .(row_id, av_tier = tier)], av[h_av$idx, ..AV_KEEP]),
           by = "row_id", all.x = TRUE)
setnames(d, c("Habitat.Density", "Trophic.Niche", "Range.Size"),
         c("habitat_density_av", "trophic_niche_av", "range_size_av"))

# 系统树
tr <- read.nexus(TREE)
h_tr <- resolve(gsub("_", " ", tr$tip.label), rep(NA_character_, length(tr$tip.label)), "系统树")
h_tr <- h_tr[tier == "T1 exact"]           # 树无科信息, 只接受精确匹配
d <- merge(d, data.table(row_id = h_tr$row_id, tree_label = tr$tip.label[h_tr$idx]),
           by = "row_id", all.x = TRUE)
msg("可用于系统发育模型的物种: ", sum(!is.na(d$tree_label)), " / ", nrow(d))

# ---- 3. v2 事件 -> 物种池 ----
ev <- fread(file.path(OUT, "data", "events_discovery_dated.csv"))
evn <- unique(ev[, .(species)])
# 事件物种的科由 AVONET/BIRDBASE 提供
famref <- unique(rbind(data.table(nm = norm(av$Species1), fam = famnm(av$Family1)),
                       data.table(nm = norm(bb_long$nm), fam = famnm(bb_long$fam))), by = "nm")
evn <- merge(evn[, .(species, nm = norm(species))], famref, by = "nm", all.x = TRUE)
e1 <- merge(evn, cn[, .(sp_key, pool_row = row_id)], by.x = "nm", by.y = "sp_key")[
  , .(species, pool_row, tier = "T1 exact")]
rest <- setdiff(evn$species, e1$species)
e3 <- if (length(rest)) {
  r <- evn[species %in% rest][, ep := epith(species)]
  cand <- merge(r[!is.na(fam)], cn[, .(ep, fam, pool_row = row_id)], by = c("ep", "fam"),
                allow.cartesian = TRUE)
  cand[, n := .N, by = species]
  cand[n == 1L, .(species, pool_row, tier = "T3 epithet within family")]
} else NULL
emap <- rbindlist(list(e1, e3), fill = TRUE)
msg("事件物种 ", nrow(evn), " -> 物种池: ", nrow(emap),
    sprintf(" (%.1f%%) | %s", 100 * nrow(emap) / nrow(evn),
            paste(sprintf("%s=%d", names(table(emap$tier)), table(emap$tier)), collapse = " ")))
unres <- setdiff(evn$species, emap$species)
if (length(unres)) msg("  未解析(", length(unres), "): ", paste(head(unres, 10), collapse = ", "))

cnt <- merge(ev[, .N, by = species], emap[, .(species, pool_row)], by = "species")[
  , .(n_new_records_v2 = sum(N)), by = pool_row]
d <- merge(d, cnt, by.x = "row_id", by.y = "pool_row", all.x = TRUE)
d[is.na(n_new_records_v2), n_new_records_v2 := 0L]
d[, new_record_v2 := as.integer(n_new_records_v2 > 0)]
msg("v2 二元响应: ", sum(d$new_record_v2), " / ", nrow(d), " 种 | 事件计入 ",
    sum(d$n_new_records_v2), " / ", nrow(ev))

# ---- 4. 派生分类变量 ----
# 体重与窝卵数: 中国库 -> BIRDBASE -> AVONET
d[!is.finite(mass_g_final) & is.finite(mass_bb), `:=`(mass_g_final = mass_bb, mass_source = "BIRDBASE")]
d[!is.finite(mass_g_final) & is.finite(mass_av), `:=`(mass_g_final = mass_av, mass_source = "AVONET")]
d[is.na(mass_source) & is.finite(mass_g_final), mass_source := "Chinese database"]
d[!is.finite(clutch_final) & is.finite(clutch_bb), `:=`(clutch_final = clutch_bb, clutch_source = "BIRDBASE")]
d[is.na(clutch_source) & is.finite(clutch_final), clutch_source := "Chinese database"]
msg("体重来源: ", paste(sprintf("%s=%d", names(table(d$mass_source)), table(d$mass_source)), collapse = " | "))
msg("窝卵数来源: ", paste(sprintf("%s=%d", names(table(d$clutch_source)), table(d$clutch_source)), collapse = " | "))

d[, iucn_group := fifelse(iucn == "LC", "Least Concern",
                   fifelse(iucn == "NT", "Near Threatened",
                   fifelse(iucn %in% c("VU", "EN", "CR"), "Threatened", NA_character_)))]
d[, trophic_niche := fifelse(trophic_niche_av %in% c("Frugivore", "Nectarivore"), "Frugivore/Nectarivore",
                      fifelse(trophic_niche_av %in% c("Herbivore aquatic", "Herbivore terrestrial"), "Herbivore",
                      fifelse(trophic_niche_av %in% c("Vertivore", "Scavenger"), "Vertivore/Scavenger",
                              trophic_niche_av)))]
d[, habitat_density := fifelse(habitat_density_av == "1", "Dense",
                        fifelse(habitat_density_av == "2", "Semi-open",
                        fifelse(habitat_density_av == "3", "Open", NA_character_)))]

NUMV <- c("mass_g_final", "clutch_final", "hwi_final", "provinces_final", "n_congeners",
          "habitat_breadth", "diet_breadth", "esi", "diet_n_china",
          "length_cn", "wing_cn", "tarsus_cn")
CATV <- c("migration_final", "endemic_final", "iucn_group", "trophic_niche",
          "habitat_density", "nest_type_c", "nest_site_c", "flocking_c")
cov0 <- rbindlist(lapply(c(NUMV, CATV), function(v)
  data.table(trait = v, before_imputation = round(100 * mean(!is.na(d[[v]]) &
                                                             nzchar(as.character(d[[v]]))), 2))))

# ---- 5. 随机森林插补 ----
for (v in c(NUMV, CATV)) d[[paste0(v, "_imputed")]] <-
  is.na(d[[v]]) | (is.character(d[[v]]) & !nzchar(as.character(d[[v]])))
if (requireNamespace("missForest", quietly = TRUE)) {
  X <- d[, c(NUMV, CATV), with = FALSE]
  for (v in NUMV) X[[v]] <- as.numeric(X[[v]])
  for (v in CATV) { x <- as.character(X[[v]]); x[!nzchar(x)] <- NA; X[[v]] <- factor(x) }
  set(X, j = "order_f",  value = factor(d$order_cn))
  set(X, j = "family_f", value = factor(d$family_cn))
  ok <- vapply(X, function(c) sum(!is.na(c)) > 0 &&
                 (!is.factor(c) || nlevels(droplevels(c[!is.na(c)])) > 1), logical(1))
  X <- X[, names(ok)[ok], with = FALSE]
  for (v in names(X)) if (is.factor(X[[v]])) X[[v]] <- droplevels(X[[v]])
  msg("随机森林插补: ", ncol(X), " 变量 | 缺失单元 ", sum(is.na(X)),
      sprintf(" (%.2f%%)", 100 * mean(is.na(X))))
  fit <- missForest::missForest(as.data.frame(X), maxiter = 6, ntree = 300, verbose = FALSE)
  msg("  OOB: ", paste(sprintf("%s=%.4f", names(fit$OOBerror), fit$OOBerror), collapse = " | "))
  Xi <- as.data.table(fit$ximp)
  for (v in intersect(c(NUMV, CATV), names(Xi)))
    d[[v]] <- if (v %in% NUMV) as.numeric(Xi[[v]]) else as.character(Xi[[v]])
  fwrite(data.table(metric = names(fit$OOBerror), value = as.numeric(fit$OOBerror)),
         file.path(OUT, "tables", "tbl_v2_trait_imputation_oob.csv"))
}

# ---- 6. 报告 ----
cov <- merge(cov0, rbindlist(lapply(c(NUMV, CATV), function(v)
  data.table(trait = v,
             after_imputation = round(100 * mean(!is.na(d[[v]]) & nzchar(as.character(d[[v]]))), 2),
             n_imputed = sum(d[[paste0(v, "_imputed")]])))), by = "trait")
setorder(cov, before_imputation); print(cov)
fwrite(cov, file.path(OUT, "tables", "tbl_v2_trait_coverage.csv"))

res <- rbind(d[, .(step = "BIRDBASE", .N), by = .(tier = bb_tier)],
             d[, .(step = "AVONET",   .N), by = .(tier = av_tier)],
             d[, .(step = "phylogeny", .N), by = .(tier = fifelse(is.na(tree_label), NA_character_, "T1 exact"))],
             emap[, .(step = "events -> pool", .N), by = tier], fill = TRUE)
print(res[!is.na(tier)]); fwrite(res, file.path(OUT, "tables", "tbl_v2_trait_resolution.csv"))
for (v in c("habitat_breadth", "diet_breadth", "esi", "diet_n_china"))
  msg(v, ": 中位 ", round(median(d[[v]], na.rm = TRUE), 2), " | 范围 ",
      round(min(d[[v]], na.rm = TRUE), 2), "-", round(max(d[[v]], na.rm = TRUE), 2))

setorder(d, row_id)
fwrite(d, file.path(OUT, "data", "species_traits_harmonised_v2.csv"))
msg("wrote species_traits_harmonised_v2.csv (", nrow(d), " 种, ", ncol(d), " 列) | DONE")
