#!/usr/bin/env python3.11
# ============================================================
# Scientific question / 科学问题:
#   无(打包步骤)。让审稿人仅凭投稿包即可复现主模型与全部图表。
#   None (packaging step): reviewers can reproduce the main model and every
#   display item from the submission package alone.
#
# Objective / 分析目标:
#   生成 submission/data_and_code/:公开仓库复现核心的冻结快照
#   (代码、建模数据、结果表、搭建与冒烟测试脚本、运行环境)
#   加上按三刊图号整理的主图源数据, 并打包上传用压缩包。
#   Build a frozen snapshot of the public repository's reproducibility core plus
#   journal-numbered source data for every main figure, and zip it for upload.
#
# Input data / 输入数据:
#   任务目录 code/、analysis_v2/tables/、figures_topjournal/source_data_*.csv;
#   公开仓库克隆 ~/bird-newrecord-discovery-dated 中的 data/、data_admin/、
#   config.R、setup_workspace.R、tests/、docs/、LICENSE
#
# Main workflow / 主要流程:
#   1. 清空并重建 data_and_code/ / rebuild the folder from scratch
#   2. 代码 = 仓库已收录脚本 ∪ 任务目录 205 号以后的新脚本(任务目录版本优先)
#   3. 数据与结果表原样复制; 主图源数据按各刊编号命名
#   4. 写运行环境(renv.lock、R sessionInfo、Python 包版本)与 README
#   5. 压缩为 _archives/data_and_code_<日期>.zip 并校验
#
# Expected output / 预期输出: analysis_v2/submission/data_and_code/ 与压缩包
# Key assumptions / 关键假设:
#   BirdLife 分布图、eBird/GBIF 原始下载与气候栅格不可再分发或体量过大,
#   只给来源与获取方式(见 config.R)。
# Main packages / 主要包: 标准库 + 已安装的 R / standard library + installed R
# Output directory / 输出路径: analysis_v2/submission/data_and_code/
#
# Usage: python3.11 code/219_data_code_package.py
# ============================================================
from __future__ import annotations

import datetime
import importlib.util
import logging
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="[219] %(message)s")
logger = logging.getLogger(__name__)

V2 = Path(__file__).resolve().parent.parent
A2 = V2 / "analysis_v2"
SUB = A2 / "submission"
OUT = SUB / "data_and_code"
TJ = A2 / "figures_topjournal"
REPO = Path.home() / "bird-newrecord-discovery-dated"
DATE = datetime.date.today().strftime("%Y%m%d")
REPO_URL = "https://github.com/dingchenchen6/bird-newrecord-discovery-dated"
FIRST_NEW = 205        # 205 号起为投稿包与图件脚本, 仓库尚未收录 / scripts from 205 on are new
EXTRA_CODE = ("191b_province_bootstrap_fill.R",)   # 编号小于 205 的新增脚本(补跑丢失的自助法重抽样)
                                                  # new scripts numbered below 205 (bootstrap refill)



def _load_217():
    """复用 217 的图件清单解析(不执行装配脚本)/ reuse 217's list parser."""
    spec = importlib.util.spec_from_file_location("m217", V2 / "code/217_editable_figures.py")
    m = importlib.util.module_from_spec(spec)
    sys.modules["m217"] = m
    spec.loader.exec_module(m)
    return m


def main_figure_sources() -> dict[str, list[tuple[str, Path]]]:
    """各刊主图编号 → 源图路径(与 217 共用一份映射)/ shared with 217."""
    return _load_217().main_figure_sources()


def copy_tree(src: Path, dst: Path, pattern: str = "*") -> int:
    """复制目录中的文件(跳过隐藏文件)/ copy files, skipping hidden ones."""
    dst.mkdir(parents=True, exist_ok=True)
    n = 0
    for f in sorted(src.glob(pattern)):
        if f.name.startswith(".") or f.is_dir():
            continue
        shutil.copy2(f, dst / f.name)
        n += 1
    return n


