#!/bin/bash

# Math Agent - Quick Start Script
# This script runs the OpenEvolve math problem-solving agent

set -e

echo "=== Math Agent - AlphaEvolve-Style Math Problem Solver ==="
echo ""

# Check if OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  Warning: OPENAI_API_KEY not set"
    echo "Please set your API key:"
    echo "  export OPENAI_API_KEY='your-key-here'"
    echo ""
    echo "Or for other providers:"
    echo "  export OPENROUTER_API_KEY='your-key'"
    echo "  export TOGETHER_API_KEY='your-key'"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# Default parameters
ITERATIONS="${1:-100}"
CHECKPOINT_DIR="${2:-}"

echo "Configuration:"
echo "  Initial Program: $SCRIPT_DIR/initial_program.py"
echo "  Evaluator: $SCRIPT_DIR/evaluator.py"
echo "  Config: $SCRIPT_DIR/config.yaml"
echo "  Iterations: $ITERATIONS"
if [ -n "$CHECKPOINT_DIR" ]; then
    echo "  Resuming from: $CHECKPOINT_DIR"
fi
echo ""

# Build the command
CMD="python $REPO_ROOT/openevolve-run.py \
    $SCRIPT_DIR/initial_program.py \
    $SCRIPT_DIR/evaluator.py \
    --config $SCRIPT_DIR/config.yaml \
    --iterations $ITERATIONS"

if [ -n "$CHECKPOINT_DIR" ]; then
    CMD="$CMD --checkpoint $CHECKPOINT_DIR"
fi

echo "Running: $CMD"
echo ""
echo "Press Ctrl+C to stop"
echo "============================================"
echo ""

# Run the evolution
eval $CMD
