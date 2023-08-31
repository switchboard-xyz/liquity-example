pub mod pyth;
pub use pyth::*;

use ethers::types::Bytes;
use base64;
use chrono::Utc;
use ethers::{
    prelude::{abigen, SignerMiddleware},
    providers::{Http, Provider},
    types::Address,
};
use rust_decimal::prelude::FromPrimitive;
use rust_decimal::Decimal;
use serde::Deserialize;
use switchboard_evm::sdk::EVMFunctionRunner;
pub use switchboard_utils::reqwest;
use ethers::prelude::Wallet;
use ethers_core::rand::thread_rng;


abigen!(Receiver, r#"[ function callback(address[], bytes[]) ]"#,);
static UNUSED_URL: &str = "https://goerli-rollup.arbitrum.io/rpc";

#[derive(Debug, Deserialize)]
pub struct DeribitRespnseInner {
    pub mark_iv: f64,
    pub timestamp: u64,
}
#[derive(Debug, Deserialize)]
pub struct DeribitResponse {
    pub result: DeribitRespnseInner,
}

#[tokio::main(worker_threads = 12)]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // --- Initialize clients ---
    let function_runner = EVMFunctionRunner::new()?;
    let receiver: Address = env!("EXAMPLE_PROGRAM").parse()?;
    let provider = Provider::<Http>::try_from(UNUSED_URL)?;
    let signer = function_runner.enclave_wallet.clone();
    let client = SignerMiddleware::new_with_provider_chain(provider, signer).await?;
    let receiver_contract = Receiver::new(receiver, client.into());

    // // --- Send the callback to the contract with Switchboard verification ---
    // let callback = receiver_contract.callback(0.into(), 0.into());
    // let expiration = (Utc::now().timestamp() + 120).into();
    // let gas_limit = 5_500_000.into();
    // function_runner.emit(receiver, expiration, gas_limit, vec![callback])?;
    Ok(())
}

/// Run `cargo test -- --nocapture`
#[cfg(test)]
mod tests {
    use crate::*;
    use crate::pyth::*;
    use ethers::prelude::LocalWallet;

    #[tokio::test]
    async fn test() {
        // https://docs.chain.link/data-feeds/price-feeds/addresses/?network=arbitrum
        let chainlink_btc_usd = "0xA39434A63A52E749F02807ae27335515BA4b07F7";
        let chainlink_eth_usd = "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e";
        // https://pyth.network/developers/price-feed-ids#pyth-evm-testnet
        let vaas = pyth::fetch_testnet_vaas(vec![
            "0xf9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b", // BTC/USD
            "0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6", // ETH/USD
        ]).await.unwrap();
        let fee = pyth::fetch_fee_for_vaas(&vaas).await.unwrap();
        println!("{:#?} -- {}", vaas, fee);
    }
}
