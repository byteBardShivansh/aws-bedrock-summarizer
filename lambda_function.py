import json
import boto3
import os
import logging
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize Bedrock client
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

def lambda_handler(event, context):
    """
    AWS Lambda handler function that invokes Meta Llama3 8B model via Bedrock
    
    Expected event structure:
    {
        "prompt": "Your question or prompt here",
        "max_tokens": 512,
        "temperature": 0.7,
        "top_p": 0.9
    }
    """
    
    try:
        # Parse the event
        if isinstance(event, str):
            event = json.loads(event)
        
        # Extract parameters from event
        prompt = event.get('prompt', 'Hello, how are you?')
        max_tokens = event.get('max_tokens', 512)
        temperature = event.get('temperature', 0.7)
        top_p = event.get('top_p', 0.9)
        
        logger.info(f"Processing request with prompt: {prompt[:100]}...")
        
        # Prepare the request body for Llama3
        request_body = {
            "prompt": prompt,
            "max_gen_len": max_tokens,
            "temperature": temperature,
            "top_p": top_p
        }
        
        # Get model ID from environment variable
        model_id = os.environ.get('MODEL_ID', 'meta.llama3-8b-instruct-v1:0')
        
        # Invoke the Bedrock model
        response = bedrock_runtime.invoke_model(
            modelId=model_id,
            body=json.dumps(request_body),
            contentType='application/json',
            accept='application/json'
        )
        
        # Parse the response
        response_body = json.loads(response['body'].read())
        
        # Extract the generated text
        generated_text = response_body.get('generation', '')
        
        logger.info("Successfully generated response")
        
        # Return successful response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'success': True,
                'generated_text': generated_text,
                'model_id': model_id,
                'input_prompt': prompt,
                'parameters': {
                    'max_tokens': max_tokens,
                    'temperature': temperature,
                    'top_p': top_p
                }
            })
        }
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        
        logger.error(f"AWS Client Error: {error_code} - {error_message}")
        
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': f"AWS Error: {error_code}",
                'message': error_message
            })
        }
        
    except json.JSONDecodeError as e:
        logger.error(f"JSON parsing error: {str(e)}")
        
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': 'Invalid JSON format',
                'message': str(e)
            })
        }
        
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': 'Internal server error',
                'message': str(e)
            })
        }

def test_local():
    """
    Function for local testing
    """
    test_event = {
        "prompt": "Explain what AWS Bedrock is in simple terms.",
        "max_tokens": 200,
        "temperature": 0.7,
        "top_p": 0.9
    }
    
    # Mock context for local testing
    class MockContext:
        def __init__(self):
            self.function_name = "test-function"
            self.memory_limit_in_mb = 256
            self.invoked_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:test-function"
            self.aws_request_id = "test-request-id"
    
    result = lambda_handler(test_event, MockContext())
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    test_local()