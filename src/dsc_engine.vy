# pragma version 0.4.3
# SPDX-License-Identifier: MIT
# @Author: Yayoo19
# @title: Collateralized Stablecoin Engine
# @notice
    # Collateral: Exogenous (WETH, WBTC, etc.)
    # Minting Mecanism: Decentralized (Algorithmic)
    # Value (Relative Stability): Anchored (USD)
    # Collateral type: Crypto
from interfaces import i_decentralized_stablecoin
from ethereum.ercs import IERC20

# ------------------------------------------------------------------
#                        STATE VARIABLES
# ------------------------------------------------------------------
DSC: public(immutable(i_decentralized_stablecoin))
COLLATERAL_TOKENS: public(immutable(address[2]))
token_to_price_feed: public(HashMap[address, address])
user_to_token_to_amount_deposited: public(HashMap[address, HashMap[address, uint256]])

# ------------------------------------------------------------------
#                        EVENTS
# ------------------------------------------------------------------
event CollateralDeposited:
    user: indexed(address)
    amount: indexed(uint256)

# ------------------------------------------------------------------
#                        EXTERNAL FUNCTIONS
# ------------------------------------------------------------------
@deploy
def __init__(token_address: address[2], price_feed_address: address[2], dsc_address: address):
    """
    @notice ETH and BTC are the only supported collaterals
    """
    DSC = i_decentralized_stablecoin(dsc_address)
    COLLATERAL_TOKENS = token_address
    self.token_to_price_feed[token_address[0]] = price_feed_address[0]
    self.token_to_price_feed[token_address[1]] = price_feed_address[1]
    
@external
def deposit_collateral(token_collateral_address: address, amount_collateral: uint256):
    self._deposit_collateral(token_collateral_address, amount_collateral)

# ------------------------------------------------------------------
#                        INTERNAL FUNCTIONS
# ------------------------------------------------------------------

@internal
def _deposit_collateral(token_collateral_address: address, amount_collateral: uint256):
    assert amount_collateral > 0,  "DSC Engine: Amount must be greater than 0"
    assert self.token_to_price_feed[token_collateral_address] != empty(address), "DSC Engine: Invalid collateral address"
    
    self.user_to_token_to_amount_deposited[msg.sender][token_collateral_address] += amount_collateral
    log CollateralDeposited(user=msg.sender, amount=amount_collateral)

    success: bool = extcall IERC20(token_collateral_address).transferFrom(msg.sender, self, amount_collateral)
    assert success, "DSC Engine: Transfer failed"
    
