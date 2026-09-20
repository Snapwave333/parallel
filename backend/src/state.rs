use sqlx::SqlitePool;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use tokio::sync::broadcast;

#[derive(Clone)]
pub struct Hub {
    rooms: Arc<Mutex<HashMap<String, broadcast::Sender<String>>>>,
}

impl Default for Hub {
    fn default() -> Self {
        Self {
            rooms: Arc::new(Mutex::new(HashMap::new())),
        }
    }
}

impl Hub {
    pub fn join(&self, room: &str) -> broadcast::Receiver<String> {
        let mut map = self.rooms.lock().unwrap();
        let tx = map
            .entry(room.to_string())
            .or_insert_with(|| broadcast::channel(256).0.clone());
        tx.subscribe()
    }

    pub fn publish(&self, room: &str, event: &str) {
        if let Some(tx) = self.rooms.lock().unwrap().get(room) {
            let _ = tx.send(event.to_string());
        }
    }

    pub fn drop_room(&self, room: &str) {
        self.rooms.lock().unwrap().remove(room);
    }
}

#[derive(Clone)]
pub struct AppState {
    pub db: SqlitePool,
    pub hub: Hub,
}

impl AppState {
    pub fn new(db: SqlitePool) -> Self {
        Self {
            db,
            hub: Hub::default(),
        }
    }
}