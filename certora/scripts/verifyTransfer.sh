#!/bin/bash

set -euxo pipefail

make -C certora munged

certoraRun \
    certora/harness/TransferHarness.sol \
    certora/dispatch/ERC20Standard.sol \
    certora/dispatch/ERC20USDT.sol \
    certora/dispatch/ERC20NoRevert.sol \
    --verify TransferHarness:certora/specs/Transfer.spec \
    --loop_iter 3 \
    --optimistic_loop \
    --msg "Morpho Blue Transfer" \
    "$@"
