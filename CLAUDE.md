# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **cn-math-taxonomy**: a comprehensive Chinese K-12 knowledge graph and adaptive diagnostic system covering:
- **Mathematics**: Elementary (grades 1-6, 241 topics), Middle School (grades 7-9, 315 topics), High School (143 mandatory + 128 elective topics)
- **English**: Elementary (grades 3-6, 208 topics), Middle School (257 topics), High School (259 topics)
- **Physics**: Middle School (92 topics), High School (177 topics)
- **Chinese Language**: Elementary (grades 1-6, 402 topics)

**Total**: 1,820 knowledge topics, 2,917 prerequisite edges, 7,427 practice questions, 627 curriculum standard mappings.

The system features **adaptive diagnostic assessment**: students answer questions on a target topic; wrong answers trigger prerequisite backtracking through the knowledge graph until root gaps are identified, with a personalized learning path generated from elementary through high school.

**Key Constraint**: This is an AI-generated draft that has NOT been reviewed by teachers. Prerequisite relationships, mastery criteria, and diagnostic questions require expert validation before production use.

## Architecture

### Data Files (JSON, read-only for web app)
- `data/topics.json` — All 1,820 knowledge topics with metadata
- `data/dependencies.json` — 2,917 prerequisite edges (hard/soft strength)
- `data/questions.json` — 7,427 diagnostic questions with auto-verification
- `data/cn-curriculum-standards.json` — 627 curriculum standard mappings
- `data/id-aliases.json` — Legacy ID redirects (cnm_ext_* → cnm_p*)

### Static Web Application (Pure Frontend, No Build Step)
- `index.html` — Home page with subject/grade navigation
- `explore/` — Interactive knowledge graph viewer (Cytoscape.js + dagre)
- `diagnose/` — Adaptive diagnostic engine (pure JavaScript, localStorage persistence)
- `children/` — Student profile management (localStorage only)
- `assets/` — Shared CSS, JavaScript utilities, vendor libraries

### Generation Scripts (Python, standard library only)
- `scripts/validate.py` — **Primary validation**: JSON integrity, graph cycles, field validation
- `scripts/verify_questions.py` — Auto-verify question answers via symbolic math
- `scripts/*_build.py` — Data generation scripts (math, English, physics, Chinese)
- `scripts/second_pass.py` — Independent blind verification of question answers

### Core Diagnostic Engine
- `diagnose/engine.js` — Pure functional diagnostic algorithm (browser + Node.js compatible)
- `tests/test_engine.js` — Engine test suite (no dependencies, runs with Node.js directly)

## Common Development Tasks

### Validation (Run Before Any Commit)
```bash
# Primary validation - checks JSON integrity, graph structure, field validity
python3 scripts/validate.py

# Question answer verification - auto-checks 2823/3355 questions
python3 scripts/verify_questions.py

# Diagnostic engine tests
node tests/test_engine.js
```

**CRITICAL**: `validate.py` MUST pass before any data changes are committed. Exit code 0 = success.

### Local Development Server
```bash
# Python 3 (simplest)
python3 -m http.server 8000

# Then open:
# http://localhost:8000/              (home)
# http://localhost:8000/explore/      (knowledge graph)
# http://localhost:8000/diagnose/     (diagnostic tool)
```

**Browser requirement**: Pages use `fetch()` for JSON loading. The `file://` protocol will not work - a local HTTP server is required.

### Subject-Specific URLs
```bash
# Math (default, no parameter needed)
http://localhost:8000/
http://localhost:8000/explore/
http://localhost:8000/diagnose/?target=cnm_221

# English
http://localhost:8000/?subject=english
http://localhost:8000/explore/?subject=english#cne_j174

# Physics
http://localhost:8000/?subject=physics
http://localhost:8000/diagnose/?subject=physics&grade=八上

# Chinese Language
http://localhost:8000/?subject=chinese
```

