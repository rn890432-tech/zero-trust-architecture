pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'pip install -r requirements.txt'
                sh 'pip install uvicorn fastapi pydantic slowapi pyjwt'
            }
        }
        stage('Test') {
            steps {
                sh 'pytest tests/'
            }
        }
    }
    post {
        failure {
            environment {
                SES_REGION = credentials('SES_REGION')
                NOTIFY_EMAIL = credentials('NOTIFY_EMAIL')
                AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
                AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
            }
            steps {
                sh '''
                pip install boto3
                python -c """
import boto3, os
ses = boto3.client('ses', region_name=os.getenv('SES_REGION'),
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'))
ses.send_email(
    Source=os.getenv('NOTIFY_EMAIL'),
    Destination={'ToAddresses': [os.getenv('NOTIFY_EMAIL')]},
    Message={
        'Subject': {'Data': f'CI/CD Pipeline Failed for Jenkins Job'},
        'Body': {'Text': {'Data': f'The Jenkins pipeline failed. See details in Jenkins.'}}
    }
)
"""
                '''
            }
        }
    }
}
