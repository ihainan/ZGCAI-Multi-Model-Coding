# Sources for packages.csv (backfill 2026-11-18)

Paths starting with `docs/` are relative to the gateway repository (`ZGCAI-Model-Gateway`, read from the P1.9 worktree). `paradigm.md` is `skills/multi-model-coding/reference/paradigm.md` in this repository. Line numbers are for the files as read on 2026-11-18.

Column definitions used for the backfill:

- `spec_review_p1_total`: P1 findings as reported by each reviewer (both reviewers added together, not deduplicated) over all full rounds plus the targeted recheck. Left empty when any round's per-reviewer count is not stated. Counts of rows the controller ruled P1 are only mentioned in notes.
- `impl_rounds`: the first implementation round plus every numbered rework round.
- `merge_failures_*`: failing tests in the first merge run (implementation first round plus tester delivery), split by the controller's ruling. Later merge failures go in notes.
- `code_review_p1`: P1s that the controller kept after ruling, from the code review itself and not from a fix check.
- `code_review_findings_kept`: code-review findings the controller accepted (fixed, or ruled a spec clarification), not counting merge-test items.
- `fixcheck_new_issues`: new issues raised by GPT fix checks. Left empty when no fix check was run.
- `gate_real_failures`: distinct defects found by the full gate that needed a code, test or spec change.
- `gate_flaky_or_load_failures`: named tests that failed in the gate and were ruled timing, load or environment failures, then passed on rerun.

## P1.6b
P1.6b done: 2026-11-14 — docs/STATUS.md:18 '**完成**（p1.6b-done，2026-11-14）'
P1.6b spec_versions: 5 — docs/specs/interfaces/P1.6b.md:3 '**状态：第 5 版（2026-11-13）'；paradigm.md:309 'versions 2 to 5.2'
P1.6b acceptance_items: 70 — docs/specs/interfaces/P1.6b.md:2374 '70. （包级与二进制级）周期循环'；paradigm.md:309 '70 acceptance items'
P1.6b spec_full_review_rounds: 3 — paradigm.md:309 'three full GPT + Gemini review rounds, one targeted fix check and one quick check'
P1.6b targeted_recheck: yes — paradigm.md:309 'one targeted fix check'；docs/specs/interfaces/P1.6b.md:2673 '### 12.5 第 5 版定向复核'
P1.6b impl_rounds: 3 — paradigm.md:337 'after three implementer rounds (the third an extra, targeted one)'
P1.6b tester_tests: 111 — paradigm.md:312 'First delivery 95 tests; after the rulings, 111 tests'
P1.6b merge_failures_spec: 0 — docs/specs/interfaces/P1.6b.md:2753-2779 '相同的 21 个失败' (rulings list only 「测试的问题」 and 「实现的问题」; no spec problem)
P1.6b code_review_p1: 4 — docs/STATUS.md:18 'P1 4 组：批内调大批量导致作业提前结束…'；paradigm.md:341 '4 groups rated P1'
P1.6b code_review_findings_kept: 35 — docs/STATUS.md:18 '合并为 37 组（成立 31、部分成立 4、不成立 3'
P1.6b gate_real_failures: 2 — docs/STATUS.md:18 '**全量门禁查出一个本包引入的回归**' + 'TestRollup_GenerationBeforeHour_P16b39（测试自身的时序竞争'
P1.6b notes (gate flaky, field left empty) — docs/STATUS.md:18 '门禁（9714d55）…单元阶段有两个计时类失败（见下方偶发）' + after merging main (8f41453) '`TestMode_RecordOnlyNeverQueues_P14a`（偶发，单独连跑 5 次通过）'; the named test may be one of the earlier two, so the distinct count is 2 or 3
P1.6b notes (15+3 questions, 21 merge failures, 12 tester rounds) — docs/specs/interfaces/P1.6b.md:2723 '测试方提出的十五个问题'；:2745 '测试方第二轮的三个问题'；:2753 '相同的 21 个失败'；docs/STATUS.md:18 '测试方共改 12 轮'
P1.6b notes (R1 Gemini P1 ambiguous) — docs/reviews/draft-P1.6b.md:182 '**5 条 P1 问题**' vs :600 '上述 7 条 P1 与 14 条 P2' (two Gemini reports in round 1; the ruling at docs/specs/interfaces/P1.6b.md:2569 says 'Gemini 的 10 条'). Other rounds: GPT R1 5 (draft-P1.6b.md:5-178, five '**P1｜' items), R2 GPT 3 (:607) + Gemini 3 (:1138 'P1-1～P1-3'), R3 GPT 1 (:1161) + Gemini 0 (:1263), targeted 1 (:1412)