### Knowledge Graph Topic ID Patterns
- Math elementary: `cnm_p001` - `cnm_p241` (grades 1-6)
- Math middle school: `cnm_001` - `cnm_315` (grades 7-9)
- Math high school mandatory: `cnm_h001` - `cnm_h143`
- Math high school elective: `cnm_h144` - `cnm_h271`
- English elementary: `cne_p001` - `cne_p208` (grades 3-6)
- English middle school: `cne_j001` - `cne_j257`
- English high school: `cne_h001` - `cne_h259`
- Physics middle school: `cnp_001` - `cnp_092`
- Physics high school: `cnp_h001` - `cnp_h177`
- Chinese elementary: `cnc_p001` - `cnc_p402`

### Data Rebuild (Comprehensive)
```bash
# Math (all levels)
python3 scripts/build_primary.py      # Elementary
python3 scripts/hs_build.py           # High school mandatory
python3 scripts/hs_sel_build.py       # High school elective

# English
python3 scripts/en_build.py           # Elementary
python3 scripts/enj_build.py          # Middle school
python3 scripts/enh_build.py          # High school

# Physics
python3 scripts/phy_build.py          # Middle + High school

# Chinese
python3 scripts/zh_build.py           # Elementary

# Always validate after rebuild
python3 scripts/validate.py
```

## Data Structure Reference

### Topic Schema (topics.json)
```json
{
  "id": "cnm_221",
  "name": "配方法",
  "domain": "数与代数",
  "grade": 9,
  "semester": "上",
  "chapter": "九上 第二十五章 一元二次方程 25.2",
  "type": "procedural",
  "description": "通过配方将一元二次方程化为 (x+p)²=q 的形式...",
  "mastery_criteria": ["...", "..."],
  "diagnostic_question": {"question": "...", "answer": "..."},
  "external": false,
  "standards": [{"id": "cms-2022:4.NA.17", "confidence": "exact"}],
  "root_reason": "..."  // Only for root nodes with no prerequisites
}
```

**Domain values**:
- Math: `数与代数`, `图形与几何`, `统计与概率`, `综合与实践`
- English: `语音`, `词汇`, `语法`, `日常表达`, `读写`
- Physics: `物质`, `运动和相互作用`, `能量`, `跨学科实践`
- Chinese: `拼音`, `识字写字`, `词语`, `句子`, `阅读理解`, `古诗文积累`, `习作基础`

**Type values**: `conceptual`, `procedural`, `reasoning`, `application`, `modeling`

### Dependency Schema (dependencies.json)
```json
{
  "topicId": "cnm_221",
  "prerequisiteId": "cnm_042",
  "strength": "hard",
  "reason": "配方法需要完全平方公式展开和逆用"
}
```

**Strength values**:
- `hard`: Cannot learn A without mastering B (enforced in diagnostic backtracking)
- `soft`: B helps learn A but is not strictly required (considered after hard prerequisites)

**Edge transitivity**: The graph is transitively reduced - only direct prerequisite edges are stored. Indirect paths are computed at runtime.

### Question Schema (questions.json)
```json
{
  "id": "cnm_221_q1",
  "topicId": "cnm_221",
  "type": "numeric",
  "difficulty": "basic",
  "question": "用配方法解方程 x² + 6x - 7 = 0，写出配方后的形式 (x+a)² = b 中 b 的值。",
  "answer": "16",
  "unit": "",
  "explanation": "x² + 6x - 7 = 0 → x² + 6x = 7 → x² + 6x + 9 = 16 → (x+3)² = 16",
  "verify": "((x + 3) ** 2).expand().equals(x**2 + 6*x + 9) and (x**2 + 6*x + 9 - (x**2 + 6*x - 7)).equals(16)",
  "options": null
}
```

**Question types**:
- `numeric`: Numerical answer (integer or decimal)
- `choice`: Multiple choice with `options` array
- `short`: Short text answer (rare, mostly deprecated)

**Difficulty levels**: `basic`, `standard`, `advanced`

**Verification**: The `verify` field contains a Python symbolic expression for auto-checking. Run `verify_questions.py` to validate all questions.

