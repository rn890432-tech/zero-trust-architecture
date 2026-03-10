# Release Playbook v1.0 Automation Scripts

## 1. PowerPoint (.pptx) Automation

This script uses `python-pptx` to convert the .txt file into a .pptx presentation.

### Requirements
- Install python-pptx: `pip install python-pptx`

### Script: generate_pptx.py

```python
from pptx import Presentation
import os

INPUT_FILE = 'Release_Playbook_v1.0.pptx.txt'
OUTPUT_FILE = 'Release_Playbook_v1.0.pptx'

prs = Presentation()

with open(INPUT_FILE, 'r', encoding='utf-8') as f:
    lines = f.readlines()

slide_title = None
slide_content = []
for line in lines:
    if line.startswith('Slide'):
        if slide_title:
            slide = prs.slides.add_slide(prs.slide_layouts[1])
            slide.shapes.title.text = slide_title
            slide.placeholders[1].text = '\n'.join(slide_content)
        slide_title = None
        slide_content = []
        continue
    if '-' in line and not slide_title:
        slide_title = line.replace('-', '').strip()
    elif slide_title:
        slide_content.append(line.strip())

# Add last slide
if slide_title:
    slide = prs.slides.add_slide(prs.slide_layouts[1])
    slide.shapes.title.text = slide_title
    slide.placeholders[1].text = '\n'.join(slide_content)

prs.save(OUTPUT_FILE)
print(f"PowerPoint saved as {OUTPUT_FILE}")
```

---

## 2. Google Slides API Automation

This script uses Google Slides API to automate slide creation. You need Google Cloud credentials and enable the Slides API.

### Requirements
- Install Google API client: `pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client`
- Download credentials.json from Google Cloud Console

### Script: generate_google_slides.py

```python
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
            requests.append({
                'insertText': {
                    'objectId': 'title',
                    'text': slide_title
                }
            })
            requests.append({
                'insertText': {
                    'objectId': 'body',
                    'text': '\n'.join(slide_content)
                }
            })
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
    requests.append({
        'insertText': {
            'objectId': 'title',
            'text': slide_title
        }
    })
    requests.append({
        'insertText': {
            'objectId': 'body',
            'text': '\n'.join(slide_content)
        }
    })

service.presentations().batchUpdate(
    presentationId=presentation_id,
    body={'requests': requests}
).execute()
print(f"Google Slides created: https://docs.google.com/presentation/d/{presentation_id}")
```

---

Place these scripts in your workspace, run them, and your .pptx and Google Slides will be generated automatically. Let me know if you want these scripts saved as files now.