## P1.6c
P1.6c done: 2026-11-14 — docs/STATUS.md:19 '**完成**（p1.6c-done，2026-11-14）'
P1.6c spec_versions: 8 — docs/specs/interfaces/P1.6c.md:3 '状态：第 8 版（2026-11-14'
P1.6c acceptance_items: 30 — docs/STATUS.md:19 '（第 8 版，验收 30 条'；docs/specs/interfaces/P1.6c.md:1173 '验收仍为 30 条'
P1.6c spec_full_review_rounds: 4 — docs/STATUS.md:19 '草案经 GPT xhigh 与 Gemini 四轮盲审'
P1.6c spec_review_p1_total: 16 — R1 9: docs/specs/interfaces/P1.6c.md:1109 '（第 1～6 条为 P1' + docs/reviews/draft-P1.6c.md:246 '先修订 3 个 P1 问题'；R2 4: draft-P1.6c.md:494 '仍有 **3 条 P1 事件序列**' + :698 '仍存在 1 个 P1 问题'；R3 3: draft-P1.6c.md:905 and :915 (two '**P1：' items) + :998 '引入了 1 个新的 P1 问题'；R4 0: draft-P1.6c.md:1151 '未发现新增 P1' + :1186 '仅剩 1 个会导致编译失败的 P2'
P1.6c targeted_recheck: no — docs/specs/interfaces/P1.6c.md:1204 '不再进行第五轮审查' (no targeted-recheck section in 12.x)
P1.6c preread_questions: 21 — docs/specs/interfaces/P1.6c.md:1208 '列出 21 处无法写成确定性断言的地方'
P1.6c impl_rounds: 3 — docs/STATUS.md:19 '第 2 轮返工（471f0bf）' + '第 3 轮返工只改该自测（788b5cf'
P1.6c tester_tests: 77 — docs/STATUS.md:19 '测试方 77 个测试函数覆盖全部 30 条'
P1.6c merge_failures_spec: 0 — docs/STATUS.md:19 '合并测试的 5 个二进制级失败都是测试的问题'
P1.6c merge_failures_impl: 0 — docs/STATUS.md:19 (same quote)
P1.6c merge_failures_test: 5 — docs/STATUS.md:19 '5 个二进制级失败都是测试的问题'
P1.6c code_review_p1: 0 — docs/reviews/code-P1.6c.md:8 '成立 7 条（1 条判为规格澄清，6 条实现问题），无 P1'
P1.6c code_review_findings_kept: 7 — docs/reviews/code-P1.6c.md:8 '成立 7 条'
P1.6c gate_real_failures: 1 — docs/STATUS.md:19 '`TestMigrationAndSchemaUpgrade_P16c` 偶发失败…第 3 轮返工只改该自测'
P1.6c gate_flaky_or_load_failures: 2 — docs/STATUS.md:19 '`TestRedisTimeout_OperationBudget_P14a`（两次…）与 `internal/core/app` 的 `TestImplMigrationNotCutByBudget`（一次'
P1.6c notes (T21-T24) — docs/STATUS.md:19 '据此补规格 T21～T24（第 7 版）'

