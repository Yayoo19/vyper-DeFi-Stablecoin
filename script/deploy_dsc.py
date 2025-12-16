from src import decentralized_stablecoin
from moccasin.boa_tools import VyperContract

def deploy_dsc() -> VyperContract:
    print("Deploying Decentralized Stablecoin")
    return decentralized_stablecoin.deploy()


def moccasin_main() -> VyperContract:
    return deploy_dsc()
