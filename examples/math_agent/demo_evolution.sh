#!/bin/bash

# Demo Evolution Script - Shows exactly what happens during evolution
# This script demonstrates the evolution process step-by-step

set -e

echo "============================================"
echo "  Math Agent Evolution - Live Demo"
echo "============================================"
echo ""

# Check for API key
if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  OPENAI_API_KEY not set"
    echo ""
    echo "To run this demo, you need to set your API key:"
    echo "  export OPENAI_API_KEY='sk-...'"
    echo ""
    echo "Or use OpenRouter/Together AI:"
    echo "  export OPENROUTER_API_KEY='...'"
    echo "  export TOGETHER_API_KEY='...'"
    echo ""
    echo "Then update config.yaml to point to the right API endpoint."
    echo ""
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

echo "📁 Working Directory: $SCRIPT_DIR"
echo ""

# Step 1: Show initial program
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: Initial Program Evaluation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Let's evaluate the initial program before evolution..."
echo ""

python3 << 'PYTHON_SCRIPT'
import sys
sys.path.insert(0, 'examples/math_agent')
import evaluator
import json

print("Running evaluator on initial_program.py...")
print("")

result = evaluator.evaluate('initial_program.py')

print("=" * 50)
print("  BASELINE PERFORMANCE (Before Evolution)")
print("=" * 50)
print(f"Overall Accuracy: {result['accuracy']:.1%} ({result['correct']}/{result['total']} problems)")
print(f"Combined Score:   {result['combined_score']:.3f}")
print(f"Code Complexity:  {result['complexity']} lines")
print("")

print("Performance by Category:")
print("-" * 50)
for category, accuracy in sorted(result['category_accuracies'].items()):
    status = "✓" if accuracy >= 0.5 else "✗"
    print(f"  {status} {category:20s}: {accuracy:>6.1%}")
print("")

print("Performance by Difficulty:")
print("-" * 50)
for difficulty, accuracy in sorted(result['difficulty_accuracies'].items()):
    status = "✓" if accuracy >= 0.5 else "✗"
    print(f"  {status} {difficulty:10s}: {accuracy:>6.1%}")
print("")

if result['num_errors'] > 0:
    print(f"Sample Errors ({result['num_errors']} total):")
    print("-" * 50)
    for i, error in enumerate(result.get('sample_errors', [])[:3], 1):
        print(f"{i}. Problem #{error['id']} ({error['category']}):")
        print(f"   {error['problem']}")
        print(f"   Expected: {error['expected']}, Got: {error['got']}")
        print(f"   Error: {error['error'][:60]}...")
        print("")

print("=" * 50)
print("")
PYTHON_SCRIPT

echo ""
read -p "Press Enter to continue to evolution..."
echo ""

# Step 2: Start evolution
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: Starting Evolution (10 iterations)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Running OpenEvolve with:"
echo "  - Initial Program: initial_program.py"
echo "  - Evaluator: evaluator.py"
echo "  - Config: config.yaml"
echo "  - Iterations: 10 (demo - use 500+ for real runs)"
echo ""
echo "What will happen:"
echo "  1. Load initial program into database"
echo "  2. For each iteration:"
echo "     a) Select best programs from islands"
echo "     b) Send to LLM for mutation"
echo "     c) Evaluate mutated program"
echo "     d) Update database if improved"
echo "  3. Save checkpoints"
echo ""
read -p "Press Enter to start evolution..."
echo ""

# Run evolution
python "$REPO_ROOT/openevolve-run.py" \
    "$SCRIPT_DIR/initial_program.py" \
    "$SCRIPT_DIR/evaluator.py" \
    --config "$SCRIPT_DIR/config.yaml" \
    --iterations 10

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: Analyzing Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Find the latest checkpoint
CHECKPOINT_DIR=$(ls -td openevolve_output/checkpoints/checkpoint_* 2>/dev/null | head -1)

if [ -d "$CHECKPOINT_DIR" ]; then
    echo "Latest checkpoint: $CHECKPOINT_DIR"
    echo ""

    if [ -f "$CHECKPOINT_DIR/best_program.py" ]; then
        echo "Evaluating evolved program..."
        python3 << PYTHON_SCRIPT2
import sys
sys.path.insert(0, 'examples/math_agent')
import evaluator

checkpoint_path = "$CHECKPOINT_DIR/best_program.py"
result = evaluator.evaluate(checkpoint_path)

print("=" * 50)
print("  EVOLVED PERFORMANCE")
print("=" * 50)
print(f"Overall Accuracy: {result['accuracy']:.1%} ({result['correct']}/{result['total']} problems)")
print(f"Combined Score:   {result['combined_score']:.3f}")
print("")

print("Improvements:")
print("-" * 50)
for category, accuracy in sorted(result['category_accuracies'].items()):
    if accuracy > 0:
        print(f"  ✓ {category:20s}: {accuracy:>6.1%}")
print("")
PYTHON_SCRIPT2
    fi

    echo ""
    echo "To view the evolved code:"
    echo "  cat $CHECKPOINT_DIR/best_program.py"
    echo ""
    echo "To visualize the evolution tree:"
    echo "  python scripts/visualizer.py --path $CHECKPOINT_DIR"
    echo ""
else
    echo "No checkpoints found. Evolution may have failed."
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Evolution Demo Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Run longer evolution: ./run.sh 500"
echo "  2. Add more problems to problems.json"
echo "  3. Tune config.yaml for better results"
echo "  4. Monitor checkpoints to track progress"
echo ""
