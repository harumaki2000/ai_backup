#!/bin/bash

# バックアップファイル名とディレクトリ名
BACKUP_FILE="ai_backup_$(date +%Y%m%d_%H%M%S).tgz"
BACKUP_DIR="/home/ai/ai_backup" # 一時的なバックアップファイル保存先
GOOGLEDRIVE_PATH="/home/ai/GoogleDrive" # GoogleDriveのマウントディレクトリ
DOCKER_DIR="/home/ai/ai" # Dockerが動いているディレクトリ

# Discord Webhook URL
DISCORD_WEBHOOK_URL="your_discord_webhook_url"

# sudoパスワード
PASSWORD="your_password"

# Dockerが動いているディレクトリに移動
cd "$DOCKER_DIR"

# バックアップ開始通知
curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"📌 データベースのバックアップを開始します。\"}" "$DISCORD_WEBHOOK_URL"

# Dockerを止める
echo $PASSWORD | sudo -S docker compose down

# ディレクトリをtar.gzで固める
sudo tar -zvcf "${BACKUP_DIR}/${BACKUP_FILE}" "${DOCKER_DIR}"

if [ $? -eq 0 ]; then
    echo "Database backup successful: ${BACKUP_FILE}"

    # GoogleDriveにコピー
    cp "${BACKUP_DIR}/${BACKUP_FILE}" "${GOOGLEDRIVE_PATH}"

    if [ $? -eq 0 ]; then
        echo "Backup copied to Google Drive."

        # Discordに成功通知
        curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"✅ データベースのバックアップが完了し、Google Driveにアップロードされました: ${BACKUP_FILE}\"}" "$DISCORD_WEBHOOK_URL"
    else
        echo "Failed to copy backup to Google Drive."

        # Discordにエラー通知
        curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"⚠ データベースのバックアップコピーに失敗しました: ${BACKUP_FILE}\"}" "$DISCORD_WEBHOOK_URL"
    fi

    # 7日以上前のバックアップを削除
    find "${BACKUP_DIR}" -type f -name "ai_backup_*.tgz" -mtime +7 -exec rm {} \;

    if [ $? -eq 0 ]; then
        echo "Old backups deleted successfully."
        
        # Discordに成功通知
        curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"🧹 7日以上前のローカルバックアップファイルを削除しました。\"}" "$DISCORD_WEBHOOK_URL"
    else
        echo "Failed to delete old backups."
        
        # Discordにエラー通知
        curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"⚠ 7日以上前のローカルバックアップファイルの削除に失敗しました。\"}" "$DISCORD_WEBHOOK_URL"
    fi

else
    echo "Database backup failed."

    # Discordにエラー通知
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"❌ データベースのバックアップに失敗しました。\"}" "$DISCORD_WEBHOOK_URL"
fi


# Docker動かす
echo $PASSWORD | sudo -S docker compose up -d
