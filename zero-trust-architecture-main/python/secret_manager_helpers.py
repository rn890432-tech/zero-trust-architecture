from google.cloud import secretmanager

PROJECT_ID = "your-gcp-project-id"  # Set your GCP project ID

def get_secret(name):
    client = secretmanager.SecretManagerServiceClient()
    path = f"projects/{PROJECT_ID}/secrets/{name}/versions/latest"
    response = client.access_secret_version(request={"name": path})
    return response.payload.data.decode("UTF-8")
