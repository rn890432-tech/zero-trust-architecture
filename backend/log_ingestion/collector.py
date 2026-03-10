import json
import psycopg2

def ingest_event(event):
    conn = psycopg2.connect("dbname=soc")
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO security_events
        (timestamp,event_type,source_ip,destination_ip,severity,raw_event)
        VALUES (%s,%s,%s,%s,%s,%s)
        """,
        (
            event["timestamp"],
            event["type"],
            event["source_ip"],
            event["destination_ip"],
            event["severity"],
            json.dumps(event)
        )
    )
    conn.commit()
