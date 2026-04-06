use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use anyhow::{Result, Context};
use tracing::{info, debug};

/// Atomares Schreiben einer Datei
pub fn atomic_write<P: AsRef<Path>>(path: P, content: &str) -> Result<()> {
    let path = path.as_ref();
    
    // 1. Backup erstellen (falls etwas schiefgeht)
    if path.exists() {
        let backup_path = create_backup_path(path)?;
        fs::copy(path, &backup_path)
            .with_context(|| format!("Backup erstellen fehlgeschlagen: {:?}", backup_path))?;
        debug!("Backup erstellt: {:?}", backup_path);
    }
    
    // 2. Temp-Datei im selben Verzeichnis erstellen
    let temp_path = path.with_extension("tmp");
    {
        let mut temp_file = fs::File::create(&temp_path)
            .with_context(|| format!("Temp-Datei erstellen fehlgeschlagen: {:?}", temp_path))?;
        temp_file.write_all(content.as_bytes())
            .with_context(|| "Schreiben in Temp-Datei fehlgeschlagen")?;
        temp_file.sync_all()
            .with_context(|| "Sync auf Disk fehlgeschlagen")?;
    }
    
    // 3. Atomare Umbenennung
    fs::rename(&temp_path, path)
        .with_context(|| format!("Atomares Rename fehlgeschlagen: {:?} -> {:?}", temp_path, path))?;
    
    info!("Atomar geschrieben: {:?}", path);
    Ok(())
}

/// Backup-Pfad erstellen mit Zeitstempel
fn create_backup_path(path: &Path) -> Result<PathBuf> {
    let timestamp = chrono::Local::now().format("%Y%m%d-%H%M%S");
    let filename = path.file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("backup");
    let ext = path.extension()
        .and_then(|s| s.to_str())
        .unwrap_or("bak");
    
    let backup_name = format!("{}.{}.{}", filename, timestamp, ext);
    let backup_path = path.with_file_name(backup_name);
    
    Ok(backup_path)
}

/// Sicheres Löschen (verschiebt zu .deleted/ statt wirklich löschen)
pub fn safe_delete<P: AsRef<Path>>(path: P) -> Result<()> {
    let path = path.as_ref();
    
    if !path.exists() {
        return Ok(());
    }
    
    let deleted_dir = path.parent()
        .map(|p| p.join(".deleted"))
        .unwrap_or_else(|| PathBuf::from(".deleted"));
    
    fs::create_dir_all(&deleted_dir)
        .with_context(|| format!(".deleted Ordner erstellen fehlgeschlagen: {:?}", deleted_dir))?;
    
    let timestamp = chrono::Local::now().format("%Y%m%d-%H%M%S");
    let filename = path.file_name()
        .and_then(|s| s.to_str())
        .unwrap_or("unknown");
    let deleted_path = deleted_dir.join(format!("{}.{}", filename, timestamp));
    
    fs::rename(path, &deleted_path)
        .with_context(|| format!("Verschieben nach .deleted fehlgeschlagen: {:?} -> {:?}", path, deleted_path))?;
    
    info!("Sicher gelöscht: {:?} -> {:?}", path, deleted_path);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Read;
    use std::fs;
    use tempfile::TempDir;

    #[test]
    fn test_atomic_write_new_file() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.txt");

        atomic_write(&file_path, "Hello World").unwrap();

        let mut content = String::new();
        fs::File::open(&file_path).unwrap().read_to_string(&mut content).unwrap();
        assert_eq!(content, "Hello World");
    }

    #[test]
    fn test_atomic_write_creates_backup() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.txt");

        // Erstmal normal schreiben
        fs::write(&file_path, "Old Content").unwrap();

        // Dann atomar überschreiben
        atomic_write(&file_path, "New Content").unwrap();

        // Prüfen: Neue Datei hat neuen Inhalt
        let content = fs::read_to_string(&file_path).unwrap();
        assert_eq!(content, "New Content");
    }
}