## Diagnostic Algorithm (diagnose/engine.js)

### Core Logic
1. **Target Selection**: User selects a topic or entire chapter/grade
2. **Adaptive Questioning**: 
   - Ask question 1 for target topic
   - **Correct answer**: Topic mastered, skip all prerequisites (ancestors pruned)
   - **Wrong answer**: Ask question 2
     - **Q2 correct**: Mark as "unstable", don't backtrack
     - **Q2 wrong**: Mark as "weak", backtrack to prerequisites
3. **Prerequisite Ordering**: Hard prerequisites explored before soft ones
4. **Root Cause Identification**: Weakest topics with no weaker prerequisites
5. **Learning Path Generation**: Sorted by grade (low to high), then by prerequisite order

### Diagnostic Session State
```javascript
{
  targets: ['cnm_221'],           // Target topic IDs
  answered: {                      // Question response history
    'cnm_221_q1': {qid, answer, correct, ts}
  },
  status: {                        // Topic assessment results
    'cnm_221': 'mastered' | 'unstable' | 'weak' | 'untested'
  }
}
```

### Testing Engine Changes
```bash
node tests/test_engine.js
```

The test suite validates:
- Prerequisite ordering (hard before soft)
- Ancestor pruning on correct answers
- Two-question unstable detection
- Root cause identification
- Cycle-free path generation

## Important Constraints

### Data Integrity Rules (Enforced by validate.py)
1. **No cycles** in the prerequisite graph (DAG property)
2. **Root nodes** must have `root_reason` field if they have no prerequisites
3. **Topic IDs** must be unique across all subjects
4. **Dependency endpoints** must reference existing topic IDs
5. **Curriculum standards** must exist in `cn-curriculum-standards.json`
6. **Cross-subject edges forbidden**: Math/English/Physics/Chinese graphs are independent
7. **Grade ordering**: Prerequisite grade ≤ dependent topic grade

### Grade Numbering Conventions
- Elementary: grades 1-6
- Middle school: grades 7-9
- High school math mandatory: 10 (first book), 11 (second book) - **Not actual grade levels**
- High school math elective: 12-14 (three books) - **Not grades, just book sequence**
- High school English: 10-12 (mandatory), 13-16 (elective) - **Not actual grade levels**
- Physics high school: 10-15 (six books) - **Not actual grade levels**

**UI Convention**: Display as "必修一" (Mandatory 1), "选必二" (Elective 2), not "高一" (Grade 10).

### Curriculum Standard Alignment
- Math elementary/middle: `cms-2022:1.NA.01` through `cms-2022:4.SP.13` (234 items)
- Math high school: `cms-2017:H.FUN.01` through `cms-2017:H.MI.04` (80 items)
- English elementary: `ces-2022:1.VO.01` through `ces-2022:2.RW.08` (35 items)
- English middle: `ces-2022:3.PH.01` through `ces-2022:3.RW.09` (37 items)
- English high school: `ces-2017:H.B.*` and `ces-2017:H.S.*` (44 items)
- Physics middle: `cps-2022:1.1.1` through `cps-2022:5.3.5` (89 items)
- Physics high school: `cps-hs-2017:B1.*` through `cps-hs-2017:S3.*` (108 items)

**Status**: Many standard texts marked `verbatim: false` and `page_or_ref: "待核"` (pending verification) - these are public paraphrases, not official quotations.

## PWA and Deployment

### Progressive Web App (manifest.webmanifest + sw.js)
- Service worker caches all data files and assets for offline use
- Install prompt on mobile: "Add to Home Screen"
- Cache version: Increment `CACHE_VERSION` in `sw.js` after data changes

### Production Deployment (Cloudflare Pages)
```bash
./scripts/deploy-cf.sh
```

Deploys to: https://math.pansgo.com/ (primary) and https://cn-math-taxonomy.pages.dev/ (backup)

**Deployment includes**:
- `index.html`, `manifest.webmanifest`, `sw.js`
- `assets/`, `explore/`, `diagnose/`, `children/`
- `data/topics.json`, `dependencies.json`, `questions.json`, `cn-curriculum-standards.json`

