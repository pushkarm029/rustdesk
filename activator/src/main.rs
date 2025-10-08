use std::io::{Read, Write};
use std::time::Duration;

#[cfg(unix)]
use std::os::unix::net::UnixStream;

fn main() {
    if let Err(e) = send_toggle_signal() {
        eprintln!("✗ Error: {e}");
        std::process::exit(1);
    }
}

#[cfg(unix)]
fn send_toggle_signal() -> Result<(), Box<dyn std::error::Error>> {
    const SOCKET_PATH: &str = "/tmp/rustdesk_cm.sock";
    const TIMEOUT_SECS: u64 = 5;

    let mut stream = UnixStream::connect(SOCKET_PATH)
        .map_err(|e| format!("Failed to connect. Is the Flutter app running?\nError: {e}"))?;

    // Set timeouts for safety
    let timeout = Some(Duration::from_secs(TIMEOUT_SECS));
    stream.set_write_timeout(timeout)?;
    stream.set_read_timeout(timeout)?;

    // Send toggle command
    stream.write_all(b"toggle\n")?;
    stream.flush()?;

    // Read response
    let mut response = String::new();
    stream.read_to_string(&mut response)?;

    let status = response.trim();
    match status {
        "shown" => println!("✓ Window is now visible"),
        "hidden" => println!("✓ Window is now hidden"),
        _ => println!("✓ Response: {status}"),
    }

    Ok(())
}

#[cfg(windows)]
fn send_toggle_signal() -> Result<(), Box<dyn std::error::Error>> {
    use std::net::TcpStream;

    const HOST: &str = "127.0.0.1:9999";
    const TIMEOUT_SECS: u64 = 5;

    let mut stream = TcpStream::connect(HOST)
        .map_err(|e| format!("Failed to connect. Is the Flutter app running?\nError: {e}"))?;

    // Set timeouts for safety
    let timeout = Some(Duration::from_secs(TIMEOUT_SECS));
    stream.set_write_timeout(timeout)?;
    stream.set_read_timeout(timeout)?;

    // Send toggle command
    stream.write_all(b"toggle\n")?;
    stream.flush()?;

    // Read response
    let mut response = String::new();
    stream.read_to_string(&mut response)?;

    let status = response.trim();
    match status {
        "shown" => println!("✓ Window is now visible"),
        "hidden" => println!("✓ Window is now hidden"),
        _ => println!("✓ Response: {status}"),
    }

    Ok(())
}

#[cfg(not(any(unix, windows)))]
fn send_toggle_signal() -> Result<(), Box<dyn std::error::Error>> {
    Err("Platform not supported. Only Unix and Windows are supported.".into())
}
