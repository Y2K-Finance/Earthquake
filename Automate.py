import time
from datetime import datetime

import os
from decouple import config

rpc = config("ARBITRUM_RPC_URL")
pk = config("PRIVATE_KEY")
cmd = "forge script DeployScript --rpc-url %s --private-key %s --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv" %(rpc, pk)

def action():
    print("Running action")
    os.system(cmd)

now = datetime.now()


def checkIfMidnight():
    now = datetime.now()
    strike_time = now.replace(hour=0, minute=0)
    print("Current time: ", now)
    print("Strike time: ", strike_time)
    return strike_time == now

while True:
    if checkIfMidnight():
        action()
        break