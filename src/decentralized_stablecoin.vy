# pragma version 0.4.3
# SPDX-License-Identifier: MIT
# @Author: Yayoo19
# @title: Decentralized Stablecoin
# @dev: This contract is a decentralized stablecoin

from snekmate.tokens import erc20
from snekmate.auth import ownable as ow
from interfaces import i_decentralized_stablecoin

implements: i_decentralized_stablecoin
initializes: ow
initializes: erc20[ownable:= ow]


# ------------------------------------------------------------------
#                             EXPORTS
# ------------------------------------------------------------------
exports: (
    erc20.IERC20,
    erc20.burn_from,
    erc20.mint,
    erc20.set_minter,
    ow.owner,
    ow.transfer_ownership


)

# ------------------------------------------------------------------
#                        CONSTANT VARIABLES
# ------------------------------------------------------------------
NAME: constant(String[25]) = "Decentralized Stablecoin"
SYMBOL: constant(String[5]) = "DSC"
DECIMALS: constant(uint8) = 18
EIP712_VERSION: constant(String[20]) = "1"

# ------------------------------------------------------------------
#                            FUNCTIONS
# ------------------------------------------------------------------
@deploy
def __init__():
    ow.__init__()
    erc20.__init__(NAME, SYMBOL, DECIMALS, NAME, EIP712_VERSION)
    