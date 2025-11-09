#!/bin/bash

# Math Agent - AWS Bedrock Setup and Runner
# This script helps you set up and run the math agent with AWS Bedrock models

set -e

echo "=========================================="
echo "  Math Agent - AWS Bedrock Setup"
echo "=========================================="
echo ""

# Check for AWS credentials
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "⚠️  AWS credentials not set"
    echo ""
    echo "Please set your AWS credentials:"
    echo "  export AWS_ACCESS_KEY_ID='your-access-key-id'"
    echo "  export AWS_SECRET_ACCESS_KEY='your-secret-access-key'"
    echo "  export AWS_REGION_NAME='us-east-1'"
    echo ""
    echo "Or configure using AWS CLI:"
    echo "  aws configure"
    echo ""
    exit 1
fi

echo "✓ AWS credentials detected"
echo ""

# Check if litellm is installed
if ! command -v litellm &> /dev/null; then
    echo "⚠️  LiteLLM not found"
    echo ""
    read -p "Install LiteLLM? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing LiteLLM..."
        pip install 'litellm[proxy]'
        echo "✓ LiteLLM installed"
    else
        echo "Please install LiteLLM manually:"
        echo "  pip install 'litellm[proxy]'"
        exit 1
    fi
else
    echo "✓ LiteLLM installed"
fi
echo ""

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if litellm proxy is already running
if curl -s http://localhost:4000/health > /dev/null 2>&1; then
    echo "✓ LiteLLM proxy already running on port 4000"
    PROXY_RUNNING=true
else
    echo "Starting LiteLLM proxy..."
    echo ""

    # Start LiteLLM in background
    litellm --config "$SCRIPT_DIR/litellm_bedrock.yaml" > /tmp/litellm.log 2>&1 &
    LITELLM_PID=$!

    # Wait for proxy to start
    echo "Waiting for proxy to start..."
    for i in {1..30}; do
        if curl -s http://localhost:4000/health > /dev/null 2>&1; then
            echo "✓ LiteLLM proxy started (PID: $LITELLM_PID)"
            PROXY_RUNNING=true
            break
        fi
        sleep 1
    done

    if [ "$PROXY_RUNNING" != "true" ]; then
        echo "✗ Failed to start LiteLLM proxy"
        echo "Check logs: tail -f /tmp/litellm.log"
        exit 1
    fi
fi
echo ""

# Test AWS Bedrock access
echo "Testing AWS Bedrock access..."
if curl -s -X POST http://localhost:4000/v1/models > /dev/null 2>&1; then
    echo "✓ Bedrock models accessible"
else
    echo "⚠️  Could not verify Bedrock access"
    echo "Make sure you have requested model access in AWS Bedrock console"
fi
echo ""

# Parameters
ITERATIONS="${1:-100}"
CHECKPOINT_DIR="${2:-}"

echo "Configuration:"
echo "  Config: config_bedrock.yaml"
echo "  LiteLLM Proxy: http://localhost:4000"
echo "  Iterations: $ITERATIONS"
if [ -n "$CHECKPOINT_DIR" ]; then
    echo "  Resuming from: $CHECKPOINT_DIR"
fi
echo ""

# Build the command
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
CMD="python $REPO_ROOT/openevolve-run.py \
    $SCRIPT_DIR/initial_program.py \
    $SCRIPT_DIR/evaluator.py \
    --config $SCRIPT_DIR/config_bedrock.yaml \
    --iterations $ITERATIONS"

if [ -n "$CHECKPOINT_DIR" ]; then
    CMD="$CMD --checkpoint $CHECKPOINT_DIR"
fi

echo "Running evolution with AWS Bedrock models..."
echo "=========================================="
echo ""

# Cleanup function
cleanup() {
    if [ -n "$LITELLM_PID" ] && [ "$LITELLM_PID" != "" ]; then
        echo ""
        echo "Stopping LiteLLM proxy (PID: $LITELLM_PID)..."
        kill $LITELLM_PID 2>/dev/null || true
    fi
}

# Register cleanup on exit
trap cleanup EXIT

# Run the evolution
eval $CMD

echo ""
echo "=========================================="
echo "Evolution complete!"
echo ""
echo "View results:"
echo "  cat openevolve_output/checkpoints/checkpoint_*/best_program.py"
echo ""
echo "LiteLLM logs:"
echo "  tail -f /tmp/litellm.log"
echo ""
