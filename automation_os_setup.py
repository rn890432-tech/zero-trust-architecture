import os
import platform
from datetime import datetime

# Configuration
LOG_DIR = os.path.join(os.getcwd(), 'automation', 'logs')
REPORT_DIR = os.path.join(os.getcwd(), 'automation', 'reports')
RECIPIENTS = ['jasonnorman66994@gmail.com', 'another@email.com', 'third@email.com']  # Add more as needed

# OS Detection
OS_TYPE = platform.system()
print(f"Detected OS: {OS_TYPE}")

# Directory Setup
for directory in [LOG_DIR, REPORT_DIR]:
    if not os.path.exists(directory):
        os.makedirs(directory)
        print(f"Created directory: {directory}")
    else:
        print(f"Directory exists: {directory}")

# Log Format Example
log_entry = f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} [INFO] Initial setup complete."
log_file = os.path.join(LOG_DIR, 'automation.log')
with open(log_file, 'a') as f:
    f.write(log_entry + '\n')
print(f"Log entry written: {log_entry}")

# Recipients
print(f"Notification recipients: {', '.join(RECIPIENTS)}")
