
## Requirements
 - Go 1.14



```bash
# STEP-1

# Install tools (golangci-lint v1.18)
make tools-clean
make tools

# Install the app into your $GOBIN
make install

# Now you should be able to run the following commands, confirming the build is successful:
fbd help
fbcli help
fbrelayer help
```

## Running and testing the application

First, initialize a chain and create accounts to test sending of a random token.

```bash
# Initialize the genesis.json file that will help you to bootstrap the network
fbd init local --chain-id=fbchain

# Create a key to hold your validator account and for another test account
fbcli keys add validator
# Enter password

fbcli keys add testuser
# Enter password

# Edit the genesis.json file for customised stake denom
--> on terminal go to folder ~/.fbd/config/genesis.json
--> Edit the staking section having bond_denom key from "stake" to "fbx"
--> Save and close the file.


# Initialize the genesis account and transaction
fbd add-genesis-account $(fbcli keys show validator -a) 1000000000fbx,1000000000fbc

# Create genesis transaction
fbd gentx --name validator --amount 1000000fbx
# Enter password

# Collect genesis transaction
fbd collect-gentxs





# STEP-2

```

## Running the bridge locally

### Set-up

```bash
cd testnet-contracts/

# Create .env with sample environment variables
cp .env.example .env
```

For running the bridge locally, you'll only need the `LOCAL_PROVIDER` environment variables.

### Terminal 1: Start local blockchain

```bash
# Download dependencies
yarn

# Start local blockchain
yarn develop
```

### Terminal 2: Compile and deploy Peggy contract

```bash
# Deploy contract to local blockchain
yarn migrate

# Copy contract ABI to go modules:
yarn peggy:abi

# Get contract's address
yarn peggy:address
```

### Terminal 3: Build and start Ethereum Bridge

```bash
# Now its safe to start `fbd`
fbd start

# Then, wait 10 seconds and in another terminal window, test things are ok by sending 10 tok tokens from the validator to the testuser
fbcli tx send validator $(fbcli keys show testuser -a) 10fbx --chain-id=fbchain --yes

# Wait a few seconds for confirmation, then confirm token balances have changed appropriately
fbcli query account $(fbcli keys show validator -a) --trust-node
fbcli query account $(fbcli keys show testuser -a) --trust-node
```

### Terminal 4: Start the Relayer service

For automated relaying, there is a relayer service that can be run that will automatically watch and relay events (local web socket and deployed address parameters may vary).

```bash
# Check fbrelayer connection to ebd
fbrelayer status

# Start ebrelayer on the contract's deployed address with [LOCAL_WEB_SOCKET] and [PEGGY_DEPLOYED_ADDRESS]
# Example [LOCAL_WEB_SOCKET]: ws://127.0.0.1:7545/
# Example [PEGGY_DEPLOYED_ADDRESS]: 0xC4cE93a5699c68241fc2fB503Fb0f21724A624BB

fbrelayer init [LOCAL_WEB_SOCKET] [PEGGY_DEPLOYED_ADDRESS] LogLock\(bytes32,address,bytes,address,string,uint256,uint256\) validator --chain-id=fbchain

# Enter password and press enter
# You should see a message like: Started ethereum websocket with provider: [LOCAL_WEB_SOCKET] \ Subscribed to contract events on address: [PEGGY_DEPLOYED_ADDRESS]

# The relayer will now watch the contract on Ropsten and create a claim whenever it detects a lock event.
```

### Using Terminal 2: Send lock transaction to contract

```bash
# Default parameter values:
# [HASHED_FBCHAIN_RECIPIENT_ADDRESS] = 0x636f736d6f7331706a74677530766175326d35326e72796b64707a74727438383761796b756530687137646668  //USE STRING TO BASE64 CONVERTER  ONLINE TO GET HASHED ADDRESS FO TESTUSER
# [TOKEN_CONTRACT_ADDRESS] = 0x0000000000000000000000000000000000000000
# [WEI_AMOUNT] = 10

# Send lock transaction with default parameters
yarn peggy:lock --default

# Send lock transaction with custom parameters
yarn peggy:lock [HASHED_FBCHAIN_RECIPIENT_ADDRESS] [TOKEN_CONTRACT_ADDRESS] [WEI_AMOUNT]

```

`yarn peggy:lock --default` expected output in fbrelayer console:

```bash
New Lock Transaction:
Tx hash: 0x83e6ee88c20178616e68fee2477d21e84f16dcf6bac892b18b52c000345864c0
Block number: 5
Event ID: cc10955295e555130c865949fb1fd48dba592d607ae582b43a2f3f0addce83f2
Token: 0x0000000000000000000000000000000000000000
Sender: 0xc230f38FF05860753840e0d7cbC66128ad308B67
Recipient: cosmos1pjtgu0vau2m52nrykdpztrt887aykue0hq7dfh
Value: 10
Nonce: 1

Response:
Height: 48
TxHash: AD842C51B4347F0F610CB524529C2D8A875DACF12C8FE4B308931D266FEAD067
Logs: [{"msg_index":0,"success":true,"log":"success"}]
GasWanted: 200000
GasUsed: 42112
Tags: - action = create_bridge_claim
```
# Confirm that the prophecy was successfully processed and that new eth was minted to the testuser address
fbcli query account $(fbcli keys show testuser -a) --trust-node

# Test out burning the eth for the return trip
fbcli tx ethbridge burn $(fbcli keys show testuser -a) 0x7B95B6EC7EbD73572298cEf32Bb54FA408207359 1eth --from=testuser --chain-id=fbchain --yes

## Running the bridge on the Ropsten testnet

To run the Ethereum Bridge on the Ropsten testnet, repeat the steps for running locally with the following changes:

```bash
# Add environment variable MNEMONIC from your MetaMask account

# Add environment variable INFURA_PROJECT_ID from your Infura account.

# Specify the Ropsten network via a --network flag for the following commands...

yarn migrate --network ropsten
yarn peggy:address --network ropsten

# Make sure to start ebrelayer with Ropsten network websocket
fbrelayer init wss://ropsten.infura.io/ws [PEGGY_DEPLOYED_ADDRESS] LogLock\(bytes32,address,bytes,address,string,uint256,uint256\) validator --chain-id=fbchain

# Send lock transaction on Ropsten testnet

yarn peggy:lock --network ropsten [HASHED_FBCHAIN_RECIPIENT_ADDRESS] [TOKEN_CONTRACT_ADDRESS] [WEI_AMOUNT]

```

## Testing ERC20 token support

The bridge supports the transfer of ERC20 token assets. A sample TEST token is deployed upon migration and can be used to locally test the feature.

### Local

```bash
# Mint 1,000 TEST tokens to your account for local use
yarn token:mint

# Approve 100 TEST tokens to the Bridge contract
yarn token:approve --default

# You can also approve a custom amount of TEST tokens to the Bridge contract:
yarn token:approve 3

# Get deployed TEST token contract address
yarn token:address

# Lock TEST tokens on the Bridge contract
yarn peggy:lock [HASHED_COSMOS_RECIPIENT_ADDRESS] [TEST_TOKEN_CONTRACT_ADDRESS] [TOKEN_AMOUNT]

```

`yarn peggy:lock` ERC20 expected output in ebrelayer console (with a TOKEN_AMOUNT of 3):

```bash
New Lock Transaction:
Tx hash: 0xce7b219427c613c8927f7cafe123af4145016a490cd9fef6e3796d468f72e09f
Event ID: bb1c4798aaf4a1236f4f0235495f54a135733446f6c401c1bb86b690f3f35e60
Token Symbol: TEST
Token Address: 0x5040BA3Cf968de7273201d7C119bB8D8F03BDcBc
Sender: 0xc230f38FF05860753840e0d7cbC66128ad308B67
Recipient: cosmos1pjtgu0vau2m52nrykdpztrt887aykue0hq7dfh
Value: 3
Nonce: 2

Response:
  height: 0
  txhash: DF1F55D2B8F4277671772D9A72188D0E4E15097AD28272E31116FF4B5D832B08
  code: 0
  data: ""
  rawlog: '[{"msg_index":0,"success":true,"log":""}]'
  logs:
  - msgindex: 0
    success: true
    log: ""
```

## Using the modules in other projects

The ethbridge and oracle modules can be used in other cosmos-sdk applications by copying them into your application's modules folders and including them in the same way as in the example application. Each module may be moved to its own repo or integrated into the core Cosmos-SDK in future, for easier usage.

For instructions on building and deploying the smart contracts, see the README in their folder.

fbcli rest-server --trust-node --chain-id=fbchain

fbcli tx staking create-validator \
  --amount=100000000fbx \
  --pubkey=$(fbd tendermint show-validator) \
  --moniker="local" \
  --chain-id=fbchain \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --gas=200000 \
  --gas-prices="0.001fbx" \
  --from=testuser
