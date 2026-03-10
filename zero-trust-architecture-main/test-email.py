import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Email settings
sender = 'jasonnorman66994@gmail.com'
receiver = 'jasonnorman66994@gmail.com'
subject = 'Archive Signed Test'
body = 'This is a test email from your Zero Trust automation.'
password = 'dlijpyyetrtoxttb'

msg = MIMEMultipart()
msg['From'] = sender
msg['To'] = receiver
msg['Subject'] = subject
msg.attach(MIMEText(body, 'plain'))

try:
    with smtplib.SMTP('smtp.gmail.com', 587) as server:
        server.starttls()
        server.login(sender, password)
        server.sendmail(sender, receiver, msg.as_string())
    print('Email sent successfully!')
except Exception as e:
    print(f'Error sending email: {e}')
