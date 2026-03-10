import boto3, os
ses = boto3.client('ses', region_name=os.getenv('SES_REGION'))
if os.getenv('CI_JOB_STATUS') != 'success':
    ses.send_email(
        Source=os.getenv('NOTIFY_EMAIL'),
        Destination={'ToAddresses': [os.getenv('NOTIFY_EMAIL')]},
        Message={
            'Subject': {'Data': f'CI/CD Pipeline Failed for {os.getenv("CI_PROJECT_NAME")}'},
            'Body': {'Text': {'Data': f'The CI/CD pipeline for {os.getenv("CI_PROJECT_NAME")} failed. See details: {os.getenv("CI_PIPELINE_URL")}'}}
        }
    )
