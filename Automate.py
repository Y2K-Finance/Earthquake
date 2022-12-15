import time
from datetime import datetime

import os
from decouple import config

rpc = config("ARBITRUM_RPC_URL")
cmd = "forge test --fork-url " + rpc

def action():
    print("Running action")
    os.system(cmd)

now = datetime.now()


def checkIfMidnight():
    now = datetime.now()
    strike_time = now.replace(hour=6, minute=30)
    print("Current time: ", now)
    print("Strike time: ", strike_time)
    return strike_time == now

while True:
    if checkIfMidnight():
        action()
        break