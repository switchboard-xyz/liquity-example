

use rust_decimal::Decimal;
use serde::Deserialize;
use std::collections::HashMap;
pub use switchboard_utils::reqwest;

#[derive(Debug, Deserialize)]
pub struct KrakenTickerResponse {
    pub result: HashMap<String, KrakenTickerInfo>,
}

// https://api.kraken.com/0/public/Ticker
// https://docs.kraken.com/rest/#tag/Market-Data/operation/getTickerInformation
#[derive(Debug, Deserialize, Clone)]
pub struct KrakenTickerInfo {
    #[serde(rename = "a")]
    pub ask: Vec<Decimal>,
    #[serde(rename = "b")]
    pub bid: Vec<Decimal>,
    #[serde(rename = "c")]
    pub close: Vec<Decimal>,
    #[serde(rename = "v")]
    pub volume: Vec<Decimal>,
    #[serde(rename = "p")]
    pub vwap: Vec<Decimal>,
    #[serde(rename = "t")]
    pub trade_count: Vec<i64>,
    #[serde(rename = "l")]
    pub low: Vec<Decimal>,
    #[serde(rename = "h")]
    pub high: Vec<Decimal>,
    #[serde(rename = "o")]
    pub open: Decimal,
}

impl KrakenTickerInfo {
    pub fn price(&self) -> Decimal {
        (self.ask[0] + self.bid[0]) / Decimal::from(2)
    }
}