## P1.7a
P1.7a done: 2026-11-14 — docs/STATUS.md:20 '**完成**（p1.7a-done，2026-11-14）'
P1.7a spec_versions: 6 — docs/specs/interfaces/P1.7a.md:3 '状态：第 6 版（2026-11-14'
P1.7a acceptance_items: 29 — docs/specs/interfaces/P1.7a.md:948 '29. **配置升版**'；docs/STATUS.md:20 '覆盖 29 条验收'
P1.7a spec_full_review_rounds: 4 — docs/STATUS.md:20 '草案四轮 GPT xhigh 与 Gemini 双盲审（R1～R31、S1～S24、T1～T12、U1～U5）'
P1.7a targeted_recheck: no — docs/specs/interfaces/P1.7a.md:1012-1104 (rulings 12.4-12.7 are four full rounds; no targeted-recheck section)
P1.7a preread_questions: 22 — docs/specs/interfaces/P1.7a.md:1131 '测试方读第 4 版后列出 22 条（`Q1`～`Q22`）'；docs/STATUS.md:20 '测试方预读（22 条）'
P1.7a impl_rounds: 4 — docs/reviews/code-P1.7a.md:5 '首轮交付（776df2f）及其后三轮返工'
P1.7a tester_tests: 69 — docs/STATUS.md:20 '测试方 69 个测试函数覆盖 29 条验收'
P1.7a merge_failures_spec: 0 — docs/STATUS.md:20 '合并测试 7 个失败（实现 4、测试 3）'
P1.7a merge_failures_impl: 4 — docs/STATUS.md:20 '合并测试 7 个失败（实现 4、测试 3）'
P1.7a merge_failures_test: 3 — docs/STATUS.md:20 (same quote)
P1.7a code_review_p1: 7 — docs/reviews/code-P1.7a.md:14-17 (V1-V4 'P1') and :24-26 (V11-V13 'P1', source 'GPT B')
P1.7a code_review_findings_kept: 12 — docs/reviews/code-P1.7a.md:14-19 and :24-29 (V1-V6 and V11-V16 from the review; V7-V10 are from the merge test and tester delivery)
P1.7a fixcheck_new_issues: 7 — docs/reviews/code-P1.7a.md:33 '第 1 次修复核对（第 2 轮返工之后）另有 6 项' + :40 '第 4 次核对 | 依赖检查只读显式构建标签' (1)
P1.7a gate_real_failures: 0 — docs/STATUS.md:20 '门禁（99b1552，新建库）…通过；`make test-testobs` 单元阶段 2 个计时类失败'
P1.7a gate_flaky_or_load_failures: 2 — docs/STATUS.md:20 '`TestPoolQueue_CrashedHolderStopsBlocking_P14a` 已在偶发清单；`TestImplVocabularyRealPaths` 新登记'
P1.7a notes (19 rows ruled P1) — docs/specs/interfaces/P1.7a.md:1018-1027 (R1-R10 '成立（P1）'), :1054-1057 (S1-S4), :1083-1085 (T1-T3), :1100-1101 (U1-U2)
P1.7a notes (V17) — docs/STATUS.md:20 'V17 是两轮核对后仍有 P1 而停下来判定的规格问题'

