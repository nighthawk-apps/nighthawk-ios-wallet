//! Background `scan_blocks` + `blockchain.subscribe_blocks` loop (upstream `bin/app/src/plugin/drk.rs`).

use std::sync::Arc;

use darkfi::system::{sleep, StoppableTask};
use drk::rpc::subscribe_blocks;
use smol::channel::unbounded;
use smol::Executor;
use url::Url;

use crate::DrkPtr;

/// Matches upstream `DARKFID_RETRY_TIME` in `bin/app/src/plugin/drk.rs`.
const DARKFID_RETRY_SECS: u64 = 20;

/// Detached thread: initial scan, subscribe to new blocks, retry on disconnect.
pub fn start_background_sync(drk: DrkPtr, endpoint: Url, ex: Arc<Executor<'static>>) {
    std::thread::Builder::new()
        .name("darkfi-wallet-sync".into())
        .spawn(move || {
            smol::block_on(async move {
                loop {
                    let rpc_task = StoppableTask::new();
                    let (shell_sender, _shell_receiver) = unbounded();
                    let _ = subscribe_blocks(
                        &drk,
                        rpc_task,
                        shell_sender,
                        endpoint.clone(),
                        &ex,
                    )
                    .await;
                    sleep(DARKFID_RETRY_SECS).await;
                }
            })
        })
        .ok();
}
