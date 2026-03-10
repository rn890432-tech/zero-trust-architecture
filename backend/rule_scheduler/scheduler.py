import time
import threading

def schedule_rule(rule_func, interval, events):
    def run():
        while True:
            alert = rule_func(events)
            if alert:
                print(alert)
            time.sleep(interval)
    t = threading.Thread(target=run)
    t.start()
