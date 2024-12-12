use reqwest::Client;
use sha1::{Digest, Sha1};
use std::{
    collections::VecDeque,
    fs::{self, File},
    io::{self, Write},
    path::Path,
    sync::{Arc, Mutex},
};
use tokio::{
    fs as async_fs,
    io::{AsyncReadExt, AsyncWriteExt},
    sync::{Semaphore, SemaphorePermit},
};

// copy target/release/librust_downloader.so to assets/rust/linux/librust_downloader.so
// add assets/rust/linux/librust_downloader.so to pubspec.yaml

#[derive(Clone)]
pub struct DownloadFile {
    max_concurrent_requests: usize,
    client: Client,
    semaphore: Arc<Semaphore>,
    request_queue: Arc<Mutex<VecDeque<tokio::sync::oneshot::Sender<()>>>>,
}

impl DownloadFile {
    pub fn new(max_concurrent_requests: usize) -> Self {
        Self {
            max_concurrent_requests,
            client: Client::new(),
            semaphore: Arc::new(Semaphore::new(max_concurrent_requests)),
            request_queue: Arc::new(Mutex::new(VecDeque::new())),
        }
    }

    // Wait for an available slot
    async fn wait_for_available_slot(&self) -> SemaphorePermit<'_> {
        self.semaphore.acquire().await.unwrap()
    }

    // Fetch a file from a URL and save it to the specified path
    pub async fn fetch(&self, url: &str, filename: &str) -> io::Result<()> {
        let path = Path::new(filename);

        if path.exists() {
            //println!("[debug][rust] {} exists", filename);
            return Ok(());
        }

        let permit = self.wait_for_available_slot().await;
        println!("[debug][rust] downloader fetch {}", url);

        if let Some(parent) = path.parent() {
            async_fs::create_dir_all(parent).await?;
        }

        println!("[debug][rust] send HTTP request {}", url);
        match self.client.get(url).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    let bytes = response.bytes().await.unwrap();
                    let mut file = async_fs::File::create(filename).await?;
                    file.write_all(&bytes).await?;
                    println!("[debug][rust] Download file is saved: {}", filename);
                    Ok(())
                } else {
                    eprintln!(
                        "[error][rust] Download failed, status = {}",
                        response.status()
                    );
                    Err(io::Error::new(
                        io::ErrorKind::Other,
                        "[error][rust] Download failed with non-200 status",
                    ))
                }
            }
            Err(e) => {
                eprintln!("[exception][rust] {}", e);
                Err(io::Error::new(io::ErrorKind::Other, e))
            }
        }?;

        drop(permit); // Release slot
        Ok(())
    }

    // Check if a file matches the expected size and SHA-1 hash
    pub async fn check_file(
        &self,
        file_path: &str,
        expected_size: u64,
        expected_sha1: &str,
    ) -> io::Result<()> {
        let path = Path::new(file_path);

        if !path.exists() {
            eprintln!("[error][rust] Error: File does not exist.");
            return Ok(());
        }

        let metadata = async_fs::metadata(file_path).await?;
        if metadata.len() != expected_size {
            eprintln!(
                "[error][rust] Error: File size does not match. Expected {} bytes, got {} bytes.",
                expected_size,
                metadata.len()
            );
            return Ok(());
        }

        let computed_sha1 = self.compute_sha1(file_path).await?;
        if computed_sha1 != expected_sha1 {
            eprintln!(
                "[error][rust] Error: SHA1 hash does not match. Expected {}, got {}.",
                expected_sha1, computed_sha1
            );
            return Ok(());
        }

        println!("[debug][rust] File verification succeeded: Size and SHA-1 hash match.");
        Ok(())
    }

    // Compute SHA-1 hash of a file
    pub async fn compute_sha1(&self, file_path: &str) -> io::Result<String> {
        let mut file = async_fs::File::open(file_path).await?;
        let mut hasher = Sha1::new();
        let mut buffer = [0u8; 4096];

        loop {
            let n = file.read(&mut buffer).await?;
            if n == 0 {
                break;
            }
            hasher.update(&buffer[..n]);
        }

        Ok(format!("{:x}", hasher.finalize()))
    }
}
