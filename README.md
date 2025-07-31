# aws-bedrock-summarizer

# AWS Bedrock Lambda with Meta Llama3 8B

This Terraform configuration creates an AWS Lambda function that invokes the Meta Llama3 8B Instruct model via AWS Bedrock. The setup includes proper IAM roles, permissions, and a Python Lambda function for seamless AI model integration.

## Architecture

- **Lambda Function**: Python 3.11 runtime that calls Bedrock
- **IAM Role**: Least-privilege access to Bedrock and CloudWatch
- **Bedrock Model**: Meta Llama3 8B Instruct (`meta.llama3-8b-instruct-v1:0`)
- **CloudWatch Logs**: Centralized logging for monitoring and debugging
- **Function URL**: Optional HTTP endpoint for direct invocation

## Resources Created

- **AWS Lambda Function**: Python function with Bedrock integration
- **IAM Role and Policies**: Secure access to Bedrock and logging
- **CloudWatch Log Group**: Structured logging with configurable retention
- **Lambda Function URL**: HTTP endpoint for external access

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.0)
3. **Python 3.11** for local testing (optional)
4. **Bedrock model access** for Meta Llama3 8B Instruct

### Model Access Requirements

Before deploying, ensure you have access to the Meta Llama3 model:

1. Go to AWS Bedrock Console
2. Navigate to "Model access"
3. Request access to "Meta Llama3 8B Instruct"
4. Wait for approval (usually immediate for most regions)

### Supported Regions

Meta Llama3 is available in these regions:
- us-east-1 (N. Virginia)
- us-west-2 (Oregon)
- eu-west-1 (Ireland)
- ap-southeast-1 (Singapore)
- ap-northeast-1 (Tokyo)

## Usage

### 1. Deploy Infrastructure

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit variables as needed
nano terraform.tfvars

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

### 2. Test the Lambda Function

#### Using AWS CLI
```bash
# Get function name from Terraform output
FUNCTION_NAME=$(terraform output -raw lambda_function_name)

# Test with simple prompt
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload '{"prompt":"What is artificial intelligence?","max_tokens":200}' \
  response.json

# View response
cat response.json | jq '.'
```

#### Using Function URL
```bash
# Get the function URL
FUNCTION_URL=$(terraform output -raw lambda_function_url)

# Test with curl
curl -X POST $FUNCTION_URL \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain machine learning in simple terms",
    "max_tokens": 300,
    "temperature": 0.7,
    "top_p": 0.9
  }'
```

### 3. Local Testing

```bash
# Test the Python function locally
cd terraform-directory
python lambda_function.py
```

## Lambda Function Parameters

The Lambda function accepts the following parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `prompt` | string | "Hello, how are you?" | Input text for the model |
| `max_tokens` | integer | 512 | Maximum tokens to generate |
| `temperature` | float | 0.7 | Randomness (0.0-1.0) |
| `top_p` | float | 0.9 | Nucleus sampling parameter |

### Example Request
```json
{
  "prompt": "Write a Python function to calculate fibonacci numbers",
  "max_tokens": 500,
  "temperature": 0.5,
  "top_p": 0.8
}
```

### Example Response
```json
{
  "statusCode": 200,
  "body": {
    "success": true,
    "generated_text": "Here's a Python function to calculate Fibonacci numbers:\n\n```python\ndef fibonacci(n):\n    if n <= 1:\n        return n\n    return fibonacci(n-1) + fibonacci(n-2)\n```",
    "model_id": "meta.llama3-8b-instruct-v1:0",
    "input_prompt": "Write a Python function to calculate fibonacci numbers",
    "parameters": {
      "max_tokens": 500,
      "temperature": 0.5,
      "top_p": 0.8
    }
  }
}
```

## Python Integration Examples

### Using boto3 directly
```python
import boto3
import json

lambda_client = boto3.client('lambda', region_name='us-east-1')

def call_bedrock_lambda(prompt, max_tokens=200):
    payload = {
        "prompt": prompt,
        "max_tokens": max_tokens,
        "temperature": 0.7
    }
    
    response = lambda_client.invoke(
        FunctionName='your-function-name',
        Payload=json.dumps(payload)
    )
    
    result = json.loads(response['Payload'].read())
    return json.loads(result['body'])

# Example usage
result = call_bedrock_lambda("Explain quantum computing")
print(result['generated_text'])
```

### Using requests (with Function URL)
```python
import requests
import json

def call_bedrock_api(prompt, function_url, max_tokens=200):
    payload = {
        "prompt": prompt,
        "max_tokens": max_tokens,
        "temperature": 0.7
    }
    
    response = requests.post(function_url, json=payload)
    return response.json()

# Example usage
function_url = "https://your-function-url.lambda-url.us-east-1.on.aws/"
result = call_bedrock_api("What is AWS Lambda?", function_url)
print(result['generated_text'])
```

## Configuration Options

