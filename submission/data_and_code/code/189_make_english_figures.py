#!/usr/bin/env python3.11
# ============================================================
# 为投稿生成英文版图件 / Generate English figure variants for submission.
#
# 问题 / Problem:
#   脚本 166、185–188 产出的 9 张图使用中文标签,但它们被嵌入三家英文期刊的 SI。
#   英文刊的图件必须全英文,否则会在编辑部初审即被退回。
#
# 做法 / Approach:
#   不改动原脚本(会议 deck 仍用中文版),而是机械派生 `*_en.R`:
#     1. 保护不可翻译的字符串 —— shapefile 文件名、shapefile 属性列名,
#        以及脚本 185 中用于筛选 CSV 的数据值(它们是数据内容,不是显示文本);
#     2. 只在字符串字面量内做中→英替换(注释与代码结构不动),按长度降序
#        避免前缀碰撞(如「离散风险模型」是「离散风险模型(边际)」的前缀);
#     3. 把 D_FG 重定向到 `<原目录>/en/`,文件名不变;
#     4. 对 185 的 split 因子做定点改写:筛选保持中文数据值,显示标签转英文。
#   最后用中文字符检测验收:任何残留都会在生成的 PDF 里被查出来。
#
# Input  / 输入: code/{166,185,186,187,188}*.R
# Output / 输出: code/*_en.R  →  analysis_v2/figures_{pa,multiscale}/en/*.{png,pdf}
# Run: python3.11 code/189_make_english_figures.py && 逐个 Rscript 运行 *_en.R
# ============================================================
from __future__ import annotations
import re
import pathlib

CODE = pathlib.Path(__file__).parent
CJK = re.compile(r"[一-鿿]")
STRLIT = re.compile(r'"(?:[^"\\]|\\.)*"')

# 绝不翻译:shapefile 名、属性列名 / never translate: shapefile names and attribute columns
GLOBAL_PROTECT = ["省（等积投影）.shp", "市（等积投影）.shp", "县（等积投影）.shp",
                  "九段线.shp", "国界.shp", "省"]
# 脚本 185 用于筛选 CSV 的数据值 / data values used to filter CSVs in script 185
PROTECT_185 = ["离散风险模型(条件)", "离散风险模型(边际)", "随机森林(类平衡)",
               "XGBoost(类平衡)", "条件 logit (M3)", "M3 分配模型",
               "^时间", "时间前推 2019–2024", "留一省"]

