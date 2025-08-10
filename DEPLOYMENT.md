# Deployment Instructions for the Daily Anomaly Report Script

## Introduction

This document provides instructions on how to deploy and run the daily anomaly report script on a Linux server. The script is designed to be run automatically via a CRON job.

**IMPORTANT:** Due to the way the project is structured as a Flutter application, compiling the pure Dart command-line script requires some temporary modifications to the project's dependency file (`pubspec.yaml`). Please follow the steps carefully.

## Prerequisites

- A Linux server with SSH access.
- The Dart SDK installed on the server. You can find installation instructions at [https://dart.dev/get-dart](https://dart.dev/get-dart).

## Step 1: Preparing for Compilation

Before you can compile the script, you need to temporarily modify the `pubspec.yaml` file to remove dependencies that are specific to the Flutter mobile app.

1.  **Backup your `pubspec.yaml` file:**
    ```bash
    cp pubspec.yaml pubspec.yaml.bak
    ```

2.  **Edit `pubspec.yaml`:**
    Open `pubspec.yaml` in a text editor and comment out or remove the following dependencies:
    - `flutter`
    - `cupertino_icons`
    - `google_fonts`
    - `fl_chart`
    - `shared_preferences`
    - `flutter_test` (under `dev_dependencies`)
    - The entire `flutter:` section at the bottom of the file.

    Your `dependencies` section should look something like this afterwards:
    ```yaml
    dependencies:
      http: ^1.2.1
      intl: ^0.19.0
      supabase_flutter: ^2.5.0 # This should be replaced with supabase if you face issues.
      mailer: ^6.1.0
      logging: ^1.2.0
    ```
    *Note: During development, it was discovered that `supabase_flutter` might need to be replaced with the pure Dart `supabase` package if you are compiling in an environment without the Flutter SDK. If you encounter issues, replace `supabase_flutter: ^2.5.0` with `supabase: ^2.8.0`.*


3.  **Get the script's dependencies:**
    Run the following command to fetch the packages required by the script:
    ```bash
    dart pub get
    ```

## Step 2: Compiling the Script

Now that the dependencies are correctly configured, you can compile the script into a standalone executable.

1.  **Run the compile command:**
    ```bash
    dart compile exe bin/send_anomaly_report.dart -o anomaly_reporter
    ```
    This will create an executable file named `anomaly_reporter` in the project's root directory.

## Step 3: Restoring the Project

It is crucial to restore the `pubspec.yaml` file to its original state so that the Flutter mobile application continues to work correctly.

1.  **Restore the original `pubspec.yaml`:**
    ```bash
    mv pubspec.yaml.bak pubspec.yaml
    ```
2.  **Run `flutter pub get`:**
    To ensure the Flutter app's dependencies are correctly restored, run:
    ```bash
    flutter pub get
    ```

## Step 4: Configuration

The script requires a `config.json` file to be present in the same directory from which it is run.

1.  **Create the `config.json` file:**
    On your server, in the directory where you will place the `anomaly_reporter` executable, create a file named `config.json`.

2.  **Populate the file with your details:**
    ```json
    {
      "smtp": {
        "host": "your_smtp_host",
        "port": 465,
        "username": "your_smtp_username",
        "password": "your_smtp_password"
      },
      "recipients": [
        "recipient1@example.com",
        "recipient2@example.com"
      ],
      "lookback_days": 3
    }
    ```
    - Replace the placeholder values with your actual SMTP server details and recipient email addresses.
    - `lookback_days` controls how many days of past data the script will analyze.

## Step 5: Setting up the CRON Job

Finally, set up a CRON job to run the script automatically every day.

1.  **Open your crontab for editing:**
    ```bash
    crontab -e
    ```

2.  **Add a new line to run the script:**
    This example runs the script every day at 7 AM.
    ```
    0 7 * * * /path/to/your/project/anomaly_reporter >> /path/to/your/project/cron.log 2>&1
    ```
    - Replace `/path/to/your/project/` with the actual absolute path to the directory containing the `anomaly_reporter` executable and the `config.json` file.
    - The `>> cron.log 2>&1` part is optional but recommended. It redirects all output (both standard and error) from the script into a `cron.log` file, which is useful for debugging.

Your daily anomaly report script is now deployed and configured to run automatically. The script will also generate its own log file, `anomaly_report.log`, in the same directory.