### Terraform Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for deployment | `us-east-1` | No |
| `project_name` | Project name prefix | `bedrock-llama` | No |
| `log_retention_days` | CloudWatch log retention | `30` | No |
| `tags` | Resource tags | See variables.tf | No |

### Lambda Environment Variables

The Lambda function uses these environment variables:
- `MODEL_ID`: Bedrock model identifier
- `AWS_REGION`: AWS region for Bedrock client

## Monitoring and Logging

### CloudWatch Logs
```bash
# View recent logs
aws logs tail /aws/lambda/your-function-name --follow

# Filter for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/your-function-name \
  --filter-pattern "ERROR"
```

### CloudWatch Metrics
The Lambda function automatically publishes metrics:
- Duration
- Error count
- Invocation count
- Throttles

### Custom Monitoring
```python
import boto3

cloudwatch = boto3.client('cloudwatch')

# Put custom metric
cloudwatch.put_metric_data(
    Namespace='BedrockLambda',
    MetricData=[
        {
            'MetricName': 'TokensGenerated',
            'Value': token_count,
            'Unit': 'Count'
        }
    ]
)
```

## Error Handling

The Lambda function handles several error types:

1. **ClientError**: AWS service errors (permissions, model access)
2. **JSONDecodeError**: Invalid request format
3. **General Exception**: Unexpected errors

### Common Error Scenarios

#### Model Access Denied
```json
{
  "success": false,
  "error": "AWS Error: AccessDeniedException",
  "message": "User is not authorized to perform: bedrock:InvokeModel"
}
```
**Solution**: Request model access in Bedrock Console

#### Invalid Parameters
```json
{
  "success": false,
  "error": "Invalid JSON format",
  "message": "Expecting value: line 1 column 1 (char 0)"
}
```
**Solution**: Ensure proper JSON formatting in requests

## Performance Optimization

### Lambda Configuration
- **Memory**: 256MB (adjustable based on needs)
- **Timeout**: 60 seconds (sufficient for most prompts)
- **Runtime**: Python 3.11 (latest supported)

### Best Practices
1. **Prompt Engineering**: Craft clear, specific prompts
2. **Token Management**: Set appropriate `max_tokens` limits
3. **Caching**: Consider caching frequent responses
4. **Batch Processing**: Group similar requests when possible

## Cost Optimization

### Bedrock Pricing
- Meta Llama3 8B: ~$0.0003 per 1K input tokens, ~$0.0006 per 1K output tokens
- Pricing varies by region

### Lambda Pricing
- First 1M requests/month: Free
- $0.20 per 1M requests thereafter
- $0.0000166667 per GB-second

### Cost Monitoring
```bash
# Check Lambda costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

## Security Best Practices

1. **IAM Least Privilege**: Role only has necessary Bedrock permissions
2. **Function URL**: Consider adding authentication for production
3. **Input Validation**: Validate and sanitize all inputs
4. **Logging**: Avoid logging sensitive information
5. **VPC**: Consider VPC deployment for sensitive workloads

### Adding Authentication
```python
# Example: API Key authentication
def validate_api_key(event):
    headers = event.get('headers', {})
    api_key = headers.get('x-api-key')
    
    if not api_key or api_key != os.environ.get('API_KEY'):
        return False
    return True
```

## Troubleshooting

### Common Issues

1. **Model Not Available**
   ```bash
   # Check available models
   aws bedrock list-foundation-models --region us-east-1
   ```

2. **Permission Errors**
   ```bash
   # Verify IAM role
   aws iam get-role --role-name your-lambda-role
   ```

3. **Lambda Timeout**
   - Increase timeout in Terraform configuration
   - Optimize prompt length and parameters

### Debug Commands
```bash
# Test Lambda locally
python lambda_function.py

# Check Lambda configuration
aws lambda get-function --function-name your-function-name

# View CloudWatch logs
aws logs describe-log-streams --log-group-name /aws/lambda/your-function-name
```

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Confirm cleanup
aws lambda list-functions --query 'Functions[?FunctionName==`your-function-name`]'
```

## Advanced Usage

### Streaming Responses
For longer responses, consider implementing streaming:

```python
def invoke_model_stream(prompt):
    response = bedrock_runtime.invoke_model_with_response_stream(
        modelId=model_id,
        body=json.dumps(request_body)
    )
    
    for event in response['body']:
        chunk = json.loads(event['chunk']['bytes'])
        yield chunk.get('generation', '')
```

### Batch Processing
```python
def process_batch(prompts):
    results = []
    for prompt in prompts:
        result = invoke_bedrock_model(prompt)
        results.append(result)
    return results
```

## Additional Resources

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Meta Llama3 Model Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/model-parameters-meta.html)
- [Lambda Python Runtime](https://docs.aws.amazon.com/lambda/latest/dg/python-programming-model.html)
- [Bedrock Pricing Calculator](https://aws.amazon.com/bedrock/pricing/)
This code was generated by [Firefly](https://app.gofirefly.io)