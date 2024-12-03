use egui::{Button, CentralPanel, Context, Label};
use git2::Repository;
use reqwest::Client;
use std::path::Path;
use std::sync::Arc;
use std::sync::Mutex;
use tokio::runtime::Runtime;

#[tokio::main]
async fn main() {
    // 啟動 GUI
    let native_options = eframe::NativeOptions {
        drag_and_drop_support: true,
        initial_window_size: Some(egui::vec2(800.0, 600.0)),
        ..Default::default()
    };

    eframe::run_native(
        "Minecraft Launcher",
        native_options,
        Box::new(|_cc| Box::<MyApp>::default()),
    );
}

#[derive(Default)]
struct MyApp {
    client: Arc<Mutex<Client>>,
    message: String,
}

impl eframe::App for MyApp {
    fn update(&mut self, ctx: &Context, _frame: &mut eframe::Frame) {
        CentralPanel::default().show(ctx, |ui| {
            ui.heading("Minecraft Launcher");

            ui.label(&self.message);

            if ui.button("Check for updates").clicked() {
                let client = self.client.lock().unwrap();
                let response = self.check_for_updates(&client);
                self.message = response.await;
            }

            if ui.button("Download Minecraft").clicked() {
                let client = self.client.lock().unwrap();
                let response = self.download_minecraft(&client);
                self.message = response.await;
            }

            if ui.button("Update Minecraft").clicked() {
                let response = self.update_minecraft_repo();
                self.message = response;
            }
        });
    }
}

impl MyApp {
    // 檢查是否有可用的更新
    async fn check_for_updates(&self, client: &Client) -> String {
        let url = "https://api.mojang.com/mc";
        match client.get(url).send().await {
            Ok(response) => {
                if response.status().is_success() {
                    return "Minecraft is up-to-date.".to_string();
                }
                "Failed to check for updates.".to_string()
            }
            Err(_) => "Error while checking for updates.".to_string(),
        }
    }

    // 下載 Minecraft
    async fn download_minecraft(&self, client: &Client) -> String {
        let url = "https://launcher.mojang.com/mc/launcher.jar"; // 這個 URL 可以換成實際的 Minecraft 下載地址
        match client.get(url).send().await {
            Ok(_) => "Minecraft downloaded successfully.".to_string(),
            Err(_) => "Error downloading Minecraft.".to_string(),
        }
    }

    // 使用 Git 更新 Minecraft 的相關倉庫
    fn update_minecraft_repo(&self) -> String {
        let repo_path = Path::new("./minecraft_repo");

        if !repo_path.exists() {
            match Repository::clone("https://github.com/Minecraft/MCLauncher", repo_path) {
                Ok(_) => "Minecraft repository cloned.".to_string(),
                Err(_) => "Error cloning Minecraft repository.".to_string(),
            }
        } else {
            match Repository::open(repo_path) {
                Ok(repo) => {
                    let mut remote = repo.find_remote("origin").unwrap();
                    match remote.fetch(&["master"], None, None) {
                        Ok(_) => "Minecraft repository updated.".to_string(),
                        Err(_) => "Error updating Minecraft repository.".to_string(),
                    }
                }
                Err(_) => "Error opening Minecraft repository.".to_string(),
            }
        }
    }
}