T = {
    # ---------------- 166 保护地图件 ----------------
    "a  基准对比:事件 vs 观鸟努力 vs 面积": "a  Baseline: events vs effort vs area",
    "全国尺度上观鸟努力并未向保护区集中,新纪录却集中":
        "New records concentrate in reserves; birding effort does not",
    "新纪录事件": "New records",
    "观鸟 checklist\\n(按努力加权)": "Birding checklists\\n(effort-weighted)",
    "观鸟地点\\n(等权)": "Birding locations\\n(equal weight)",
    "陆域面积": "Land area",
    "落在自然保护区内的比例 (%)": "Share falling inside nature reserves (%)",
    "b  条件 logistic:同省同年 1:200 匹配":
        "b  Conditional logistic: 1:200 matched controls",
    "对照 = 观鸟人当年在该省实际去过的地点":
        "Controls: locations birders visited in that province-year",
    "保护区内 vs 区外的优势比 (95% CI)": "Inside-vs-outside odds ratio (95% CI)",
    "A0 仅暴露": "A0 exposure only",
    "A1 +选址几何": "A1 + siting geometry",
    "L 国家级": "L national-level",
    "按地点等权的对照": "Location-equal controls",
    "按观测努力加权的对照": "Effort-weighted controls",
    "c  稳健性:效应由少数保护区与近十年撑起":
        "c  Robustness",
    "剔除前两大宿主保护区后 CI 覆盖 1;2002-2012 无效应":
        "Dropping the two largest hosts brings the CI over unity; none in 2002-2012",
    "条件优势比 (95% CI)": "Conditional odds ratio (95% CI)",
    "d  区内事件高度集中": "d  Inside-reserve events are concentrated",
    "%d 条区内事件只落在 %d 处保护区(全部 1028 处中的 %.1f%%)":
        "%d events in only %d reserves (%.1f%% of 1,028)",
    "宿主保护区(按区内事件数降序)": "Host reserves (ranked by inside-reserve events)",
    "累计占比 (%)": "Cumulative share (%)",
    "前 %d 处保护区\\n即占区内事件的一半": "The top %d reserves\\nhold half the inside events",
    "a  再检出的原始比例": "a  Raw re-detection rate",
    "此后至少再检出 1 次": "Re-detected in ≥1 later year",
    "此后 ≥3 个年份被检出的比例": "Proportion re-detected in ≥3 later years",
    "此后 ≥3 个年份被检出": "Re-detected in ≥3 later years",
    "保护区内": "Inside reserve",
    "保护区外": "Outside reserve",
    "被再检出的比例": "Proportion re-detected",
    "b  控制后续观测努力与年份后": "b  After controlling for subsequent effort and year",
    "绿带为预先声明的等价界 [0.67, 1.5];CI 稍宽于等价界,判为不确定而非无差异":
        "Green band: pre-declared equivalence bounds [0.67, 1.5]; the intervals are\nslightly wider, so we report no detectable difference rather than equivalence",
    "c  决定再检出的是后续观测努力": "c  Re-detection is governed by subsequent survey effort",
    "再检出率随后续 checklist 量陡升;区内外差异在各努力档内均不可分辨":
        "Re-detection rises steeply with checklist volume; inside-outside differences\nare indistinguishable within every effort band",
    "首次记录之后该省累计 checklist 量 (log)":
        "Cumulative provincial checklists after the first record (log)",
    "d  右删失:越晚的首次记录后续窗口越短":
        "d  Right-censoring: later first records have shorter follow-up",
    "因此主分析限定在 2020 年及以前的事件":
        "The main analysis is therefore restricted to events up to 2020",
    "首次记录年份": "Year of first record",
    "首次记录后被再检出的比例": "Proportion re-detected after the first record",
    "以 GBIF/eBird 同种同省的后续年份检出为存续代理":
        "Persistence proxied by later-year detections of the same species in the same province",
    "a  「保护区都建在增温慢的地方」是口径造成的":
        "a  'Reserves sit where warming is slow' is an artefact",
    "省级广播口径给出 8.5 倍落差;格级实测口径下落差仅 1.2 倍":
        "Provincial broadcast implies an 8.5-fold spread; cell-level only 1.2-fold",
    "省级广播口径(原 grid 文件)": "Provincial broadcast (original grid file)",
    "格级实测口径(CRU TS 4.09 重算)": "Cell-level (recomputed from CRU TS 4.09)",
    "增温速率五分位(Q1 最慢 → Q5 最快)": "Warming-rate quintile (Q1 slowest → Q5 fastest)",
    "面积加权保护地覆盖率": "Area-weighted reserve coverage",
    "b  分层置换检验:省内无配置偏倚": "b  Stratified permutation: no siting bias within provinces",
    "999 次层内重排;观测值落在零分布内部":
        "999 within-stratum shuffles; the observed value lies inside the null distribution",
    "省 × 海拔带分层内的 Spearman ρ(保护地覆盖 vs 增温)":
        "Within-stratum Spearman ρ (coverage vs warming)",
    "置换零分布密度": "Permutation null density",
    "  观测 ρ = %.3f\\n  P = %.2f": "  observed ρ = %.3f\\n  P = %.2f",
    "c  监测嫁接优先级": "c  Monitoring-grafting priority",
    "高增温三分位 × 低近期观测三分位;底图 GS(2019)1822":
        "Upper warming tercile × lower recent-effort tercile; basemap GS(2019)1822",
    "A 嫁接到已建保护区": "A graft onto existing reserves",
    "B 保护体系外,需另投调查": "B outside the reserve system",
    "C 高暴露但已有观测": "C high exposure, already surveyed",
    "D 其他": "D other",
    "d  两类监测缺口的量级": "d  Magnitude of the two monitoring gaps",
    "A 类可直接嫁接到已建保护区的管理机构;B 类必须另投调查力量":
        "Class A grafts onto existing reserve administrations; class B needs new capacity",
    "面积 (万 km²)": "Area (10⁴ km²)",
    "%d 格 · 区内覆盖 %.0f%%": "%d cells · %.0f%% inside reserves",
    "\\n全部保护地图件已输出到 ": "\\nAll reserve figures written to ",
    # ---------------- 185 多模型多尺度(当前面) ----------------
    "三族模型 × 三个尺度的当前预测面(2024)":
        "Present-day prediction surfaces: three model families × three scales (2024)",
    "每列为族内自洽的两段式:省级期望数 × 省内分配份额;色标行内共享(log10)。":
        "Each column is a self-consistent two-stage pipeline: provincial expectation × within-province allocation share; colour scales are shared within rows (log10). ",
    "机制面 = 冻结主模型 + 条件 logit;RF / XGBoost 为类平衡变体。\\n":
        "\nMechanistic = frozen main model + conditional logit; RF and XGBoost are class-balanced variants.\\n",
    "省级 ρ:机制-RF %.2f · 机制-XGB %.2f · RF-XGB %.2f":
        "Province ρ: mech–RF %.2f · mech–XGB %.2f · RF–XGB %.2f",
    "\\n%s ρ:机制-RF %.2f · 机制-XGB %.2f · RF-XGB %.2f":
        "\\n%s ρ: mech–RF %.2f · mech–XGB %.2f · RF–XGB %.2f",
    "底图:审图号 GS(2019)1822(主图全幅含南海诸岛与九段线)。Basemap GS(2019)1822.":
        "Basemap GS(2019)1822; the full-extent maps include the South China Sea islands and the nine-dash line.",
    "a  省级:内插时树模型领先,外推时机制模型追平或反超":
        "a  Tree ensembles lead on interpolation; the mechanistic model wins on extrapolation",
    "机制模型:随机折取条件预测(BLUP 可用),其余方案取边际;RF 与 XGBoost 取类平衡变体;误差线为折间 SD":
        "Mechanistic: conditional prediction on random folds, marginal elsewhere. RF and XGBoost class-balanced. Error bars: fold SD",
    "b  市县分配:时间前推三族打平;换到新省份,机制模型优势最大":
        "b  Allocation: families tie on temporal splits; the mechanistic model gains most on new provinces",
    "同一批 2019–2024 事件与同一特征集;留一省 = 把整省移出训练集后预测该省":
        "Same 2019-2024 events and feature set; leave-one-province holds a whole province out before predicting it",
    "被选中单元的预测排名分位(越小越好)": "Predicted rank percentile of the chosen unit (lower is better)",
    "事件率 0.369%": "Event rate 0.369%",
    "随机 = 0.5": "Random = 0.5",
    "随机 5 折": "Random 5-fold",
    "留物种 5 折": "Leave-species 5-fold",
    "留省 5 折": "Leave-province 5-fold",
    "时间前推\\n2019–2024": "Temporal\\n2019–2024",
    "预测新纪录数(2024,": "Predicted new records (2024, ",
    "预测新纪录数(2024)": "Predicted number of new records (2024)",
    "预测新纪录数(市级)": "Predicted new records (prefecture)",
    "预测新纪录数(县级)": "Predicted new records (county)",
    "a  省级:预测新纪录数(2024)": "a  Province: predicted new records (2024)",
    "b  市级落点": "b  Prefecture-level landing",
    "c  县级落点": "c  County-level landing",
    "读取底图 / basemap": "reading basemap",
    "FigMS1w(横版三联)": "FigMS1w (wide three-scale panel)",
    # ---------------- 186 时空格局 ----------------
    "a  %s 条新纪录的空间分布(点色 = 年份)":
        "a  %s new records (colour = year)",
    "b  省级累计新纪录数(2000–2025)": "b  Cumulative records per province",
    "c  年度记录数持续上升": "c  Annual record counts rise steadily",
    "柱:发布口径(报告年份);黑线:建模子集按发现年 —— 两者的错位即定年校正的动机":
        "Bars: reported year; line: modelled subset by discovery year",
    "d  记录位置的时间漂移": "d  Temporal drift in record location",
    "每点一条记录;灰带为 loess ± SE": "One point per record; grey band is loess ± SE",
    "记录年份": "Year of record",
    "累计新纪录数": "Cumulative new records",
    "记录数 / 年": "Records per year",
    "纬度": "Latitude",
    "经度": "Longitude",
    "数据:China Bird New Record (CBNR) 数据集,Zenodo 记录 20809949(CC-BY-4.0);剔除坐标异常 %d 条。":
        "Data: China Bird New Record (CBNR), Zenodo record 20809949 (CC-BY-4.0); %d records with implausible coordinates excluded. ",
    "底图:审图号 GS(2019)1822。": "Basemap GS(2019)1822.",
    "剔除坐标异常 ": "dropped implausible coordinates: ",
    "发布版记录 ": "released records: ",
    " 条,": " records, ",
    " 种,": " species, ",
    " 省级单元,年份 ": " provincial units, years ",
    " 条": " records",
    # ---------------- 187 未来情景(机制) ----------------
    "未来情景下的预测新纪录数:气候情景 × 调查努力情景(2030 / 2050)":
        "Predicted new records under future scenarios: climate scenario × survey-effort scenario (2030 / 2050)",
    "离散风险主模型;气候 delta 取 CMIP6 4-GCM 集成中位,分别施加于省端与物种分布区端;":
        "Frozen discrete-time hazard model; CMIP6 four-model ensemble median deltas\napplied separately to the provincial and species-range ends of the gradient; ",
    "努力停滞 = 冻结于 2024,努力延续 = +0.6 SD/十年(历史观测增速约 1.2)。\\n":
        "effort frozen at 2024, or continuing at +0.6 SD per decade (observed pace ≈ 1.2).\\n",
    "透明度 = 该省落在训练协变量支撑域(1–99 百分位)内的比例;":
        "Transparency encodes the fraction of species–province cells inside the fitted covariate support (1st–99th percentile); ",
    "县级行为份额冻结假设(省内分配取 2024 机制面),色标行内共享(log10)。":
        "the county row assumes frozen 2024 allocation shares; colour scales are shared within rows (log10).",
    "预测新纪录数(县级,2050)": "Predicted new records (county, 2050)",
    "c  2050 县级:": "c  2050, county: ",
    "主模型已载入;基期 ": "main model loaded; baseline year ",
    "\\n== 全国期望新纪录数 × 情景 ==\\n": "\\n== National expected new records × scenario ==\\n",
    # ---------------- 188 未来情景 × 模型族 ----------------
    "未来情景预测(2050):模型族 × 气候情景 × 调查努力情景":
        "Future projections for 2050: model family × climate scenario × survey-effort scenario",
    "行=模型族,列=情景;色标全图共享(log10);透明度=该省落在训练协变量支撑域内的比例。":
        "Rows are model families, columns are scenarios; the colour scale is shared across all maps (log10); transparency encodes the fraction of cells inside the fitted covariate support. ",
    "报告完整度沿用 2024 水平,故预测量为「被记录的新纪录数」。":
        "\nReporting completeness is held at its 2024 level, so the projected quantity is the number of recorded new records.",
    "d  情景响应:只有机制模型随努力情景上升;随机森林持平,XGBoost 反向下滑":
        "d  Scenario response: only the mechanistic model rises; the forest stays flat, XGBoost reverses",
    "三族已在 2024 基期校准到同一量级(22.4 条/年),此后情景斜率是各族自己的。未来的 yr 与 effort_z 越出训练范围后,\\n树集成返回边界叶值:随机森林锁死在基期水平,XGBoost 的边界值甚至给出反向趋势 —— 外推方向不可审查":
        "All three families are calibrated to the same 2024 baseline (22.4 records per year), so each scenario slope is that family's own. Once year and effort leave the training range,\\ntree ensembles return boundary leaf values: the random forest locks at the baseline and XGBoost even reverses — the direction of extrapolation cannot be audited",
    "未来情景下的多尺度预测面:%s · %s · %d 年":
        "Multi-scale prediction surfaces under one future scenario: %s · %s · %d",
    "行=尺度,列=模型族;每列为族内自洽的两段式(该族的省级期望 × 该族的省内分配份额),":
        "Rows are scales, columns are model families; each column is a self-consistent\ntwo-stage pipeline (that family's provincial expectation\n× its own within-province shares), ",
    "市县为份额冻结假设(份额取各族 2024 面)。色标行内共享(log10);透明度=支撑域内比例。":
        "\nwith prefecture and county surfaces holding the 2024 shares fixed. Colour scales are shared within rows (log10); transparency encodes the in-support fraction.",
    "全国预测新纪录数 / 年": "National predicted new records per year",
    "2024 基期 %.1f": "2024 baseline %.1f",
    "2030 年": "2030", "2050 年": "2050",
    "努力停滞": "Effort frozen", "努力延续": "Effort continuing",
    "\\n== 全国预测新纪录数 / 年 ==\\n": "\\n== National predicted new records per year ==\\n",
    "\\n基期 2024 全国合计(三族校准后一致):": "\\nBaseline 2024 national total (identical after calibration): ",
    "三族终拟合完成": "final fits for all three families complete",
    "校准因子 ": "calibration factors: ",
    "数据 ": "data: ", " 行,": " rows, ", " 事件;基期 ": " events; baseline ",
    "预测新纪录数(": "Predicted new records (",
    # ---------------- 共用 ----------------
    "底图:审图号 GS(2019)1822(主图全幅含南海诸岛与九段线)。":
        "Basemap GS(2019)1822; full-extent maps include the South China Sea islands and the nine-dash line.",
    "全国 %.1f 条/年 · 支撑域内 %d%%": "National %.1f per year · %d%% in support",
    "预测新纪录数 / 年": "Predicted new records per year",
    "离散风险模型": "Mechanistic hazard", "随机森林": "Random forest",
    "a  省级 · ": "a  Province · ", "市级": "Prefecture", "县级": "County",
    "完成 / done": "done",
    "a  省级 · ": "a  Province · ", " 省级单元,年份 ": " provincial units, years ",
}

