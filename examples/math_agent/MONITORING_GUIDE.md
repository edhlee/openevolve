# Evolution Monitoring Guide

## Real-Time Monitoring

### Watch the logs as evolution runs

```bash
# Start evolution
./run.sh 500

# In another terminal, watch the logs
tail -f openevolve_output/evolution.log
```

You'll see output like:
```
[2025-11-09 12:00:00] INFO - Starting evolution...
[2025-11-09 12:00:01] INFO - Initial evaluation: Score=0.239, Accuracy=40%
[2025-11-09 12:00:05] INFO - [Iter 1/500] Evaluating mutation...
[2025-11-09 12:00:10] INFO - [Iter 1/500] NEW BEST! 0.239 → 0.387 (+62%)
[2025-11-09 12:00:15] INFO - [Iter 2/500] Evaluating mutation...
[2025-11-09 12:00:20] INFO - [Iter 2/500] No improvement (score: 0.352)
[2025-11-09 12:00:25] INFO - [Iter 3/500] Evaluating mutation...
[2025-11-09 12:00:30] INFO - [Iter 3/500] NEW BEST! 0.387 → 0.456 (+18%)
...
```

## Checkpoint Analysis

### After each checkpoint (every 25 iterations)

```bash
# Navigate to latest checkpoint
cd openevolve_output/checkpoints/checkpoint_25/

# View the best program so far
cat best_program.py

# Check metadata
cat metadata.json
```

### Metadata shows:
```json
{
  "iteration": 25,
  "best_score": 0.678,
  "best_accuracy": 0.75,
  "timestamp": "2025-11-09T12:05:00",
  "total_evaluations": 25,
  "successful_mutations": 12,
  "database_stats": {
    "total_programs": 45,
    "islands": 5,
    "populated_cells": 32
  },
  "category_performance": {
    "algebra": 1.0,
    "calculus": 1.0,
    "number_theory": 1.0,
    "geometry": 1.0,
    "trigonometry": 1.0,
    "combinatorics": 1.0,
    "statistics": 1.0,
    "sequences": 0.5,
    "optimization": 0.5,
    "linear_algebra": 0.0
  }
}
```

## Progress Tracking Script

Create a script to track progress across checkpoints:

```bash
#!/bin/bash
# track_progress.sh

echo "Evolution Progress Tracker"
echo "=========================="
echo ""

for checkpoint in openevolve_output/checkpoints/checkpoint_*/; do
    if [ -f "$checkpoint/metadata.json" ]; then
        iter=$(jq -r '.iteration' "$checkpoint/metadata.json")
        score=$(jq -r '.best_score' "$checkpoint/metadata.json")
        accuracy=$(jq -r '.best_accuracy' "$checkpoint/metadata.json")

        printf "Iter %3d: Score=%.3f, Accuracy=%.1f%%\n" \
            "$iter" "$score" "$(echo "$accuracy * 100" | bc)"
    fi
done
```

## Visualization Commands

### View evolution tree
```bash
python scripts/visualizer.py \
    --path openevolve_output/checkpoints/checkpoint_500/
```

This creates a visual graph showing:
- Program lineage (which programs evolved from which)
- Score improvements over time
- Island populations and migrations
- Feature space distribution

### Compare checkpoints

```bash
# Compare checkpoint 100 vs 500
python examples/math_agent/evaluator.py \
    openevolve_output/checkpoints/checkpoint_100/best_program.py

python examples/math_agent/evaluator.py \
    openevolve_output/checkpoints/checkpoint_500/best_program.py
```

## Interactive Monitoring Dashboard (DIY)

Create a simple monitoring dashboard:

