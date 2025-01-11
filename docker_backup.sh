#!/bin/bash

# バックアップファイル名とディレクトリ名
BACKUP_FILE="ai_backup_$(date +%Y%m%d_%H%M%S).tgz"
BACKUP_DIR="/home/ai/ai_backup" # 一時的なバックアップファイル保存先
DOCKER_DIR="/home/ai/ai" # Dockerが動いているディレクトリ
RCLONE_REMOTE="your_rclone_remote" # rcloneで設定したリモート名（例: gdrive）
RCLONE_DESTINATION="backup_folder" # Google Drive上の保存先フォルダ名

# Discord Webhook URL
DISCORD_WEBHOOK_URL="your_discord_webhook_url"

# sudoパスワード
PASSWORD="your_password"

# Dockerが動いているディレクトリに移動
cd "$DOCKER_DIR"

# バックアップ開始通知
curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"📌 データベースのバックアップを開始します。\"}" "$DISCORD_WEBHOOK_URL"

# Dockerを停止
echo $PASSWORD | sudo -S docker compose down

# ディレクトリをtar.gzで固める
sudo tar -zvcf "${BACKUP_DIR}/${BACKUP_FILE}" -C "${DOCKER_DIR}" .

if [ $? -eq 0 ]; then
    echo "Backup successful: ${BACKUP_FILE}"

    # rcloneでGoogle Driveにアップロード
    rclone copy "${BACKUP_DIR}/${BACKUP_FILE}" "${RCLONE_REMOTE}:${RCLONE_DESTINATION}"

    if [ $? -eq 0 ]; then
        echo "Backup uploaded to Google Drive using rclone."

        # Discordに成功通知
        curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"✅ バックアップが完了し、Google Driveにアップロードされました: ${BACKUP_FILE}\"}" "$DISCORD_WEBHOOK_URL"
    else
        echo "Failed to upload backup to Google Drive using rclone."

        # Discordにエラー通知
        curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"⚠ Google Driveへのバックアップアップロードに失敗しました: ${BACKUP_FILE}\"}" "$DISCORD_WEBHOOK_URL"
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
    echo "Backup failed."

    # Discordにエラー通知
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"❌ バックアップ作成に失敗しました。\"}" "$DISCORD_WEBHOOK_URL"
fi

# Dockerを再起動
echo $PASSWORD | sudo -S docker compose up -d
