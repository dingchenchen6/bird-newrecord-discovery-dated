#!/usr/bin/env python3.11
# ============================================================
# Scientific question / 科学问题:
#   无(发布步骤)。让公开仓库与任务目录的最新结果、图件与投稿包一致。
#   None (release step): keep the public repository in step with the task directory.
#
# Objective / 分析目标:
#   把任务目录同步到本地克隆 ~/bird-newrecord-discovery-dated, 只改工作区, 不提交。
#   Sync the task directory into the local clone; working tree only, no commit.
#
# Input data / 输入数据: 任务目录 code/ 与 analysis_v2/{figures*,tables,docs,submission}/
# Main workflow / 主要流程:
#   1. 仓库已跟踪文件: 有源且内容不同 → 覆盖 / tracked files: overwrite when changed
#   2. 新内容: submission/、figures_topjournal/、figures_direction/、tables/、205 号起的新脚本
#   3. submission/ 镜像删除: 任务目录已移除的投稿件在仓库中也删除
#   4. 跳过: 上传压缩包、Office 锁文件、> 95 MB 的文件(GitHub 单文件上限 100 MB)
# Expected output / 预期输出: 仓库工作区改动 + 同步摘要(新增/更新/删除/跳过)
# Key assumptions / 关键假设:
#   仓库路径 P ↔ 任务目录 analysis_v2/P(图表文档投稿包)或 P(code);
#   figures_en/x ↔ analysis_v2/figures_multiscale/en/x 或 figures_pa/en/x。
# Main packages / 主要包: 标准库 / standard library
# Output directory / 输出路径: ~/bird-newrecord-discovery-dated(工作区)
#
# Usage: python3.11 code/220_sync_public_repo.py [--dry-run]
# ============================================================
from __future__ import annotations

import filecmp
import logging
import re
import shutil
import subprocess
import sys
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="[220] %(message)s")
logger = logging.getLogger(__name__)

V2 = Path(__file__).resolve().parent.parent
A2 = V2 / "analysis_v2"
REPO = Path.home() / "bird-newrecord-discovery-dated"
MAX_MB = 95
FIRST_NEW = 205
NEW_DIRS = ["submission", "figures_topjournal", "figures_direction", "tables"]   # 新文件也同步的目录
SKIP_PARTS = {"_archives", ".DS_Store"}
DRY = "--dry-run" in sys.argv


def skip(p: Path) -> bool:
    return (bool(SKIP_PARTS & set(p.parts)) or p.name.startswith("~$") or p.name.startswith(".")
            or p.suffix == ".zip" or p.stat().st_size > MAX_MB * 1e6)


def source_for(rel: str) -> Path | None:
    """仓库相对路径 → 任务目录源文件 / repo path -> task source."""
    top, _, rest = rel.partition("/")
    cands = [V2 / rel] if top == "code" else [A2 / rel]
    if top == "figures_en":
        cands += [A2 / "figures_multiscale/en" / rest, A2 / "figures_pa/en" / rest]
    return next((c for c in cands if c.is_file()), None)


def tracked() -> list[str]:
    out = subprocess.run(["git", "-C", str(REPO), "ls-files", "-z"], capture_output=True, check=True).stdout
    return [x.decode() for x in out.split(b"\0") if x]


def copy(src: Path, dst: Path) -> None:
    if not DRY:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)


def main() -> None:
    if not (REPO / ".git").exists():
        sys.exit(f"找不到仓库克隆 / clone not found: {REPO}")
    files = tracked()
    tset = set(files)
    upd = add = rm = skipped = 0
    # 1 已跟踪文件 / tracked files
    for rel in files:
        src = source_for(rel)
        dst = REPO / rel
        if src is None:
            continue
        if src.stat().st_size > MAX_MB * 1e6:
            skipped += 1
            continue
        if not dst.exists() or not filecmp.cmp(src, dst, shallow=False):
            copy(src, dst)
            upd += 1
    # 2 新内容 / new content
    for d in NEW_DIRS:
        root = A2 / d
        for src in sorted(root.rglob("*")):
            if not src.is_file() or skip(src):
                if src.is_file() and src.stat().st_size > MAX_MB * 1e6:
                    logger.warning("跳过超限文件 / skipped > %d MB: %s", MAX_MB, src.relative_to(A2))
                    skipped += 1
                continue
            rel = str(src.relative_to(A2))
            if rel not in tset:
                copy(src, REPO / rel)
                add += 1
    for src in sorted((V2 / "code").iterdir()):
        m = re.match(r"(\d+)", src.name)
        if src.is_file() and m and int(m.group(1)) >= FIRST_NEW and src.suffix in {".R", ".py"}:
            rel = f"code/{src.name}"
            if rel not in tset:
                copy(src, REPO / rel)
                add += 1
    # 3 submission/ 镜像删除 / mirror deletions inside submission/
    for rel in files:
        if rel.startswith("submission/") and source_for(rel) is None:
            if not DRY:
                subprocess.run(["git", "-C", str(REPO), "rm", "-q", "--cached", rel], check=True)
                (REPO / rel).unlink(missing_ok=True)
            rm += 1
    logger.info("%s更新 %d、新增 %d、删除 %d、跳过 %d / updated, added, removed, skipped",
                "[演练 / dry run] " if DRY else "", upd, add, rm, skipped)


if __name__ == "__main__":
    main()