## P1.7b
P1.7b done: 2026-11-15 — docs/STATUS.md:21 '**完成**（p1.7b-done，2026-11-15）'
P1.7b spec_versions: 8 — docs/specs/interfaces/P1.7b.md:3 '状态：第 8 版，定稿'；paradigm.md:364 'Eight versions'
P1.7b acceptance_items: 29 — docs/specs/interfaces/P1.7b.md:455 '29. （测试接口与循环）'；paradigm.md:364 '29 acceptance items'
P1.7b spec_full_review_rounds: 4 — paradigm.md:364 'Four full GPT xhigh + Gemini rounds: P1 findings 13, 5, 1, 1'
P1.7b spec_review_p1_total: 22 — docs/specs/interfaces/P1.7b.md:501 'GPT（xhigh）报 8 项 P1…Gemini 报 5 项 P1'；:535 '4 项 P1…Gemini 报 1 项 P1'；:565 'GPT（xhigh）报 1 项 P1'；:586 'GPT（xhigh）报 1 项 P1'；:605 '报 2 项 P1'
P1.7b targeted_recheck: yes — docs/specs/interfaces/P1.7b.md:603 '### 12.5 第五轮定向复核的裁决'；paradigm.md:365
P1.7b preread_questions: 20 — docs/specs/interfaces/P1.7b.md:631 '提出 20 条问题（Q1～Q20）'；paradigm.md:366
P1.7b impl_rounds: 2 — docs/reviews/code-P1.7b.md:5 '首轮交付（36d9da9）及第 2 轮返工（f7dc27c）'
P1.7b tester_tests: 54 — docs/STATUS.md:21 '测试方 54 个测试函数覆盖 29 条验收'；paradigm.md:367
P1.7b merge_failures_spec: 0 — docs/specs/interfaces/P1.7b.md:615 'test/p17b 两个失败' (M1 and M2 both test problems; M3 at :621 is not a test failure, see docs/STATUS.md:21 '主控核对交付说明时发现')
P1.7b merge_failures_impl: 0 — docs/STATUS.md:21 '合并测试 2 个失败（均为测试）'
P1.7b merge_failures_test: 2 — docs/STATUS.md:21 '合并测试 2 个失败（均为测试）'；paradigm.md:368 '2 failures, both test mistakes'
P1.7b code_review_p1: 0 — docs/specs/interfaces/P1.7b.md:615 '均未发现 P1'
P1.7b code_review_findings_kept: 4 — docs/reviews/code-P1.7b.md:17-20 (N1, N2, N4, N5 from the two reviews; N3 not adopted at :27; N6 at :21 came from '实现方交付说明', not a reviewer)
P1.7b gate_real_failures: 0 — docs/STATUS.md:21 '`make test-testobs`（这次没有偶发失败）'；paradigm.md:370 'Passed on the first run'
P1.7b gate_flaky_or_load_failures: 0 — docs/STATUS.md:21 '（这次没有偶发失败）'
P1.7b notes (6 rework items) — docs/STATUS.md:21 '一轮返工 6 项 P2'；paradigm.md:369 'one rework round fixed 6 small issues'

## P1.7c
P1.7c done: 2026-11-15 — docs/STATUS.md:22 '**完成**（p1.7c-done，2026-11-15）'
P1.7c spec_versions: 5 — docs/specs/interfaces/P1.7c.md:3 '状态：第 5 版，定稿'
P1.7c acceptance_items: 27 — docs/specs/interfaces/P1.7c.md:316 '27. （循环）'；docs/STATUS.md:22 '覆盖 27 条验收'
P1.7c spec_full_review_rounds: 2 — docs/STATUS.md:22 '草案两轮 GPT xhigh 与 Gemini 双盲审'
P1.7c spec_review_p1_total: 3 — docs/specs/interfaces/P1.7c.md:357 'GPT（xhigh）报 2 项 P1…Gemini…认为没有 P1'；:387 '没有新的 P1'；:405 '报 1 项 P1，记作 F1'
P1.7c targeted_recheck: yes — docs/specs/interfaces/P1.7c.md:403 '### 12.3 第三轮定向复核的裁决'
P1.7c preread_questions: 16 — docs/specs/interfaces/P1.7c.md:430 '提出 16 条问题（Q1～Q16）'
P1.7c impl_rounds: 3 — docs/STATUS.md:22 '全量门禁（af08f17 加第 3 轮返工）'
P1.7c impl_first_round_min: 44 — docs/STATUS.md:22 'Codex 首轮实现 44 分钟'
P1.7c tester_tests: 37 — docs/STATUS.md:22 '测试方 37 个测试函数覆盖 27 条验收'
P1.7c merge_failures_spec: 0 — docs/specs/interfaces/P1.7c.md:413 '第一次运行全部通过，没有需要裁决的失败'
P1.7c merge_failures_impl: 0 — docs/specs/interfaces/P1.7c.md:413 (same quote)
P1.7c merge_failures_test: 0 — docs/specs/interfaces/P1.7c.md:413 (same quote)
P1.7c code_review_p1: 0 — docs/specs/interfaces/P1.7c.md:413 '均未发现 P1'
P1.7c code_review_findings_kept: 5 — docs/STATUS.md:22 '一轮返工 3 项 P2、2 项 P3'；docs/reviews/code-P1.7c.md:15-19 (N1-N4, N7)
P1.7c gate_real_failures: 1 — docs/specs/interfaces/P1.7c.md:424 'N8 | （全量门禁）…依赖 ripgrep…实现问题（P2）'
P1.7c gate_flaky_or_load_failures: 1 — docs/specs/interfaces/P1.7c.md:426 'N10 | （全量门禁）`test/p14c` 的 EXF-050 偶发失败'