```python
# monitor.py
import json
import time
from pathlib import Path

def monitor_evolution(output_dir="openevolve_output/checkpoints"):
    checkpoints = sorted(Path(output_dir).glob("checkpoint_*"))

    print("\033[2J\033[H")  # Clear screen
    print("=" * 60)
    print("  MATH AGENT EVOLUTION - LIVE DASHBOARD")
    print("=" * 60)

    if not checkpoints:
        print("No checkpoints found yet...")
        return

    latest = checkpoints[-1]
    metadata_file = latest / "metadata.json"

    if metadata_file.exists():
        with open(metadata_file) as f:
            data = json.load(f)

        print(f"\nLatest Checkpoint: {latest.name}")
        print(f"Iteration: {data['iteration']}")
        print(f"Best Score: {data['best_score']:.3f}")
        print(f"Best Accuracy: {data['best_accuracy']:.1%}")
        print(f"Successful Mutations: {data['successful_mutations']}")

        print("\nCategory Performance:")
        print("-" * 60)
        for cat, acc in sorted(data['category_performance'].items()):
            bar = "█" * int(acc * 40)
            status = "✓" if acc >= 0.5 else "✗"
            print(f"{status} {cat:20s} [{bar:<40s}] {acc:.1%}")

        print("\nProgress Over Time:")
        print("-" * 60)
        scores = []
        for cp in checkpoints[-10:]:  # Last 10 checkpoints
            cp_meta = cp / "metadata.json"
            if cp_meta.exists():
                with open(cp_meta) as f:
                    cp_data = json.load(f)
                scores.append((cp_data['iteration'], cp_data['best_score']))

        for iter_num, score in scores:
            bar = "█" * int(score * 40)
            print(f"Iter {iter_num:3d}: [{bar:<40s}] {score:.3f}")

if __name__ == "__main__":
    while True:
        monitor_evolution()
        time.sleep(5)  # Refresh every 5 seconds
        print("\n\nRefreshing in 5 seconds... (Ctrl+C to stop)")
```

Run it:
```bash
python monitor.py
```

## Key Metrics to Watch

### 1. **Best Score Trajectory**
- Should generally trend upward
- Plateaus are normal (exploration phase)
- Sudden jumps indicate breakthrough mutations

### 2. **Successful Mutation Rate**
- Healthy: 20-40% of mutations improve the population
- Too low (<10%): Might need higher temperature or more diversity
- Too high (>60%): Might indicate easy problem or lucky streak

### 3. **Category Coverage**
- Which categories are improving?
- Which are stuck at 0%?
- Adjust prompts to focus on weak areas

### 4. **Code Complexity**
- More complex ≠ better
- Watch for code bloat
- Best programs often find elegant solutions

## Debugging Poor Performance

### If evolution isn't improving:

1. **Check LLM Responses**
   - Add verbose logging to see what LLM is generating
   - Look for syntax errors or malformed code

2. **Review Evaluation Errors**
   - Check `openevolve_output/errors/` directory
   - Common issues: import errors, timeout, crashes

3. **Inspect Database**
   ```python
   import pickle
   with open('openevolve_output/checkpoints/checkpoint_25/database.pkl', 'rb') as f:
       db = pickle.load(f)
   print(f"Total programs: {len(db.programs)}")
   print(f"Best score: {db.best_score}")
   ```

4. **Adjust Config**
   - Increase `temperature` for more creativity
   - Add more `num_top_programs` for more context
   - Reduce `timeout` if programs hang
   - Add more `islands` for diversity

## Expected Evolution Patterns

### Typical progression for Math Agent:

```
Iterations 1-50:    Rapid initial improvement (40% → 60%)
                    - LLM adds basic implementations
                    - Low-hanging fruit solved

Iterations 51-150:  Steady progress (60% → 75%)
                    - Refinement of existing solvers
                    - Edge case handling
                    - Better parsing

Iterations 151-300: Slower gains (75% → 85%)
                    - Hard problems tackled
                    - Optimization and polish
                    - Some plateaus expected

Iterations 301-500: Fine-tuning (85% → 90-95%)
                    - Last few problems solved
                    - Code elegance improvements
                    - May plateau if problems are too hard
```

## When to Stop Evolution

Stop when:
1. ✅ Target accuracy reached (e.g., 95%)
2. ✅ Score plateaus for 100+ iterations
3. ✅ All solvable problems solved (some may be too hard)
4. ✅ Budget/time limits reached

## Resuming Evolution

If interrupted or want to continue:

```bash
# Resume from iteration 250
./run.sh 250 openevolve_output/checkpoints/checkpoint_250/

# Or specify additional iterations
python openevolve-run.py \
    examples/math_agent/initial_program.py \
    examples/math_agent/evaluator.py \
    --config examples/math_agent/config.yaml \
    --checkpoint openevolve_output/checkpoints/checkpoint_250/ \
    --iterations 250  # Will run 250 MORE iterations (to iteration 500)
```

## Best Practices

1. **Save checkpoints frequently** (every 10-25 iterations)
2. **Monitor first 50 iterations closely** to catch issues early
3. **Keep notes** on what prompts/configs work well
4. **Archive successful runs** before experimenting
5. **Test evolved programs** on NEW problems to check generalization

Happy evolving! 🧬🚀