def build_code() -> list[str]:
    """仓库已收录脚本 ∪ 新脚本;同名时用任务目录的最新版 / union of repo and new scripts."""
    dst = OUT / "code"
    dst.mkdir(parents=True)
    names = {f.name for f in (REPO / "code").iterdir() if f.is_file() and not f.name.startswith(".")}
    for f in (V2 / "code").iterdir():
        m = re.match(r"(\d+)", f.name)
        if f.is_file() and m and int(m.group(1)) >= FIRST_NEW and f.suffix in {".R", ".py"}:
            names.add(f.name)
        # 无编号的共用函数与重跑驱动脚本 / unnumbered shared helpers and rerun drivers
        if f.is_file() and (re.match(r"(helper_.*\.R|rerun_.*\.sh)$", f.name) or f.name in EXTRA_CODE):
            names.add(f.name)
    for name in sorted(names):
        src = V2 / "code" / name if (V2 / "code" / name).exists() else REPO / "code" / name
        shutil.copy2(src, dst / name)
    return sorted(names)


def build_source_data() -> list[str]:
    """主图源数据按各刊编号命名;优先用顶刊版的完整长表 / journal-numbered source data."""
    rows = []
    for J, figs in main_figure_sources().items():
        d = OUT / "source_data" / J
        d.mkdir(parents=True, exist_ok=True)
        for label, base in figs:
            tj = TJ / f"source_data_{_load_217().TJ_NAME.get(base.name, '')}.csv"
            orig = base.parent / f"source_data_{base.name}.csv"
            src = tj if tj.exists() else (orig if orig.exists() else None)
            if src is None:
                logger.warning("%s %s: 无源数据 / no source data for %s", J, label, base.name)
                continue
            shutil.copy2(src, d / f"Source_Data_{label}.csv")
            rows.append(f"| {J} | {label} | `{base.name}` | `{src.name}` |")
    return rows


def write_environment() -> None:
    env = OUT / "environment"
    env.mkdir()
    shutil.copy2(V2 / "renv.lock", env / "renv.lock")
    r = subprocess.run(["Rscript", "--no-init-file", "-e",
                        "suppressMessages({library(glmmTMB); library(data.table); library(ggplot2); library(sf)}); "
                        "print(sessionInfo())"], capture_output=True, text=True, timeout=600)
    (env / "R_sessionInfo.txt").write_text(r.stdout or r.stderr, encoding="utf-8")
    pkgs = ["python-docx", "python-pptx", "PyMuPDF", "Pillow", "numpy"]
    r = subprocess.run([sys.executable, "-m", "pip", "show", *pkgs], capture_output=True, text=True)
    vers = re.findall(r"Name: (.+)\nVersion: (.+)", r.stdout)
    (env / "python_packages.txt").write_text(
        f"Python {sys.version.split()[0]}\n" + "".join(f"{n}=={v}\n" for n, v in vers), encoding="utf-8")
    for doc in ("ENVIRONMENT.md", "DATA_DICTIONARY.md"):
        shutil.copy2(REPO / "docs" / doc, env / doc)


