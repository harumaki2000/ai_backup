## ai_backup
https://github.com/syuilo/ai のバックアップスクリプトです。
記述ミスのみchatGPTに直してもらってます。
ディレクトリごとのバックアップなのでDockerで動かしているものならなんでも使えると思います(検証してませんので悪しからず)

## 必要なコマンド
google-drive-ocamlfuseを使用しています。
[Ubuntu/LinuxにGoogleDriveをマウントする](https://zenn.dev/harumaki2000/articles/5ec7fb4cb33d1c) を参考にしてください。

## スクリプト実行権限付与
```
chmod +x ai_backup.sh
```

## cron登録
```
crontab -e
# 3時に実行する場合
0 3 * * * /home/ai/ai_backup.sh
```
