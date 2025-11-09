# Math Agent Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     OPENEVOLVE CONTROLLER                       │
│                   (Main Orchestration Loop)                     │
└────────────┬────────────────────────────────────┬───────────────┘
             │                                    │
             ▼                                    ▼
    ┌────────────────┐                  ┌─────────────────┐
    │   Config.yaml  │                  │  Initial Program│
    │                │                  │  (Generation 0) │
    │ • LLM settings │                  │                 │
    │ • Islands: 5   │                  │ Baseline: 40%   │
    │ • Population   │                  │ Score: 0.239    │
    └────────────────┘                  └─────────────────┘
             │                                    │
             └────────────────┬───────────────────┘
                              ▼
             ┌─────────────────────────────────────┐
             │      MAP-ELITES DATABASE             │
             │   (Feature Grid + Islands)           │
             ├──────────────────────────────────────┤
             │                                      │
             │  Island 1    Island 2    Island 3   │
             │  ┌──────┐    ┌──────┐    ┌──────┐   │
             │  │ Grid │    │ Grid │    │ Grid │   │
             │  │ [A,C]│    │ [A,C]│    │ [A,C]│   │
             │  └──────┘    └──────┘    └──────┘   │
             │                                      │
             │  Island 4    Island 5               │
             │  ┌──────┐    ┌──────┐               │
             │  │ Grid │    │ Grid │               │
             │  │ [A,C]│    │ [A,C]│               │
             │  └──────┘    └──────┘               │
             │                                      │
             │  A = Accuracy (0.0-1.0)             │
             │  C = Complexity (lines of code)      │
             └──────────────┬───────────────────────┘
                            │
                            ▼
             ┌──────────────────────────────────────┐
             │     ITERATION LOOP (1 to N)          │
             │                                      │
             │  ┌────────────────────────────────┐  │
             │  │ 1. SELECT programs from DB     │  │
             │  │    - Top performers (5)        │  │
             │  │    - Diverse programs (3)      │  │
             │  └───────────┬────────────────────┘  │
             │              ▼                       │
             │  ┌────────────────────────────────┐  │
             │  │ 2. BUILD PROMPT                │  │
             │  │    - System message            │  │
             │  │    - Selected programs         │  │
             │  │    - Performance breakdown     │  │
             │  │    - Error analysis            │  │
             │  └───────────┬────────────────────┘  │
             │              ▼                       │
             │  ┌────────────────────────────────┐  │
             │  │ 3. LLM MUTATION                │  │
             │  │    ┌──────────────────────┐    │  │
             │  │    │ GPT-4o (70% weight)  │    │  │
             │  │    │ GPT-4o-mini (30%)    │    │  │
             │  │    └──────────────────────┘    │  │
             │  │    → Returns evolved code      │  │
             │  └───────────┬────────────────────┘  │
             │              ▼                       │
             │  ┌────────────────────────────────┐  │
             │  │ 4. EVALUATION                  │  │
             │  │    ┌─────────────────────┐     │  │
             │  │    │  evaluator.py       │     │  │
             │  │    │  Tests 20 problems  │     │  │
             │  │    │  Returns metrics    │     │  │
             │  │    └─────────────────────┘     │  │
             │  └───────────┬────────────────────┘  │
             │              ▼                       │
             │  ┌────────────────────────────────┐  │
             │  │ 5. DATABASE UPDATE             │  │
             │  │    - Calculate features        │  │
             │  │    - Find grid cell [A, C]     │  │
             │  │    - Compare with existing     │  │
             │  │    - Keep better program       │  │
             │  │    - Update absolute best      │  │
             │  └────────────────────────────────┘  │
             └──────────────────────────────────────┘
                            │
                            ▼
             ┌──────────────────────────────────────┐
             │      CHECKPOINT SYSTEM               │
             │   (Every 25 iterations)              │
             ├──────────────────────────────────────┤
             │  checkpoints/checkpoint_N/           │
             │  ├── best_program.py                 │
             │  ├── database.pkl                    │
             │  ├── metadata.json                   │
             │  └── islands/                        │
             │      ├── island_0.json               │
             │      ├── island_1.json               │
             │      └── ...                         │
             └──────────────────────────────────────┘