README = """# Data and code for the submission

Frozen snapshot ({date}) of the reproducibility core of the public repository
<{url}>, prepared for peer review. It reproduces the main model and every
display item of the manuscript. The repository remains the maintained version.

## Contents

| Folder / file | What it holds |
|---|---|
| `code/` | Analysis pipeline ({n_code} scripts). Scripts 130–154 fit and summarise the models; 160–192 run the conservation, downscaling, machine-learning and null-model modules; 200–221 build the submission package, the figures, their editable versions and the animated map used in the talk; 222–230 correct the 2024 survey effort (eBird 2024 added from GBIF download https://doi.org/10.15468/dl.vfeeak), drive the full rerun (`rerun_effort2024_*.sh`) and trace every changed number; 231 re-renders the .docx files built directly from .md and checks their numbers; `helper_projection_base.R` completes the projection base year; `191b` refits the 50 province-bootstrap resamples lost to a worker crash in 191 (same seeds), restoring all 300. Run in numerical order. |
| `data/`, `data_admin/` | Modelling data: discovery-dated events, effort panel, model matrices (three thresholds), climate panels, traits, protected-area and administrative-unit tables ({data_mb:.0f} MB) |
| `tables/` | Every result table cited in the manuscript and the Supplementary Information |
| `source_data/{{GCB,NEE,NC}}/` | Source data for each main figure, named by that journal's figure number (long format, one row per plotted value, `panel` column) |
| `environment/` | `renv.lock`, R `sessionInfo()`, Python package versions, environment notes and the data dictionary |
| `setup_workspace.R`, `tests/smoke_test.R` | Build the working layout, then refit the main model and check it against the published coefficients (about two minutes) |
| `config.R` | Paths to external inputs that are not redistributed (below) |

## Quick start

```bash
Rscript --no-init-file setup_workspace.R
Rscript --no-init-file tests/smoke_test.R
```

Run both from this folder. R 4.5 with the packages listed in `environment/renv.lock`
(glmmTMB, data.table, arrow, ggplot2, patchwork, sf) is sufficient for scripts 131–154.

## External inputs (not redistributed)

- **CBNR v2**, the record compilation: CC BY 4.0, <https://doi.org/10.5281/zenodo.20809949> (input of script 130).
- **Species range maps** (BirdLife International and Handbook of the Birds of the World, 2024):
  available on request from BirdLife; the licence does not permit redistribution.
- **Climate**: WorldClim 2.1 downscaling of CRU TS 4.09 and CMIP6 projections, <https://www.worldclim.org>.
- **Standard base map** GS(2019)1822, Ministry of Natural Resources of China, <http://bzdt.ch.mnr.gov.cn/>.

The distributed panels already contain every derived quantity these inputs supply, so only
upstream rebuilds (scripts 130, 132 from raw panels, 141 maps) need them; set their paths in `config.R`.

## Source data map

| Journal | Figure | Source figure | File copied |
|---|---|---|---|
{sd_rows}

The submitted figures and their redesigned versions (`figures_polished/` in each journal folder)
plot the same values; both are documented by the files above.

## Licence

Code: MIT (`LICENSE`). Data derived from CBNR: CC BY 4.0, cite the dataset DOI above.
"""


def zip_folder() -> Path:
    arch = SUB / "_archives"
    arch.mkdir(exist_ok=True)
    for old in arch.glob("data_and_code_*.zip"):
        old.unlink()
    z = arch / f"data_and_code_{DATE}.zip"
    with zipfile.ZipFile(z, "w", zipfile.ZIP_DEFLATED) as zf:
        for f in sorted(OUT.rglob("*")):
            if f.is_file() and not f.name.startswith("."):
                zf.write(f, Path("data_and_code") / f.relative_to(OUT))
    with zipfile.ZipFile(z) as zf:
        if zf.testzip() is not None:
            sys.exit("压缩包损坏 / zip corrupt")
    return z


def main() -> None:
    if "--zip-only" in sys.argv:             # wm-clean 之后只重打压缩包 / rezip after cleaning
        z = zip_folder()
        logger.info("重打压缩包 / rezipped: %s (%.1f MB)", z.name, z.stat().st_size / 1e6)
        return
    if not (REPO / "code").is_dir():
        sys.exit(f"找不到仓库克隆 / repository clone not found: {REPO}")
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    names = build_code()
    n_data = copy_tree(REPO / "data", OUT / "data")
    for sub in ("admin", "pa"):
        if (REPO / "data" / sub).is_dir():
            n_data += copy_tree(REPO / "data" / sub, OUT / "data" / sub)
    n_admin = copy_tree(REPO / "data_admin", OUT / "data_admin")
    n_tab = copy_tree(A2 / "tables", OUT / "tables", "*.csv")
    for f in ("config.R", "setup_workspace.R", "LICENSE"):
        shutil.copy2(REPO / f, OUT / f)
    (OUT / "tests").mkdir()
    shutil.copy2(REPO / "tests/smoke_test.R", OUT / "tests/smoke_test.R")
    sd_rows = build_source_data()
    write_environment()
    data_mb = sum(f.stat().st_size for d in ("data", "data_admin") for f in (OUT / d).rglob("*") if f.is_file()) / 1e6
    (OUT / "README.md").write_text(README.format(date=DATE, url=REPO_URL, n_code=len(names), data_mb=data_mb,
                                                 sd_rows="\n".join(sd_rows)), encoding="utf-8")
    z = zip_folder()
    logger.info("代码 %d、数据 %d(+行政单元 %d)、结果表 %d、源数据 %d → %s(%.1f MB)",
                len(names), n_data, n_admin, n_tab, len(sd_rows), z.name, z.stat().st_size / 1e6)


if __name__ == "__main__":
    main()
