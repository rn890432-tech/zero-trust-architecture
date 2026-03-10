import importlib
import os

RULES_DIR = os.path.join(os.path.dirname(__file__), '../detection_rules')


def load_rules():
    rules = []
    for fname in os.listdir(RULES_DIR):
        if fname.endswith('_rule.py'):
            mod_name = f"backend.detection_rules.{fname[:-3]}"
            mod = importlib.import_module(mod_name)
            rules.append(mod)
    return rules


def run_detection(events):
    alerts = []
    for rule in load_rules():
        for attr in dir(rule):
            if attr.startswith('detect_'):
                func = getattr(rule, attr)
                alerts.extend(func(events))
    return alerts