## P1.8a
P1.8a done: 2026-11-15 — docs/STATUS.md:24 '**完成**（p1.8a-done，2026-11-15）'
P1.8a spec_versions: 5 — docs/specs/interfaces/P1.8a.md:3 '状态：第 5 版，定稿'
P1.8a acceptance_items: 30 — docs/specs/interfaces/P1.8a.md:443 '30. 测试接口'；docs/STATUS.md:24 '覆盖 30 条验收'
P1.8a spec_full_review_rounds: 2 — docs/STATUS.md:24 '草案两轮 GPT xhigh 与 Gemini 双盲审'
P1.8a spec_review_p1_total: 13 — docs/STATUS.md:24 '第一轮双方共 10 项 P1，第二轮 GPT 2 项 P1' + docs/specs/interfaces/P1.8a.md:511 'Gemini 认为可以进入实现，提出 3 项 P2、2 项 P3' + :533 '1 项 P1、3 项 P2'
P1.8a targeted_recheck: yes — docs/specs/interfaces/P1.8a.md:531 '### 12.3 第 3 版定向复核的裁决'
P1.8a preread_questions: 18 — docs/specs/interfaces/P1.8a.md:576 '提出 18 条问题'
P1.8a impl_rounds: 4 — docs/specs/interfaces/P1.8a.md:572 '第 4 轮返工'；docs/reviews/code-P1.8a.md:21
P1.8a impl_first_round_min: 58 — docs/STATUS.md:24 'Codex 首轮实现 58 分钟'
P1.8a tester_tests: 51 — docs/STATUS.md:24 '测试方 51 个测试函数覆盖 30 条验收'
P1.8a merge_failures_spec: 0 — docs/specs/interfaces/P1.8a.md:544 '共 3 个测试，裁决均为测试问题'
P1.8a merge_failures_impl: 0 — docs/specs/interfaces/P1.8a.md:544 (same quote)
P1.8a merge_failures_test: 3 — docs/specs/interfaces/P1.8a.md:544 '共 3 个测试，裁决均为测试问题'
P1.8a code_review_p1: 2 — docs/reviews/code-P1.8a.md:18 'A 段 GPT 2 项 P1'；docs/specs/interfaces/P1.8a.md:556-557 (N1, N2 '实现问题（P1）')
P1.8a code_review_findings_kept: 7 — docs/reviews/code-P1.8a.md:18 '处理 N1～N5、N7、N8；N6…不改实现'
P1.8a fixcheck_new_issues: 1 — docs/reviews/code-P1.8a.md:19 'URI 修复新引入 1 项 P1（…N9）'
P1.8a gate_real_failures: 2 — docs/specs/interfaces/P1.8a.md:570 'G1 … 规格问题：本包新增标准模式必需变量时漏改共享用例' + :572 'G3 … 第 4 轮返工：实现方测试改为每回合轮换顺序'
P1.8a notes (gate load) — docs/specs/interfaces/P1.8a.md:571 'G2 … 多个未改动的包里出现数据库连接超时…负载 50～77'

