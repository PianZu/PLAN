# PLAN Database Setup & Administration

Dieses Projekt enthält alle notwendigen Daten für die Erstellung der Datenbank **PLAN** im Modul Informationssysteme.

## Enthaltene Dateien

Stellen Sie sicher, dass sich die folgenden Dateien im selben Ordner befinden:

* **setup_plan.sh** – Das Haupt-Shell-Skript zur Automatisierung.
* **create_staging.sql** – Erstellt die Tabellenstruktur im Schema `SCHEMA_MAIN`.
* **02_load_from_excel_new_no_truncate.sql** – Lädt die Daten in die Tabellen.
* **skripte.txt** – Enthält zusätzliche technische Details.

## Installation & Ausführung

Folgen Sie diesen Schritten im Terminal, um die Datenbank einzurichten:

### 1. In das Verzeichnis navigieren

```bash
cd /pfad/zu/deinem/folder
```

### 2. Skript ausführbar machen

```bash
chmod +x setup_plan.sh
```

### 3. Setup starten

```bash
./setup_plan.sh create_staging.sql 02_load_from_excel_new_no_truncate.sql
```


