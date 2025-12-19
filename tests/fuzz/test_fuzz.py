from hypothesis.stateful import RuleBasedStateMachine, initialize, rule, invariant
from script.deploy_dsc import deploy_dsc
from script.deploy_dsc_engine import deploy_dsc_engine
from moccasin.config import get_active_network
from eth.constants import ZERO_ADDRESS
from boa.util.abi import Address
import boa
from hypothesis import strategies as st, assume
from boa.test.strategies import strategy
from eth_utils import to_wei

USERS_SIZE = 10
MAX_DEPOSIT_SIZE = to_wei(1000, "ether")

class StablecoinFuzzer(RuleBasedStateMachine):
    def __init__(self):
        super().__init__()

    @initialize()
    def setup(self):
        self.dsc = deploy_dsc()
        self.dsc_engine = deploy_dsc_engine(self.dsc)

        active_network = get_active_network()
        self.weth = active_network.manifest_named("weth")
        self.wbtc = active_network.manifest_named("wbtc")
        self.eth_usd_price_feed = active_network.manifest_named("eth_usd_price_feed")
        self.btc_usd_price_feed = active_network.manifest_named("btc_usd_price_feed")

        self.users = [Address("0x" + ZERO_ADDRESS.hex())]
        while Address("0x" + ZERO_ADDRESS.hex()) in self.users:
            self.users = [boa.env.generate_address() for _ in range(USERS_SIZE)]
    
    @rule(
        collateral_seed =st.integers(min_value=0, max_value=1),
        user_seed=st.integers(min_value=0, max_value=USERS_SIZE-1),
        amount=strategy("uint256", min_value=1, max_value=MAX_DEPOSIT_SIZE)
    )
    def mint_and_deposit_collateral(self, collateral_seed, user_seed, amount):
        collateral = self._get_collateral_from_seed(collateral_seed)
        user = self.users[user_seed]
        with boa.env.prank(user):
            collateral.mint_amount(amount)
            collateral.approve(self.dsc_engine.address, amount)
            self.dsc_engine.deposit_collateral(collateral, amount)

    @rule(
        collateral_seed =st.integers(min_value=0, max_value=1),
        user_seed=st.integers(min_value=0, max_value=USERS_SIZE-1),
        percentage=st.integers(min_value=1, max_value=100),
    )
    def redeem_collateral(self, collateral_seed, user_seed, percentage):
        user = self.users[user_seed]
        collateral = self._get_collateral_from_seed(collateral_seed)
        max_reedemable = self.dsc_engine.get_collateral_balance_of_user(user, collateral)
        to_redeem = (max_reedemable * percentage) // 100
        assume(to_redeem > 0)
        with boa.env.prank(user):
            self.dsc_engine.redeem_collateral(collateral, to_redeem)

    @invariant()
    def protocol_must_be_healthy(self):
        total_supply = self.dsc.totalSupply()
        weth_deposited = self.weth.balanceOf(self.dsc_engine.address)
        wbtc_deposited = self.wbtc.balanceOf(self.dsc_engine.address)

        weth_value = self.dsc_engine.get_usd_value(self.weth, weth_deposited)
        wbtc_value = self.dsc_engine.get_usd_value(self.wbtc, wbtc_deposited)

        assert weth_value + wbtc_value >= total_supply

    def _get_collateral_from_seed(self, seed):
        if seed == 0:
            return self.weth
        elif seed == 1:
            return self.wbtc

stablecoin_fuzzer = StablecoinFuzzer.TestCase