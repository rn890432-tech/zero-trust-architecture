# generate_google_slides.py
# Auto-generates Google Slides from .pptx.txt using Google Slides API

from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
import pickle
import os

SCOPES = ['https://www.googleapis.com/auth/presentations']
INPUT_FILE = 'Release_Playbook_v1.0.pptx.txt'

creds = None
if os.path.exists('token.pickle'):
    with open('token.pickle', 'rb') as token:
        creds = pickle.load(token)
if not creds or not creds.valid:
    if creds and creds.expired and creds.refresh_token:
        creds.refresh(Request())
    else:
        flow = InstalledAppFlow.from_client_secrets_file('credentials.json', SCOPES)
        creds = flow.run_local_server(port=0)
    with open('token.pickle', 'wb') as token:
        pickle.dump(creds, token)

service = build('slides', 'v1', credentials=creds)

presentation = service.presentations().create(body={
    'title': 'Release Playbook v1.0'
}).execute()
presentation_id = presentation['presentationId']

with open(INPUT_FILE, 'r', encoding='utf-8') as f:
    lines = f.readlines()

slide_title = None
slide_content = []
requests = []
for line in lines:
    if line.startswith('Slide'):
        if slide_title:
            requests.append({
                'createSlide': {
                    'slideLayoutReference': {'predefinedLayout': 'TITLE_AND_BODY'}
                }
            })
            # Note: You must update objectId for each slide after creation
        slide_title = None
        slide_content = []
        continue
    if '-' in line and not slide_title:
        slide_title = line.replace('-', '').strip()
    elif slide_title:
        slide_content.append(line.strip())

# Add last slide
if slide_title:
    requests.append({
        'createSlide': {
            'slideLayoutReference': {'predefinedLayout': 'TITLE_AND_BODY'}
        }
    })

# Batch update (objectId handling must be customized per slide)
service.presentations().batchUpdate(
    presentationId=presentation_id,
    body={'requests': requests}
).execute()
print(f"Google Slides created: https://docs.google.com/presentation/d/{presentation_id}")