def translate_line(line: str, protect: list[str]) -> str:
    """只在字符串字面量内替换。

    保护采用「整条字面量完全匹配」而非子串匹配:子串保护会把 `同省同年` 之类
    切成占位符,使整句译表键失配,进而让短键(如「省」「条」)去啃碎片并产生
    `b  records件 logistic` 这样的乱码。受保护的都是完整字面量(shapefile 名、
    用于筛选 CSV 的数据值),因此完全匹配是安全且充分的。
    Protect whole literals only — substring protection breaks longer dictionary
    keys and lets short keys corrupt the remaining fragments.
    """
    prot = set(protect)

    def fix(m: re.Match) -> str:
        s = m.group(0)
        if s[1:-1] in prot:
            return s
        for zh in sorted(T, key=len, reverse=True):
            if zh in s:
                s = s.replace(zh, T[zh])
        return s
    return STRLIT.sub(fix, line)

def build(src_name: str, protect: list[str]) -> pathlib.Path:
    src = CODE / src_name
    out_lines, redirected = [], False
    for line in src.read_text(encoding="utf-8").splitlines():
        if line.lstrip().startswith("#"):
            out_lines.append(line); continue
        out_lines.append(translate_line(line, protect))
        if not redirected and re.match(r"^D_FG\s*<-", line):
            out_lines.append('D_FG <- file.path(D_FG, "en")   # 英文版输出目录 / English output dir')
            out_lines.append('dir.create(D_FG, recursive = TRUE, showWarnings = FALSE)')
            redirected = True
    assert redirected, f"{src_name}: 未找到 D_FG 定义"
    txt = "\n".join(out_lines) + "\n"
    # 166:估计量阶梯的 y 轴标签由 CSV 的 model 列派生,同样需重编码。
    txt = txt.replace('lad[, lbl := sub(" \\\\[.*", "", model)]',
                      'lad[, lbl := sub(" \\\\[.*", "", model)]\n' + 'LAD_EN <- c("A0 \\u4ec5\\u66b4\\u9732" = "A0 exposure only", "A1 +\\u9009\\u5740\\u51e0\\u4f55" = "A1 + siting geometry", "L \\u56fd\\u5bb6\\u7ea7" = "L national-level")\nlad[, lbl := fifelse(is.na(LAD_EN[lbl]), lbl, LAD_EN[lbl])]')

    # 166:稳健性面板的情景名同样来自 CSV,需在作图前重编码。
    txt = txt.replace('rob <- fread(file.path(D_TB, "tbl_pa_c1_robustness.csv"))',
                      'rob <- fread(file.path(D_TB, "tbl_pa_c1_robustness.csv"))\nROB_EN <- c("\\u4e3b\\u53e3\\u5f84(\\u52aa\\u529b\\u52a0\\u6743, K=200)" = "Main specification (effort-weighted, K=200)", "\\u5254\\u9664\\u897f\\u85cf" = "Excluding Tibet", "\\u5254\\u9664\\u524d 2 \\u5927\\u5bbf\\u4e3b\\u4fdd\\u62a4\\u533a" = "Excluding the two largest host reserves", "\\u4ec5 2013-2023(\\u4fdd\\u62a4\\u7f51\\u7edc\\u5df2\\u51bb\\u7ed3)" = "2013-2023 only (reserve network frozen)", "\\u4ec5 2002-2012" = "2002-2012 only", "\\u4ec5\\u89c2\\u9e1f\\u5f0f\\u53d1\\u73b0\\u7684\\u4e8b\\u4ef6" = "Birdwatching-type discoveries only", "\\u4ec5\\u4e13\\u4e1a\\u8c03\\u67e5\\u53d1\\u73b0\\u7684\\u4e8b\\u4ef6" = "Professional-survey discoveries only")\nrob[, model := ROB_EN[model]]')

    # 166:priority 是 CSV 里的数据值(中文)。译表已把 levels= 改成英文,
    # 因此必须在读入后立刻把数据本身重编码,否则全部落成 NA。
    # 重编码表的中文键用 \u 转义写出,以免再次被本工具翻译。
    PRI = [("A 嫁接到已建保护区", "A graft onto existing reserves"),
           ("B 保护体系外,需另投调查", "B outside the reserve system"),
           ("C 高暴露但已有观测", "C high exposure, already surveyed"),
           ("D 其他", "D other")]
    esc = lambda z: "".join(c if ord(c) < 128 else f"\\u{ord(c):04x}" for c in z)
    pri_map = ("PRI_EN <- c(" + ", ".join(f'"{esc(z)}" = "{e}"' for z, e in PRI) + ")\n"
               'pri[, priority := PRI_EN[priority]]\n'
               'gp[,  priority := PRI_EN[priority]]')
    txt = txt.replace('gp  <- fread(file.path(D_PA, "c3_grid_panel.csv"))',
                      'gp  <- fread(file.path(D_PA, "c3_grid_panel.csv"))\n' + pri_map)

    # 186 / 187 / 188:中文用作 R 名字(不是字符串字面量),译表触及不到,需直接改名
    for zh, en in (("纬度 = latitude", "Latitude = latitude"),
                   ("经度 = longitude", "Longitude = longitude"),
                   ("`努力停滞` = 0", "`Effort frozen` = 0"),
                   ("`努力延续` = 0.6", "`Effort continuing` = 0.6")):
        txt = txt.replace(zh, en)

    # 188:hzf 的构造串必须与已译的因子水平一致,否则分面全变 NA
    txt = txt.replace('hzf = factor(paste0(horizon, " 年"), levels = c("2030", "2050"))',
                      'hzf = factor(as.character(horizon), levels = c("2030", "2050"))')
    # 185:split 的筛选值必须保持中文(来自 CSV),仅显示标签转英文
    txt = txt.replace(
        'split = factor(split, levels = c("时间前推 2019–2024", "留一省")))]',
        'split = factor(fifelse(split == "时间前推 2019–2024", "Temporal 2019–2024", "Leave-one-province"),\n'
        '                            levels = c("Temporal 2019–2024", "Leave-one-province")))]')
    dst = CODE / src_name.replace(".R", "_en.R")
    dst.write_text(txt, encoding="utf-8")
    return dst

if __name__ == "__main__":
    jobs = [("166_pa_figures.R", []), ("185_multiscale_prediction_maps.R", PROTECT_185),
            ("186_spatiotemporal_pattern.R", []), ("187_future_scenario_maps.R", []),
            ("188_future_multimodel_maps.R", [])]
    for name, extra in jobs:
        d = build(name, GLOBAL_PROTECT + extra)
        left = sum(1 for ln in d.read_text(encoding="utf-8").splitlines()
                   if not ln.lstrip().startswith("#")
                   for s in STRLIT.findall(ln) if CJK.search(s))
        print(f"{d.name}: 生成完成,字符串字面量中残留中文 {left} 处")
