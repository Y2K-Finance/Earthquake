import time
from datetime import datetime   
import pytz

import os
from decouple import config

rpc = config("ARBITRUM_RPC_URL")
pk = config("PRIVATE_KEY")
cmd = "forge script DeployScript --rpc-url %s --private-key %s --broadcast --skip-simulation --gas-estimate-multiplier 200 --slow -vv " %(rpc, pk)

def action():
    print("Running action")
    os.system(cmd)

now = datetime.now()


def checkIfMidnight():
    now = datetime.now(pytz.utc).timestamp()
    strike = datetime.now(pytz.utc).replace(hour=23, minute=59, second=00).timestamp()
    print(now)
    print(strike)
    if now > strike:
        return True
    else:
        return False



while True:
    time.sleep(2)
    if checkIfMidnight():
        action()
        break
   
