use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::SqlitePool;
use std::str::FromStr;

pub async fn connect(url: &str) -> Result<SqlitePool, sqlx::Error> {
    let (opts, max_connections) = if url == ":memory:" || url == "sqlite::memory:" {
        (SqliteConnectOptions::new().in_memory(true), 1u32)
    } else {
        let u = if url.starts_with("sqlite:") {
            url.to_string()
        } else {
            format!("sqlite://{url}")
        };
        (
            SqliteConnectOptions::from_str(&u)?.create_if_missing(true),
            8u32,
        )
    };
    let opts = opts.foreign_keys(true);
    let pool = SqlitePoolOptions::new()
        .max_connections(max_connections)
        .connect_with(opts)
        .await?;
    sqlx::migrate!().run(&pool).await?;
    Ok(pool)
}