# generate_mission_control_deck.py
# Creates a branded Google Slides deck with custom layout, fonts, colors, and inserts a live chart from Google Sheets.

import os
import pickle
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request

SCOPES = ['https://www.googleapis.com/auth/presentations', 'https://www.googleapis.com/auth/drive', 'https://www.googleapis.com/auth/spreadsheets.readonly']
CREDENTIALS_FILE = 'credentials.json'
INPUT_FILE = 'Release_Playbook_v1.0.pptx.txt'  # Or your slide spec
SPREADSHEET_ID = 'your_spreadsheet_id_here'  # Update with your sheet ID
CHART_ID = 123456789  # Update with your chart ID

creds = None
if os.path.exists('token.pickle'):
    with open('token.pickle', 'rb') as token:
        creds = pickle.load(token)
if not creds or not creds.valid:
    if creds and creds.expired and creds.refresh_token:
        creds.refresh(Request())
    else:
        flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
        creds = flow.run_local_server(port=0)
    with open('token.pickle', 'wb') as token:
        pickle.dump(creds, token)

slides_service = build('slides', 'v1', credentials=creds)

presentation = slides_service.presentations().create(body={
    'title': 'Mission Control Deck'
}).execute()
presentation_id = presentation['presentationId']

# Customization
TITLE_FONT = 'Arial'
TITLE_SIZE = 32
TITLE_COLOR = '#1a237e'  # Deep blue
BODY_FONT = 'Roboto'
BODY_SIZE = 18
BG_COLOR = '#f5f5f5'  # Light gray

# Create slides
requests = []

# Example: Title slide
requests.append({
    'createSlide': {
        'slideLayoutReference': {'predefinedLayout': 'TITLE'},
        'objectId': 'slide_title'
    }
})
requests.append({
    'insertText': {
        'objectId': 'slide_title',
        'text': 'Mission Control Deck',
        'insertionIndex': 0
    }
})
# Example: Custom background color
requests.append({
    'updatePageProperties': {
        'objectId': 'slide_title',
        'pageProperties': {
            'backgroundFill': {
                'solidFill': {
                    'color': {'rgbColor': {'red': 0.96, 'green': 0.96, 'blue': 0.96}},
                    'alpha': 1
                }
            }
        },
        'fields': 'backgroundFill.solidFill.color'
    }
})
# Example: Insert Sheets chart
requests.append({
    'createSheetsChart': {
        'objectId': 'slide_title_chart',
        'spreadsheetId': SPREADSHEET_ID,
        'chartId': CHART_ID,
        'linkingMode': 'LINKED',
        'elementProperties': {
            'pageObjectId': 'slide_title',
            'transform': {
                'scaleX': 1,
                'scaleY': 1,
                'translateX': 60,
                'translateY': 200,
                'unit': 'PT'
            }
        }
    }
})

# Add more slides as needed (see your SlideSpec)

slides_service.presentations().batchUpdate(
    presentationId=presentation_id,
    body={'requests': requests}
).execute()

print(f"Google Slides created: https://docs.google.com/presentation/d/{presentation_id}/edit")
