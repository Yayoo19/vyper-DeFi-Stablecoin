from src.mocks import mock_token
from moccasin.boa_tools import VyperContract

def deploy_collateral() -> VyperContract:
    print("Deploying token...")
    mock_token_contract = mock_token.deploy()
    print(f"Deployed Mock Token contract at {mock_token_contract.address}")
    return mock_token_contract

def moccasin_main():
    return deploy_collateral()