```

## Component Details

### 1. Controller (`openevolve/controller.py`)

**Role**: Main orchestration
- Manages iteration loop
- Coordinates all components
- Handles checkpointing
- Parallel evaluation scheduling

### 2. Database (`openevolve/database.py`)

**Role**: Population management using MAP-Elites
- Maintains 5 independent islands
- Each island has a 2D feature grid:
  - **Accuracy dimension**: 0.0 to 1.0 (10 bins)
  - **Complexity dimension**: lines of code (10 bins)
- Stores best program per grid cell
- Tracks absolute best across all islands

**Why Islands?**
- Prevents premature convergence
- Maintains diversity
- Allows parallel exploration of solution space
- Islands migrate programs every 50 iterations

### 3. Evaluator (`examples/math_agent/evaluator.py`)

**Role**: Program testing and scoring
- Loads evolved program
- Tests against 20 problems
- Returns metrics:
  - `accuracy`: % correct
  - `combined_score`: Weighted by difficulty
  - `category_accuracies`: Per-category breakdown
  - `complexity`: Code size
  - `errors`: Failed problem details

### 4. LLM Integration (`openevolve/llm/`)

**Role**: Code mutation via language models
- Ensemble approach:
  - Primary model (GPT-4o): 70% weight
  - Fast model (GPT-4o-mini): 30% weight
- Async generation with retry logic
- Timeout protection (180s)
- Token limit: 8000

### 5. Prompt Builder (`openevolve/prompt.py`)

**Role**: Construct evolution prompts
- System message (from config)
- Selected programs with code
- Performance breakdown
- Error analysis
- Specific improvement suggestions

## Data Flow Example

### Iteration 10 Walkthrough

```
1. SELECT
   └─> Query database for best programs
       • Island 2, Cell [6,3]: Program #45 (Score: 0.678)
       • Island 1, Cell [5,4]: Program #32 (Score: 0.545)
       • Island 3, Cell [7,2]: Program #51 (Score: 0.712)
       • ... (total 8 programs selected)

2. PROMPT
   └─> Build LLM prompt:
       ├─ System: "You are an expert mathematician..."
       ├─ Programs: Shows code from #45, #51, #32
       ├─ Performance: "Algebra: 100%, Calculus: 50%, ..."
       └─ Errors: "Problem #6 fails because..."

3. MUTATE
   └─> Send to LLM (GPT-4o)
       ├─ Request: [System + Prompt]
       ├─ Temperature: 0.8
       ├─ Max tokens: 8000
       └─ Response: [Evolved code]

4. EVALUATE
   └─> Run evaluator.py
       ├─ Save evolved code to temp file
       ├─ Import and test against 20 problems
       ├─ Problem 1: ✓ Correct (expected: 4.0, got: 4.0)
       ├─ Problem 2: ✓ Correct (expected: 2.0, got: 2.0)
       ├─ ...
       └─ Results: {accuracy: 0.80, combined_score: 0.745, ...}

5. UPDATE
   └─> Update database
       ├─ Features: accuracy=0.80, complexity=165
       ├─ Cell: [8, 3] on Island 2
       ├─ Current occupant: Program #67 (score: 0.689)
       ├─ New score 0.745 > 0.689 → REPLACE ✓
       └─ New absolute best: 0.745 > 0.712 → UPDATE ✓

6. LOG
   └─> "[Iteration 10] NEW BEST! 0.712 → 0.745 (+5%)"

7. CHECKPOINT (if iter % 25 == 0)
   └─> Save state to disk
```

## Feature Space Visualization

```
Complexity →

 200┤
    │                  [●]  ← Program with high accuracy
 180┤              [●]      but also complex
    │
 160┤      [●]  [●]  [●]    ← Sweet spot: good accuracy,
    │      [●]  [●]  [●]       moderate complexity
 140┤  [●]  [●]  [●]
    │  [●]  [●]
 120┤  [●]  [●]            ← Simple but lower accuracy
    │
 100┤  [●]
    │
  80┤  [●]                 ← Initial program
    └────┴────┴────┴────┴──
    0.2  0.4  0.6  0.8  1.0
                          ← Accuracy

Each [●] represents a grid cell containing the best program
for that (accuracy, complexity) combination.
```

## Migration Pattern

```
Every 50 iterations:

