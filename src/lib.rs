use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::sync::Mutex;
use tokio::runtime::Runtime;

use lazy_static::lazy_static;
pub mod downloader;
pub use downloader::DownloadFile;
use std::str::Utf8Error;
// .so file is located at target/release/librust_downloader.so
// copy target/release/librust_downloader.so to assets/rust/linux/librust_downloader.so
// add assets/rust/linux/librust_downloader.so to pubspec.yaml

lazy_static::lazy_static! {
    // lazy is similar to 'late'
    // global variable: RUNTIME and it's type is Mutex<Runtime>
    // Mutex<> can keep multi-thread safety
    // Runtime is defined in Tokio for asynchronous task
    pub static ref RUNTIME: Mutex<Runtime> = Mutex::new(Runtime::new().expect("Failed to create Tokio runtime"));
    //static ref C_RUNTIME: Mutex<Runtime> = Mutex::new(Runtime::new().unwrap());
}

#[no_mangle]
pub extern "C" fn create_downloader(max_concurrent_requests: c_int) -> *mut DownloadFile {
    let downloader = Box::new(DownloadFile::new(max_concurrent_requests as usize));
    Box::into_raw(downloader)
}

#[no_mangle]
pub extern "C" fn fetch_file(
    downloader_ptr: *mut DownloadFile,
    url: *const c_char,
    filename: *const c_char,
) {
    let downloader = unsafe {
        assert!(!downloader_ptr.is_null());
        &mut *downloader_ptr
    };

    //let url = unsafe { CStr::from_ptr(url).to_str().unwrap() };
    //let filename = unsafe { CStr::from_ptr(filename).to_str().unwrap() };
    //let url = unsafe { CStr::from_ptr(url).to_str_lossy().into_owned() };
    //let filename = unsafe { CStr::from_ptr(filename).to_str_lossy().into_owned() };
    let url = unsafe {
        CStr::from_ptr(url)
            .to_str()
            .map(String::from) // 转换为 String
            .unwrap_or_else(|_| {
                CStr::from_ptr(url)
                    .to_bytes_with_nul()
                    .iter()
                    .cloned()
                    .map(char::from)
                    .collect()
            })
    };

    let filename = unsafe {
        match CStr::from_ptr(filename).to_str() {
            Ok(s) => s.to_string(),
            Err(_) => String::from_utf8_lossy(CStr::from_ptr(filename).to_bytes()).into_owned(),
        }
    };
    RUNTIME.lock().unwrap().spawn(async move {
        if let Err(err) = downloader.fetch(&url, &filename).await {
            eprintln!(
                "[error][rust] Failed to download file {} from {}: {}",
                filename, url, err
            );
        }
    });
}

#[no_mangle]
pub extern "C" fn free_downloader(downloader_ptr: *mut DownloadFile) {
    if downloader_ptr.is_null() {
        return;
    }
    unsafe {
        Box::from_raw(downloader_ptr); // Automatically dropped
    }
}
