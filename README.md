# vyper-DeFi-Stablecoin

## Introduction

This repository contains the smart contracts for the Vyper implementation of the stablecoin DeFi project.


## What this project does

1. Users can deposit $200 ETH
2. They can mint $50 of Stablecoin
   - They will have a 4/1 ratio of collateral to stablecoin
   - We will set a required collateral ratio of 2/1
3. If the price of ETH drops, other should be able to liquidate those users
