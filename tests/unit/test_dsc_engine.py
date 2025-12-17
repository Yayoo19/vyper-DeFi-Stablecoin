from src import dsc_engine
from eth.codecs.abi.exceptions import EncodeError
import pytest
from tests.conftest import COLLATERAL_AMOUNT
import boa
from eth_utils import to_wei

def test_reverts_if_token_lenghts_are_different(dsc, eth_usd_price_feed, btc_usd_price_feed, weth, wbtc):
    with pytest.raises(EncodeError):
        dsc_engine.deploy([wbtc, weth, weth], [eth_usd_price_feed, btc_usd_price_feed], dsc.address)

# ------------------------------------------------------------------
#                        DEPOSIT COLLATERAL
# ------------------------------------------------------------------
def test_reverts_if_collateral_amount_is_zero(dsc_engine, weth, user):
    with boa.env.prank(user):
        weth.approve(dsc_engine.address, COLLATERAL_AMOUNT )
        with boa.reverts():
            dsc_engine.deposit_collateral(weth.address, 0)

# ------------------------------------------------------------------
#                          PRICE TESTS
# ------------------------------------------------------------------
def test_get_token_amount_from_usd(dsc_engine, weth):
    expected_weth = to_wei(0.05, "ether")
    actual_weth = dsc_engine.get_token_amount_from_usd(weth, to_wei(100, "ether"))
    assert expected_weth == actual_weth


def test_get_usd_value(dsc_engine, weth):
    eth_amount = to_wei(15, "ether")
    expected_usd = to_wei(30_000, "ether")
    actual_usd = dsc_engine.get_usd_value(weth, eth_amount)
    assert expected_usd == actual_usd

# ------------------------------------------------------------------
#                       DEPOSITCOLLATERAL
# ------------------------------------------------------------------
def test_reverts_if_collateral_zero(user, weth, dsc_engine):
    with boa.env.prank(user):
        weth.approve(dsc_engine, COLLATERAL_AMOUNT)
        with boa.reverts():
            dsc_engine.deposit_collateral(weth, 0)