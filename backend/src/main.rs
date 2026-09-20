use parallel_backend::{app, db, state};
use state::AppState;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".into());
    let db_url =
        std::env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://parallel.db".to_string());
    let pool = db::connect(&db_url).await?;
    let state = AppState {
        db: pool,
        hub: state::Hub::default(),
    };
    let app = app(state);

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}")).await?;
    println!("parallel backend listening on http://localhost:{port}");
    axum::serve(
        listener,
        app.layer(
            tower_http::trace::TraceLayer::new_for_http().make_span_with(
                tower_http::trace::DefaultMakeSpan::new().level(tracing::Level::INFO),
            ),
        )
        .layer(
            tower_http::cors::CorsLayer::permissive(),
        ),
    )
    .await?;
    Ok(())
}