Island 1 → Island 2 → Island 3 → Island 4 → Island 5 → Island 1
   ↓          ↓          ↓          ↓          ↓          ↓
 Copy       Copy       Copy       Copy       Copy       Copy
 best       best       best       best       best       best
programs   programs   programs   programs   programs   programs

Result: Cross-pollination of successful strategies
```

## Performance Optimization

### Parallel Evaluation
```
┌─────────────┐
│ Controller  │
└──────┬──────┘
       │
       ├─────────────┬─────────────┬─────────────┐
       ▼             ▼             ▼             ▼
  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
  │Worker 1 │  │Worker 2 │  │Worker 3 │  │Worker 4 │
  │Iter 1   │  │Iter 2   │  │Iter 3   │  │Iter 4   │
  └─────────┘  └─────────┘  └─────────┘  └─────────┘
       │             │             │             │
       └─────────────┴─────────────┴─────────────┘
                     │
                     ▼
              Results merged
              back to database
```

**Config setting**: `parallel_evaluations: 4`

## Key Algorithms

### MAP-Elites Selection
```python
def update_database(program, features, score):
    # Calculate grid cell
    accuracy_cell = int(features['accuracy'] * 10)
    complexity_cell = int(features['complexity'] / 50)

    # Get current cell occupant
    current = grid[accuracy_cell][complexity_cell]

    # Keep better program
    if current is None or score > current.score:
        grid[accuracy_cell][complexity_cell] = program
        return True
    return False
```

### Double Selection
```python
def select_programs_for_mutation():
    # Select programs to inspire mutation
    inspiration = select_top_k(database, k=5)

    # Select different programs to show in prompt
    # (ensures diversity in what LLM sees)
    shown_programs = select_diverse(database, k=3, exclude=inspiration)

    return inspiration, shown_programs
```

## File Structure

```
examples/math_agent/
├── initial_program.py       # Starting template (Gen 0)
├── evaluator.py             # Fitness function
├── config.yaml              # Evolution parameters
├── problems.json            # Test dataset
├── run.sh                   # Quick start script
├── demo_evolution.sh        # Demo with explanations
├── README.md                # User guide
├── ARCHITECTURE.md          # This file
├── EXAMPLE_PROMPT.md        # LLM prompt example
├── MONITORING_GUIDE.md      # Progress tracking
└── openevolve_output/       # Created during evolution
    ├── checkpoints/
    │   ├── checkpoint_25/
    │   ├── checkpoint_50/
    │   └── ...
    ├── evolution.log
    └── errors/
```

## Extending the Architecture

### Add New Problem Category

1. Add problems to `problems.json`:
   ```json
   {"id": 21, "category": "complex_analysis", ...}
   ```

2. Update `initial_program.py`:
   ```python
   def solve_complex_analysis(self, problem: str) -> float:
       # Implementation
       pass
   ```

3. Update `evaluator.py` if needed (usually automatic)

4. Update `config.yaml` system message to mention new category

### Add New Feature Dimension

Currently: `[accuracy, complexity]`

To add `execution_time`:

1. Update `config.yaml`:
   ```yaml
   feature_dimensions:
     - "accuracy"
     - "complexity"
     - "speed"  # New!
   ```

2. Update `evaluator.py` to return time metric

3. Database automatically creates 3D grid: `[accuracy, complexity, speed]`

### Use Different LLM

Update `config.yaml`:
```yaml
llm:
  api_base: "https://api.anthropic.com/v1"
  models:
    - name: "claude-3-5-sonnet-20241022"
      weight: 1.0
```

## AlphaEvolve Alignment

This architecture mirrors AlphaEvolve's approach:

| AlphaEvolve Feature | OpenEvolve Implementation |
|---------------------|---------------------------|
| LLM-driven mutation | ✓ GPT-4o ensemble |
| Island evolution | ✓ 5 islands with migration |
| MAP-Elites diversity | ✓ 2D feature grid |
| Cascade evaluation | ✓ Configurable stages |
| Checkpoint/resume | ✓ Full state snapshots |
| Prompt engineering | ✓ Template system |

**Key Difference**: AlphaEvolve is closed-source; OpenEvolve is open and extensible!
