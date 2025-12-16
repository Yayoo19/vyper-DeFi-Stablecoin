from src.mocks import MockToken
from vyper import VyperContract

def deploy_collateral() -> VyperContract:
    return MockToken.deploy()

def moccasin_main():
    return deploy_collateral