# Math Agent - AlphaEvolve-Style Math Problem Solver

This example demonstrates how to use OpenEvolve to create a general-purpose mathematical problem-solving agent inspired by Google DeepMind's AlphaEvolve.

## Overview

The Math Agent uses evolutionary computation to evolve a program that can solve diverse mathematical problems across multiple categories:

- **Algebra**: Linear, quadratic, and polynomial equations
- **Calculus**: Derivatives, integrals, optimization
- **Number Theory**: GCD, LCM, divisibility
- **Geometry**: Areas, volumes, spatial calculations
- **Linear Algebra**: Matrix operations, determinants
- **Sequences**: Arithmetic and geometric progressions
- **Trigonometry**: Sine, cosine, identities
- **Statistics**: Mean, variance, standard deviation
- **Combinatorics**: Permutations, combinations

## Components

### 1. `initial_program.py`

The starting template for the math solver. It contains:
- A `MathSolver` class with category-specific solving methods
- Basic implementations for some problem types
- Room for evolution to improve and expand capabilities

The code within `# EVOLVE-BLOCK-START` and `# EVOLVE-BLOCK-END` markers will be evolved by the LLM.

### 2. `evaluator.py`

Evaluates the solver against a dataset of 20 math problems across different categories and difficulty levels. Returns metrics including:
- **accuracy**: Overall percentage of correct solutions
- **combined_score**: Weighted score (easy=1x, medium=2x, hard=3x)
- **category_accuracies**: Performance breakdown by category
- **difficulty_accuracies**: Performance by difficulty level
- **avg_time_per_problem**: Average solving time
- **complexity**: Code complexity metric

### 3. `problems.json`

A dataset of 20 diverse math problems with:
- Problem statements in natural language
- Expected numerical answers
- Tolerance for numerical precision
- Category and difficulty labels

### 4. `config.yaml`

Configuration for the evolution process:
- LLM settings (models, temperature, tokens)
- Database/MAP-Elites parameters
- Evaluation timeouts and retries
- Prompt engineering and system messages

## Quick Start

### Prerequisites

1. Install OpenEvolve:
```bash
pip install -e ".[dev]"
```

2. Set up your LLM API key:
```bash
export OPENAI_API_KEY="your-api-key-here"
# Or for other providers:
# export OPENROUTER_API_KEY="your-key"
# export TOGETHER_API_KEY="your-key"
```

### Running the Math Agent

1. **Start a new evolution run**:
```bash
python openevolve-run.py \
  examples/math_agent/initial_program.py \
  examples/math_agent/evaluator.py \
  --config examples/math_agent/config.yaml \
  --iterations 500
```

2. **Monitor progress**:
The evolution will run for 500 iterations, creating checkpoints every 25 iterations in `examples/math_agent/openevolve_output/`.

3. **Resume from checkpoint** (if interrupted):
```bash
python openevolve-run.py \
  examples/math_agent/initial_program.py \
  examples/math_agent/evaluator.py \
  --config examples/math_agent/config.yaml \
  --checkpoint examples/math_agent/openevolve_output/checkpoints/checkpoint_100/ \
  --iterations 100
```

## What to Expect

### Initial Performance
The initial program has basic implementations for:
- GCD and LCM (number theory)
- Circle area and sphere volume (geometry)
- Mean calculation (statistics)
- Combinatorics (choose and permutations)

Expected initial accuracy: **30-40%** (6-8 problems out of 20)

### Evolution Process

The evolution will:
1. **Improve parsing**: Better extraction of numbers and operations from text
2. **Add solvers**: Implement missing category solvers (algebra, calculus, etc.)
3. **Refine algorithms**: Improve accuracy of existing solvers
4. **Handle edge cases**: Better error handling and validation
5. **Optimize**: Balance between accuracy and code complexity

### Target Performance

After 500 iterations, you should expect:
- **Accuracy**: 75-95% (15-19 problems out of 20)
- **Combined score**: 0.7-0.9 (accounting for difficulty weights)
- **Strong category coverage**: Good performance across most categories

## Customization

### Adding More Problems

Edit `problems.json` to add your own math problems:

```json
{
  "id": 21,
  "category": "calculus",
  "difficulty": "hard",
  "problem": "Find the limit of (sin(x)/x) as x approaches 0.",
  "answer": 1.0,
  "tolerance": 0.001
}
```

### Tuning Evolution Parameters

Edit `config.yaml` to adjust:
- **max_iterations**: More iterations = better solutions (but more cost/time)
- **population_size**: Larger populations = more diversity
- **num_islands**: More islands = better exploration vs exploitation balance
- **temperature**: Higher = more creative mutations, lower = more conservative

### Using Different LLMs

Update the `llm.models` section in `config.yaml`:

```yaml
llm:
  api_base: "https://openrouter.ai/api/v1"
  models:
    - name: "anthropic/claude-3.5-sonnet"
      weight: 0.8
    - name: "openai/gpt-4o"
      weight: 0.2
```

## Visualization

View the evolution tree after running:

```bash
python scripts/visualizer.py \
  --path examples/math_agent/openevolve_output/checkpoints/checkpoint_500/
```

This shows:
- Evolution history and lineage
- Performance improvements over time
- Island populations and migrations
- Feature space distribution

## Tips for Best Results

1. **Start small**: Run a few hundred iterations first to verify everything works
2. **Monitor checkpoints**: Check intermediate results to ensure progress
3. **Tune prompts**: Modify the system message in `config.yaml` based on what the LLM struggles with
4. **Add problem diversity**: Include problems that challenge current weaknesses
5. **Use strong models**: Better LLMs (GPT-4, Claude) produce better evolution
6. **Patience**: Good evolution takes time and iterations

## AlphaEvolve Alignment

This example follows the AlphaEvolve methodology:

1. **Problem-Centric**: Focused on solving a specific domain (math problems)
2. **Evolutionary**: Uses MAP-Elites for population diversity
3. **LLM-Driven**: Leverages LLMs for code mutation and improvement
4. **Benchmarked**: Evaluates against a standard problem set
5. **Iterative**: Progressively improves through many generations

## Troubleshooting

**Problem**: Evolution gets stuck (no improvement)
- **Solution**: Increase temperature, add more islands, or diversify the problem set

**Problem**: All solutions score 0.0
- **Solution**: Check that initial_program.py has some working implementations, verify problems.json is accessible

**Problem**: Timeout errors
- **Solution**: Increase `evaluator.timeout` in config.yaml, or optimize initial_program.py

**Problem**: Out of memory
- **Solution**: Reduce `parallel_evaluations` and `population_size` in config.yaml

## Next Steps

1. **Extend to harder problems**: Add problems from competition math (AMC, AIME, IMO)
2. **Symbolic solving**: Use SymPy for algebraic manipulation
3. **Natural language**: Improve problem parsing with NLP
4. **Interactive solving**: Show step-by-step solutions
5. **Multi-modal**: Include problems with diagrams or graphs

## References

- [AlphaEvolve Repository](https://github.com/google-deepmind/alphaevolve_repository_of_problems)
- [OpenEvolve Framework](https://github.com/edhlee/openevolve)
- [MAP-Elites Algorithm](https://arxiv.org/abs/1504.04909)

## License

This example is provided as part of OpenEvolve and follows the same license.
