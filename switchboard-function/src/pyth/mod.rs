use base64;
pub use switchboard_utils::reqwest;
use ethers::types::Bytes;
use ethers::abi::Address;
use ethers::types::U256;
use ethers::prelude::*;
 use rand::thread_rng;

type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;


static ARBITRUM_TESTNET_URL: &str = "https://goerli-rollup.arbitrum.io/rpc";
    // https://docs.pyth.network/documentation/pythnet-price-feeds/evm#networks
static PYTH_ADDRESS_ARBITRUM_TESTNET: &str = "0x939C0e902FF5B3F7BA666Cc8F6aC75EE76d3f900";
abigen!(PythContract, r#"[ function getUpdateFee(bytes[]) view returns (uint256) ]"#,);

pub fn b64_to_hex(input: &str) -> Result<String> {
    let decoded_bytes = base64::decode(input)?;

    // Convert bytes to hexadecimal string
    let hex_string: String = decoded_bytes.iter()
        .map(|b| format!("{:02x}", b))
        .collect();

    // Prepend 0x
    Ok(format!("0x{}", hex_string))
}

pub async fn fetch_testnet_vaas(addresses: Vec<&str>) -> Result<Vec<Bytes>> {
    let addresses = addresses.join("&ids[]=");
    let pyth_vaas: Vec<Bytes> = reqwest::get(format!("https://xc-testnet.pyth.network/api/latest_vaas?ids[]={}", addresses))
        .await?.json::<Vec<String>>().await?.iter().map(|x| base64::decode(x).unwrap().into()).collect();
    Ok(pyth_vaas)
}

pub async fn fetch_fee_for_vaas(vaas: &Vec<Bytes>) -> Result<U256> {
    let provider = Provider::<Http>::try_from(ARBITRUM_TESTNET_URL)?;
    let wallet = LocalWallet::new(&mut thread_rng());
    let client = SignerMiddleware::new_with_provider_chain(provider, wallet).await?;
    let pyth_address: Address = PYTH_ADDRESS_ARBITRUM_TESTNET.parse()?;
    let pyth_contract = PythContract::new(pyth_address, client.into());
    let fee = pyth_contract.get_update_fee(vaas.clone()).call().await?;
    Ok(fee)
}
