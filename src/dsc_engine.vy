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


# ------------------------------------------------------------------
#                        STATE VARIABLES
# ------------------------------------------------------------------
DSC: public(immutable(i_decentralized_stablecoin))
COLLATERAL_TOKENS: public(immutable(address[2]))
token_to_price_feed: public(HashMap[address, address])


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
    


