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
from interfaces import AggregatorV3Interface

# ------------------------------------------------------------------
#                        STATE VARIABLES
# ------------------------------------------------------------------
DSC: public(immutable(i_decentralized_stablecoin))
COLLATERAL_TOKENS: public(immutable(address[2]))
FEED_PRECISION: public(constant(uint256)) = 1 * (10**10)
PRECISION: public(constant(uint256)) = 10 ** 18
LIQUIDATION_THRESHOLD: public(constant(uint256)) = 50
LIQUIDATION_PRECISION: public(constant(uint256)) = 100
MIN_HEALTH_FACTOR: public(constant(uint256)) = 1 * (10**18)
token_to_price_feed: public(HashMap[address, address])
user_to_token_to_amount_deposited: public(HashMap[address, HashMap[address, uint256]])
user_to_dsc_minted: public(HashMap[address, uint256])

# ------------------------------------------------------------------
#                        EVENTS
# ------------------------------------------------------------------

event CollateralDeposited:
    user: indexed(address)
    amount: indexed(uint256)

event CollateralRedeemed:
    token: indexed(address)
    amount: indexed(uint256)
    _from: address
    _to: address
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

@external
def mint_dsc(amount: uint256):
    self._mint_dsc(amount)

@external
def redeem_collateral(token_collateral_address: address, amount_collateral: uint256):
    self._redeem_collateral(token_collateral_address, amount_collateral, msg.sender, msg.sender)
    self._revert_if_health_factor_broken(msg.sender)

# ------------------------------------------------------------------
#                        INTERNAL FUNCTIONS
# ------------------------------------------------------------------

@internal 
def _redeem_collateral(token_collateral_address: address, amount_collateral: uint256, _from:address, to:address):
    self.user_to_token_to_amount_deposited[_from][token_collateral_address] -= amount_collateral
    log CollateralRedeemed(token=token_collateral_address, amount=amount_collateral, _from=_from, _to=to)
    sucess: bool = extcall IERC20(token_collateral_address).transfer(to, amount_collateral)
    assert sucess, "DSC Engine: Transfer failed"

@internal
def _deposit_collateral(token_collateral_address: address, amount_collateral: uint256):
    assert amount_collateral > 0,  "DSC Engine: Amount must be greater than 0"
    assert self.token_to_price_feed[token_collateral_address] != empty(address), "DSC Engine: Invalid collateral address"
    
    self.user_to_token_to_amount_deposited[msg.sender][token_collateral_address] += amount_collateral
    log CollateralDeposited(user=msg.sender, amount=amount_collateral)

    success: bool = extcall IERC20(token_collateral_address).transferFrom(msg.sender, self, amount_collateral)
    assert success, "DSC Engine: Transfer failed"
    
@internal
def _mint_dsc(amount_dsc_to_mint: uint256):
    assert amount_dsc_to_mint > 0,  "DSC Engine: Amount_to_mint must be greater than 0"
    self.user_to_dsc_minted[msg.sender] += amount_dsc_to_mint
    self._revert_if_health_factor_broken(msg.sender)
    extcall DSC.mint(msg.sender, amount_dsc_to_mint)

@internal
def _revert_if_health_factor_broken(user: address):
    user_health_factor: uint256 = self._health_factor(user)
    assert user_health_factor >= MIN_HEALTH_FACTOR, "DSC Engine: User health factor is too low"

    

@internal
def _get_account_information(user: address) -> (uint256, uint256):
    """
    @notice Returns the amount of DSC minted and the amount of collateral deposited
    """
    total_dsc_minted: uint256 = self.user_to_dsc_minted[user]
    collateral_value_usd: uint256 = self._get_account_collateral_value(user)
    return (total_dsc_minted, collateral_value_usd)

@internal
def _get_account_collateral_value(user: address) -> uint256:
    total_collateral_value_in_usd: uint256 = 0
    for token: address in COLLATERAL_TOKENS:
        amount: uint256 = self.user_to_token_to_amount_deposited[user][token]
        total_collateral_value_in_usd += self._get_usd_value(token, amount)
    return total_collateral_value_in_usd

@internal
@view
def _get_usd_value(token: address, amount: uint256) -> uint256:
    price_feed: AggregatorV3Interface = AggregatorV3Interface(self.token_to_price_feed[token])
    price: int256 = staticcall price_feed.latestAnswer()
    return ((convert(price, uint256) * FEED_PRECISION) * amount) // PRECISION
        
@internal
def _health_factor(user:address) -> uint256:
    total_dsc_minted: uint256 = 0
    total_collateral_value_in_usd: uint256 = 0
    total_dsc_minted, total_collateral_value_in_usd = self._get_account_information(user)
    return self._calculate_health_factor(total_dsc_minted, total_collateral_value_in_usd)

@internal
def _calculate_health_factor(total_dsc_minted: uint256, total_collateral_value_in_usd: uint256) -> uint256:
    if total_dsc_minted == 0:
        return max_value(uint256)
    collateral_adjusted_for_threshold: uint256 = (total_collateral_value_in_usd * LIQUIDATION_THRESHOLD) // LIQUIDATION_PRECISION
    return (collateral_adjusted_for_threshold * PRECISION) // total_dsc_minted

