import subprocess
import sys
import time

def run_simulator():
    while True:
        subprocess.Popen([sys.executable, 'simulator.py'])
        time.sleep(5)

if __name__ == "__main__":
    run_simulator()
