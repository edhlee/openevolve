# AWS Bedrock Configuration for Math Agent

This guide shows you how to use AWS Bedrock models (Claude, Titan, etc.) with the Math Agent instead of OpenAI.

## Setup Options

There are two ways to use AWS Bedrock with OpenEvolve:

### Option 1: Using LiteLLM Proxy (Recommended)

LiteLLM provides an OpenAI-compatible proxy for AWS Bedrock.

#### Step 1: Install LiteLLM

```bash
pip install litellm[proxy]
```

#### Step 2: Set AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION_NAME="us-east-1"  # or your preferred region
```

#### Step 3: Start LiteLLM Proxy

```bash
# Start the proxy server (runs on localhost:4000 by default)
litellm --model bedrock/anthropic.claude-3-5-sonnet-20241022-v2:0
```

Or create a config file for multiple models:

```yaml
# litellm_config.yaml
model_list:
  - model_name: claude-sonnet
    litellm_params:
      model: bedrock/anthropic.claude-3-5-sonnet-20241022-v2:0
      aws_region_name: us-east-1

  - model_name: claude-haiku
    litellm_params:
      model: bedrock/anthropic.claude-3-5-haiku-20241022-v1:0
      aws_region_name: us-east-1

  - model_name: titan
    litellm_params:
      model: bedrock/amazon.titan-text-premier-v1:0
      aws_region_name: us-east-1
```

Then start with:
```bash
litellm --config litellm_config.yaml
```

#### Step 4: Update Math Agent Config

Update `examples/math_agent/config.yaml`:

```yaml
llm:
  api_base: "http://localhost:4000"  # LiteLLM proxy
  api_key: "dummy"  # Any value works with LiteLLM
  models:
    - name: "claude-sonnet"  # Model name from litellm_config.yaml
      weight: 0.7
    - name: "claude-haiku"
      weight: 0.3
  temperature: 0.8
  max_tokens: 8000
  timeout: 180
```

#### Step 5: Run Evolution

```bash
cd examples/math_agent
./run.sh 100
```

### Option 2: Using boto3 Directly (Advanced)

This requires modifying OpenEvolve to support Bedrock's native API.

#### Step 1: Install boto3

```bash
pip install boto3
```

#### Step 2: Set AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION_NAME="us-east-1"
```

#### Step 3: Use OpenAI-compatible endpoint

AWS Bedrock doesn't have a native OpenAI-compatible endpoint, so you'll need to use LiteLLM (Option 1) or wait for OpenEvolve to add native Bedrock support.

## Available Bedrock Models

### Anthropic Claude Models

- **Claude 3.5 Sonnet v2**: `bedrock/anthropic.claude-3-5-sonnet-20241022-v2:0` (Best for reasoning)
- **Claude 3.5 Haiku**: `bedrock/anthropic.claude-3-5-haiku-20241022-v1:0` (Fast and cheap)
- **Claude 3 Opus**: `bedrock/anthropic.claude-3-opus-20240229-v1:0` (Most capable)
- **Claude 3 Sonnet**: `bedrock/anthropic.claude-3-sonnet-20240229-v1:0`
- **Claude 3 Haiku**: `bedrock/anthropic.claude-3-haiku-20240307-v1:0`

### Amazon Titan Models

- **Titan Text Premier**: `bedrock/amazon.titan-text-premier-v1:0`
- **Titan Text Express**: `bedrock/amazon.titan-text-express-v1`
- **Titan Text Lite**: `bedrock/amazon.titan-text-lite-v1`

### Meta Llama Models

- **Llama 3.2 90B**: `bedrock/meta.llama3-2-90b-instruct-v1:0`
- **Llama 3.2 11B**: `bedrock/meta.llama3-2-11b-instruct-v1:0`
- **Llama 3.2 3B**: `bedrock/meta.llama3-2-3b-instruct-v1:0`
- **Llama 3.2 1B**: `bedrock/meta.llama3-2-1b-instruct-v1:0`

### Mistral Models

- **Mistral Large**: `bedrock/mistral.mistral-large-2407-v1:0`
- **Mistral Small**: `bedrock/mistral.mistral-small-2402-v1:0`

## Recommended Configuration for Math Agent

For best results with the math agent, use Claude 3.5 Sonnet v2:

```yaml
# config.yaml
llm:
  api_base: "http://localhost:4000"
  api_key: "dummy"
  models:
    - name: "claude-sonnet"
      weight: 0.8
    - name: "claude-haiku"
      weight: 0.2
  temperature: 0.8
  max_tokens: 8000
  timeout: 180
```

With `litellm_config.yaml`:

```yaml
model_list:
  - model_name: claude-sonnet
    litellm_params:
      model: bedrock/anthropic.claude-3-5-sonnet-20241022-v2:0
      aws_region_name: us-east-1
      max_tokens: 8000

  - model_name: claude-haiku
    litellm_params:
      model: bedrock/anthropic.claude-3-5-haiku-20241022-v1:0
      aws_region_name: us-east-1
      max_tokens: 8000
```

## Costs (AWS Bedrock Pricing)

Example costs for Claude 3.5 Sonnet v2 in us-east-1:

- **Input**: $3.00 per million tokens
- **Output**: $15.00 per million tokens

For 500 iterations with ~2000 tokens per iteration:
- Total tokens: ~1 million tokens
- Estimated cost: ~$3-10 depending on input/output ratio

Compare to OpenAI GPT-4o:
- **Input**: $2.50 per million tokens
- **Output**: $10.00 per million tokens

Bedrock is slightly more expensive but you have more control over data residency and can use cross-region inference.

## Troubleshooting

### Issue: "Connection refused" when connecting to LiteLLM

**Solution**: Make sure LiteLLM proxy is running:
```bash
litellm --config litellm_config.yaml
```

### Issue: AWS credentials not found

**Solution**: Set environment variables:
```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_REGION_NAME="us-east-1"
```

Or use AWS CLI configuration:
```bash
aws configure
```

### Issue: Model not found in Bedrock

**Solution**: Check if the model is enabled in your AWS account:
1. Go to AWS Bedrock console
2. Navigate to "Model access"
3. Request access to the models you want to use

### Issue: Rate limits or throttling

**Solution**:
- Reduce `parallel_evaluations` in config.yaml
- Add retry logic (LiteLLM handles this automatically)
- Request quota increase in AWS console

## Performance Tips

1. **Use haiku for diversity**: Claude Haiku is 10x cheaper and faster, good for generating diverse mutations
2. **Regional endpoints**: Use the AWS region closest to you for lower latency
3. **Batch processing**: LiteLLM supports request batching for better throughput
4. **Caching**: Enable prompt caching in LiteLLM config to reduce costs

## Complete Example

Here's a complete setup:

```bash
# 1. Install dependencies
pip install litellm[proxy] boto3

# 2. Set AWS credentials
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_REGION_NAME="us-east-1"

# 3. Create LiteLLM config
cat > litellm_config.yaml << 'EOF'
model_list:
  - model_name: claude-sonnet
    litellm_params:
      model: bedrock/anthropic.claude-3-5-sonnet-20241022-v2:0
      aws_region_name: us-east-1
      max_tokens: 8000

  - model_name: claude-haiku
    litellm_params:
      model: bedrock/anthropic.claude-3-5-haiku-20241022-v1:0
      aws_region_name: us-east-1
      max_tokens: 8000
EOF

# 4. Start LiteLLM proxy (in separate terminal)
litellm --config litellm_config.yaml

# 5. Run evolution
cd examples/math_agent
./run.sh 100
```

That's it! Your evolution will now use AWS Bedrock models instead of OpenAI.
