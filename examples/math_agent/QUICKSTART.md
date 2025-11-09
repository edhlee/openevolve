# Math Agent - Quick Start Guide

## TL;DR - Get Started in 3 Steps

```bash
# 1. Set API key
export OPENAI_API_KEY="sk-..."

# 2. Run evolution
cd examples/math_agent
./run.sh 100

# 3. Check results
cat openevolve_output/checkpoints/checkpoint_100/best_program.py
```

## Complete Walkthrough

### Step 1: Prerequisites

**Required:**
- Python 3.10+
- API key for one of:
  - OpenAI
  - AWS Bedrock
  - OpenRouter
  - Together AI

**Install:**
```bash
pip install -e ".[dev]"
```

**Set API Key:**
```bash
# Option 1: OpenAI
export OPENAI_API_KEY="sk-..."

# Option 2: AWS Bedrock (Claude, Titan, Llama, Mistral)
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION_NAME="us-east-1"
# Then use: ./run_bedrock.sh 100

# Option 3: OpenRouter
export OPENROUTER_API_KEY="sk-..."
# Then update config.yaml api_base to: "https://openrouter.ai/api/v1"

# Option 4: Together AI
export TOGETHER_API_KEY="..."
# Then update config.yaml api_base to: "https://api.together.xyz/v1"
```

### Step 2: Understanding the Components

**What you have:**
```
examples/math_agent/
├── initial_program.py    ← Starting solver (40% accurate)
├── evaluator.py          ← Tests against 20 problems
├── problems.json         ← Problem dataset
├── config.yaml           ← Evolution settings
└── run.sh                ← Quick start script
```

**What you'll get:**
```
examples/math_agent/
└── openevolve_output/
    ├── checkpoints/
    │   ├── checkpoint_25/
    │   │   ├── best_program.py   ← Evolved solver
    │   │   ├── metadata.json     ← Stats
    │   │   └── database.pkl      ← Population
    │   ├── checkpoint_50/
    │   └── ...
    └── evolution.log
```

### Step 3: Run Your First Evolution

**Option A: Quick demo (10 iterations, ~5 minutes)**
```bash
cd examples/math_agent

# Interactive demo with explanations
./demo_evolution.sh
```

**Option B: Short run (100 iterations, ~30-60 minutes)**
```bash
./run.sh 100
```

**Option C: Full run (500 iterations, ~2-4 hours)**
```bash
./run.sh 500
```

**Option D: Custom run**
```bash
python ../../openevolve-run.py \
    initial_program.py \
    evaluator.py \
    --config config.yaml \
    --iterations 200
```

### Step 4: Monitor Progress

**Watch logs in real-time:**
```bash
tail -f openevolve_output/evolution.log
```

**Check latest results:**
```bash
# Find latest checkpoint
ls -lt openevolve_output/checkpoints/

# View best program
cat openevolve_output/checkpoints/checkpoint_100/best_program.py

# Check stats
cat openevolve_output/checkpoints/checkpoint_100/metadata.json
```

**Evaluate evolved program:**
```bash
cd examples/math_agent
python -c "
import evaluator
result = evaluator.evaluate('openevolve_output/checkpoints/checkpoint_100/best_program.py')
print(f'Accuracy: {result[\"accuracy\"]:.1%}')
print(f'Score: {result[\"combined_score\"]:.3f}')
"
```

### Step 5: Analyze Results

**What to look for:**

✅ **Good signs:**
- Accuracy increasing: 40% → 50% → 60% → ...
- Score trending upward
- New categories solved
- Fewer errors in logs

⚠️ **Warning signs:**
- Stuck at same score for 50+ iterations
- Lots of errors in logs
- Accuracy decreasing
- Programs timing out

**View improvements:**
```bash
# Compare initial vs evolved
echo "=== INITIAL PROGRAM ==="
python -c "import evaluator; r = evaluator.evaluate('initial_program.py'); print(f\"Accuracy: {r['accuracy']:.1%}\")"

echo "=== EVOLVED PROGRAM ==="
python -c "import evaluator; r = evaluator.evaluate('openevolve_output/checkpoints/checkpoint_100/best_program.py'); print(f\"Accuracy: {r['accuracy']:.1%}\")"
```

### Step 6: Resume or Continue

**If interrupted:**
```bash
# Resume from checkpoint 50
./run.sh 50 openevolve_output/checkpoints/checkpoint_50/
```

**If you want to continue further:**
```bash
# Run 100 MORE iterations beyond checkpoint 100
python ../../openevolve-run.py \
    initial_program.py \
    evaluator.py \
    --config config.yaml \
    --checkpoint openevolve_output/checkpoints/checkpoint_100/ \
    --iterations 100
```

## Expected Results

### After 10 iterations (~5 min)
```
Accuracy: 45-55%
Score: 0.3-0.4
New categories: Maybe 1-2
```

### After 100 iterations (~1 hour)
```
Accuracy: 60-75%
Score: 0.5-0.7
New categories: 3-5
Starting to solve harder problems
```

### After 500 iterations (~3 hours)
```
Accuracy: 80-95%
Score: 0.75-0.9
Most categories: 80%+
Near-optimal solutions
```

## Customization

### Easy Tweaks

**Run longer:**
```yaml
# config.yaml
max_iterations: 1000  # Instead of 500
```

**More creativity:**
```yaml
# config.yaml
llm:
  temperature: 0.9  # Instead of 0.7
```

**More parallel processing:**
```yaml
# config.yaml
parallel_evaluations: 8  # Instead of 4
```

### Add Your Own Problems

Edit `problems.json`:
```json
{
  "id": 21,
  "category": "algebra",
  "difficulty": "hard",
  "problem": "Solve the quartic equation: x^4 - 5x^3 + 5x^2 + 5x - 6 = 0. Return the smallest positive real root.",
  "answer": 1.0,
  "tolerance": 0.001
}
```

### Use Different Models

```yaml
# config.yaml
llm:
  models:
    - name: "anthropic/claude-3.5-sonnet"
      weight: 0.8
    - name: "openai/gpt-4o"
      weight: 0.2
```

## Troubleshooting

### Problem: No API key error
```bash
export OPENAI_API_KEY="sk-..."
```

### Problem: All scores are 0.0
- Check that problems.json is accessible
- Verify initial_program.py has working implementations
- Check logs for import errors

### Problem: Evolution stuck (no improvement)
- Increase temperature in config.yaml
- Add more islands
- Check if problems are too hard

### Problem: Out of memory
- Reduce `parallel_evaluations` in config.yaml
- Reduce `population_size`

### Problem: Timeouts
- Increase `evaluator.timeout` in config.yaml
- Check if programs have infinite loops

## Next Steps

1. ✅ **Run your first evolution** (start with 100 iterations)
2. 📊 **Monitor progress** (watch the checkpoints)
3. 🔍 **Analyze results** (read MONITORING_GUIDE.md)
4. 🎨 **Customize** (add problems, tune config)
5. 🚀 **Scale up** (run 500+ iterations for best results)

## Learn More

- **README.md** - Comprehensive overview and features
- **ARCHITECTURE.md** - How the system works internally
- **EXAMPLE_PROMPT.md** - See what the LLM receives
- **MONITORING_GUIDE.md** - Advanced monitoring techniques

## Support

- Issues: https://github.com/edhlee/openevolve/issues
- Examples: Check other `examples/` directories
- AlphaEvolve Paper: https://arxiv.org/abs/2412.xxxxx

---

**Ready to evolve?** 🧬

```bash
cd examples/math_agent && ./run.sh 100
```

Happy evolving! 🚀