**Excluded from deployment**: Screenshots, `_qbatches/`, `_second_pass/`, docs/, scripts/

## File Organization Principles

### Many Small Files > Few Large Files
- Topic generation: Separate files per grade/subject (e.g., `hs_book1.py`, `en_g3.py`)
- Each subject has dedicated `*_lib.py` with shared utilities
- Build scripts: `*_build.py` orchestrates compilation, never inline generation

### Pure Functions in Diagnostic Engine
- `engine.js`: No side effects, no DOM access, no localStorage
- All state passed explicitly as parameters
- Enables testing in Node.js without browser environment
- `app.js` handles all browser-specific concerns (DOM, storage)

### Standard Library Only for Python Scripts
- No external dependencies (numpy, pandas, etc.)
- Symbolic math verification uses `fractions.Fraction` and string parsing
- Ensures scripts run in any Python 3 environment without pip install

## Known Limitations and TODOs

### Data Quality Issues
1. **No teacher review**: All content (topics, prerequisites, questions) is AI-generated
2. **Prerequisite strength (hard/soft)**: Subjective AI judgment, needs empirical validation
3. **Small question bank**: Only 4 questions per topic (max 2 used in diagnostic)
4. **High school questions lack blind review**: Only auto-verification, no independent solver
5. **Curriculum standard texts**: Many marked "pending verification" - not official quotations

### Textbook Coverage Gaps
1. **Grade 9 math (spring)**: Uses unofficial third-party table of contents
2. **Elementary grades 4-6**: Some volumes still use current edition, not 2024+ revision
3. **High school textbook page numbers**: Missing throughout, marked "pending verification"
4. **Chapter numbering**: Based on third-party sources, not official publisher catalogs

### Technical Debt
1. **No TypeScript**: Pure JavaScript for diagnostic engine (intentional for simplicity)
2. **No build step**: Vendor libraries committed to repo for offline functionality
3. **localStorage only**: No backend, no user accounts, data trapped on device
4. **No analytics**: Stats collection disabled by default (see `assets/stats-config.js`)
5. **Question images**: Only 4 SVG diagrams for 7,427 questions

## Development Workflow for Major Changes

### Adding New Topics
1. Edit or create appropriate `scripts/*_topics.py` file
2. Add prerequisite edges in `scripts/*_edges.py`
3. Generate questions in `scripts/*_g*.py` with diagnostic question, answer, explanation, verify expression
4. Run `python3 scripts/*_build.py` to compile into data files
5. **Always run `python3 scripts/validate.py`** before commit
6. Test in browser: Load target topic in explore/ and diagnose/ pages
7. Check question auto-verification: `python3 scripts/verify_questions.py`

### Modifying Diagnostic Algorithm
1. Edit `diagnose/engine.js` (pure functions only)
2. Add test cases to `tests/test_engine.js`
3. Run `node tests/test_engine.js` - all tests must pass
4. Test in browser with multiple scenarios (correct answers, wrong answers, mixed)
5. Check localStorage persistence: Refresh page, verify session recovery

### Updating Curriculum Standards
1. Edit `data/cn-curriculum-standards.json` directly
2. Update topic `standards` arrays in source scripts
3. Rebuild data files: `python3 scripts/*_build.py`
4. Validate mappings: `python3 scripts/validate.py`
5. Check coverage: Look for "standards为空" warnings in validation output

## License and Commercial Use

**License**: CC BY-NC 4.0 (Creative Commons Attribution-NonCommercial 4.0 International)

**Allowed**:
- Personal learning, teaching, research
- Modification and redistribution with attribution

**Prohibited**:
- Commercial use (paid courses, apps, institutional services, question bank sales)

**Commercial licensing**: Contact author via X [@hassanyehiaa](https://x.com/hassanyehiaa) or GitHub issue.

**Vendor libraries** (`assets/vendor/`): Cytoscape.js, dagre, cytoscape-dagre remain under MIT license.
