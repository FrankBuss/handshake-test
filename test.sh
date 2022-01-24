#!/bin/bash

# first install Handshake as described here: https://github.com/handshake-org/hsd
# on Debian Linux it looks like this:

# apt-get install npm libunbound-dev libcap2-bin
# git clone https://github.com/handshake-org/hsd.git
# cd hsd
# npm install -g node-gyp
# npm install --production

# stop any running hsd daemon
killall hsd
sleep 3

# remove old blockchain data
rm -rf ~/.hsd/regtest/

# start server and wait a bit until started
# root nameserver at port 25349, recursive server at port 25350
echo "starting server"
./bin/hsd --network regtest --http-host 0.0.0.0 --api-key=test --listen --max-inbound 50 --rs-host 0.0.0.0 > /dev/null &
sleep 5

# call a RPC method
hsd-rpc() {
    ./node_modules/.bin/hsd-rpc --network regtest --api-key test "$@"
}

# call a RPC wallet method
hsw-rpc() {
    ./node_modules/.bin/hsw-rpc --network regtest --api-key test "$@"
}

# call a wallet method
hsw-cli() {
    ./node_modules/.bin/hsw-cli --network regtest --api-key=test "$@"
}

# mine blocks, argument is number of blocks
mine() {
    for (( c=1; c<=$1; c++ )) ; do hsd-rpc generatetoaddress 1 "$receive" > /dev/null ; done
}

# get a receive address
receive=$(hsw-cli account default | jq -r .receiveAddress)
echo "receive address: $receive"

echo "mining coins"
mine 100

# TLD name
name="metaroot"
echo "name: $name"

# open a bid, and mine one block to add it to the blockchain
hsw-rpc sendopen "$name" > /dev/null
mine 1

# get number of blocks until auction starts and mine them
blocks=$(hsd-rpc getnameinfo "$name" | jq -r .info.stats.blocksUntilBidding)
echo "blocks until auction starts: $blocks"
mine "$blocks"

# create bid
hsw-rpc sendbid "$name" 1 10 > /dev/null
mine 1

# wait until reveal
blocks=$(hsd-rpc getnameinfo "$name" | jq -r .info.stats.blocksUntilReveal)
echo "blocks until auction reveal: $blocks"
mine "$blocks"

# send a reveal tx and mine a block to confirm it
hsw-rpc sendreveal "$name" > /dev/null
mine 1

# mine enough blocks to close the auction
blocks=$(hsd-rpc getnameinfo "$name" | jq -r .info.stats.blocksUntilClose)
echo "blocks until auction close: $blocks"
mine "$blocks"