## P1.8b
P1.8b done: 2026-11-15 — docs/STATUS.md:25 '**完成**（p1.8b-done，2026-11-15）'
P1.8b spec_versions: 6 — docs/specs/interfaces/P1.8b.md:3 '状态：第 6 版，完成'
P1.8b acceptance_items: 21 — docs/specs/interfaces/P1.8b.md:330 '21. 性能'
P1.8b spec_full_review_rounds: 2 — docs/STATUS.md:25 '草案两轮双盲审加一轮 GPT 定向复核后定稿'
P1.8b targeted_recheck: yes — docs/specs/interfaces/P1.8b.md:397 '### 10.3 第 3 版定向复核的裁决'
P1.8b preread_questions: 18 — docs/specs/interfaces/P1.8b.md:458 '提出 18 条问题'
P1.8b impl_rounds: 2 — docs/specs/interfaces/P1.8b.md:446 '第 2 轮返工（d15933c）处理 N1～N9'
P1.8b merge_failures_spec: 2 — docs/specs/interfaces/P1.8b.md:430 'M2 | `TestRootIDLatency_P18b21` 与实现方 `TestRootIDPerformance_P18b`…规格问题'
P1.8b merge_failures_impl: 0 — docs/specs/interfaces/P1.8b.md:425 '`test/p18b` 两个失败、`test/p18bimpl` 一个失败' (rulings M1 test, M2 spec)
P1.8b merge_failures_test: 1 — docs/specs/interfaces/P1.8b.md:429 'M1 | `TestStreamingAttribution_P18b11`…测试问题'
P1.8b code_review_p1: 0 — docs/specs/interfaces/P1.8b.md:432 '各由 GPT（xhigh）与 Gemini 盲审，均无 P1'
P1.8b code_review_findings_kept: 9 — docs/specs/interfaces/P1.8b.md:446 '第 2 轮返工（d15933c）处理 N1～N9'；docs/STATUS.md:25 '9 项 P2/P3 第 2 轮返工处理'
P1.8b gate_real_failures: 0 — docs/specs/interfaces/P1.8b.md:452-454 (G1 provenance only, G2 environment, G3 existing race '与本包无关')
P1.8b gate_flaky_or_load_failures: 3 — docs/specs/interfaces/P1.8b.md:453 '`TestRedisTimeout_OperationBudget_P14a` 实测 204.6 ms…`TestStore_SecondTierRegexWarning`' + :454 '`test/p16aimpl` 的 `a06-…`'
P1.8b notes (6 rows ruled P1 in R1) — docs/specs/interfaces/P1.8b.md:358-362 and :364 ('采纳（P1）'); R2 per reviewer at :378 'GPT 3 项 P1…Gemini 1 项 P1'; recheck at :399 '2 项 P1'

## P1.8c
P1.8c done: 2026-11-16 — docs/STATUS.md:26 '**完成**（p1.8c-done，2026-11-16）'
P1.8c spec_versions: 5 — docs/specs/interfaces/P1.8c.md:3 '状态：第 5 版，完成'
P1.8c acceptance_items: 16 — docs/specs/interfaces/P1.8c.md:295 '16. 并发与性能'
P1.8c spec_full_review_rounds: 2 — docs/STATUS.md:26 '草案两轮双盲审加一轮 GPT 定向复核与测试方预读后定稿'
P1.8c targeted_recheck: yes — docs/STATUS.md:26 (same quote)
P1.8c preread_questions: 19 — docs/specs/interfaces/P1.8c.md:410 '测试方按第 3 版预读，提出 19 条问题'
P1.8c impl_rounds: 3 — docs/specs/interfaces/P1.8c.md:432 '第 3 轮返工（25574f5）之后合并测试全部通过'
P1.8c tester_tests: 22 — docs/STATUS.md:26 '测试方 22 个二进制级测试（238856a）'；docs/specs/interfaces/P1.8c.md:381 '`test/p18c`（22 个测试'
P1.8c merge_failures_spec: 0 — docs/specs/interfaces/P1.8c.md:381 '第一次运行全部通过'
P1.8c merge_failures_impl: 0 — docs/specs/interfaces/P1.8c.md:381 (same quote)
P1.8c merge_failures_test: 0 — docs/specs/interfaces/P1.8c.md:381 (same quote)
P1.8c code_review_p1: 0 — docs/STATUS.md:26 '代码审查两段双审无 P1（Gemini 标的 1 项 P1 路径变体定为 P2）'
P1.8c code_review_findings_kept: 10 — docs/reviews/code-P1.8c.md:19 '第 2 轮返工（ac32356）处理 N1～N9、N11；N10…不改'
P1.8c fixcheck_new_issues: 3 — docs/specs/interfaces/P1.8c.md:399 '另提出 3 项'；docs/reviews/code-P1.8c.md:20 '另有 3 项'
P1.8c gate_real_failures: 0 — docs/specs/interfaces/P1.8c.md:436-438 (G1 pass, G2 provenance, G3 '环境问题')
P1.8c gate_flaky_or_load_failures: 2 — docs/specs/interfaces/P1.8c.md:438 '`ledger/rollup` 一个测试连接数据库超时（负载 11）、`protocol/encode` 进程被系统终止'
P1.8c notes (later merge M1) — docs/specs/interfaces/P1.8c.md:406 'M1 | 合并测试 `TestProxyStatus_P18c11`…规格问题（主控第 2 轮任务说明与 4.1 第 3 条冲突）'

