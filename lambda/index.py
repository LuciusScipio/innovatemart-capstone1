import json

def handler(event, context):
    for record in event.get('Records', []):
        s3_info = record.get('s3', {})
        bucket_name = s3_info.get('bucket', {}).get('name')
        file_key = s3_info.get('object', {}).get('key')
        print(f"Image received: {file_key} from bucket {bucket_name}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete')
    }