## P1.8d
P1.8d done: 2026-11-16 — docs/STATUS.md:28 '**完成**（p1.8d-done，2026-11-16）'
P1.8d spec_versions: 6 — docs/specs/interfaces/P1.8d.md:3 '状态：第 6 版，完成'
P1.8d acceptance_items: 18 — docs/specs/interfaces/P1.8d.md:200 '18. 解码开销'
P1.8d spec_full_review_rounds: 2 — docs/STATUS.md:28 '草案两轮双盲审加一轮 GPT 定向复核与测试方预读后定稿'
P1.8d spec_review_p1_total: 20 — docs/specs/interfaces/P1.8d.md:224 'GPT 10 项 P1、7 项 P2；Gemini 6 项 P1'；:249 'GPT（xhigh）2 项 P1…Gemini 2 项 P1'；:268 'GPT（xhigh）4 项 P2'
P1.8d targeted_recheck: yes — docs/specs/interfaces/P1.8d.md:266 '### 10.3 第 3 版定向复核的裁决'
P1.8d preread_questions: 18 — docs/specs/interfaces/P1.8d.md:328 '测试方按第 4 版预读，提出 18 条问题'
P1.8d impl_rounds: 3 — docs/specs/interfaces/P1.8d.md:318 '第 3 轮返工（`3e04a4f`）只改这 4 个测试包'
P1.8d tester_tests: 37 — docs/specs/interfaces/P1.8d.md:272 '37 个测试函数：包级 17、二进制级 20'
P1.8d merge_failures_spec: 0 — docs/specs/interfaces/P1.8d.md:284 '包级测试两种构建只有 1 个失败' (M1 at :288 is '实现问题')
P1.8d merge_failures_impl: 1 — docs/specs/interfaces/P1.8d.md:288 'M1 | `TestInbound_Speed_Messages_P18d10`…实现问题'
P1.8d merge_failures_test: 0 — docs/specs/interfaces/P1.8d.md:284 (same quote)
P1.8d code_review_findings_kept: 6 — docs/reviews/code-P1.8d.md:20 'N1～N3、N5～N7 第 2 轮返工；N4…不改'
P1.8d fixcheck_new_issues: 1 — docs/specs/interfaces/P1.8d.md:302 '另提 1 项'
P1.8d gate_real_failures: 1 — docs/specs/interfaces/P1.8d.md:322 'G1 … 测试问题，第 2.6 节漏列' (5 tests in 4 packages, one cause)
P1.8d gate_flaky_or_load_failures: 2 — docs/specs/interfaces/P1.8d.md:324 '`TestIngressPerformance_P18a`…与 `TestRootIDPerformance_P18b` 在负载 7～10 时超出门槛…判定为负载造成的测量波动'
P1.8d notes (code review P1 left empty) — docs/reviews/code-P1.8d.md:20 'GPT 1 项 P1（工具名集合无界，定为 P2）…Gemini 1 项 P1（`speed: null`，同 M1）' (the ruling for N5 at P1.8d.md:298 gives no severity)

## P1.9a (recorded at close-out, 2026-11-18, by the controller)
P1.9a: all numbers from docs/specs/interfaces/P1.9a.md section 11 (11.1-11.9), docs/reviews/code-P1.9a.md and the controller's session. spec_review_p1_total = round 1 GPT 6 (Gemini did not run: provider outage) + round 2 GPT 5 + Gemini 3 + targeted recheck 1. merge_failures_* count the first stage-A merge run M1-M8 (M2 split spec/self-test counted as spec; M8 ended as a self-test change, counted under test is not applied: left out). code_review_p1 = N1, N2, BN1 kept as P1. fixcheck_new_issues = F1-F4, BC1-BC3. gate_flaky_or_load_failures = MB3, MB4 (known p18b excluded).
