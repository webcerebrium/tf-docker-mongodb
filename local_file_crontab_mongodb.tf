resource "local_file" "crontab_mongodb" {
  content = var.network_params.env == "local" ? "" : <<EOF
PATH=/usr/bin:/bin:/usr/local/bin
0 3 * * * karta bash ${path.cwd}/bin/mongodb-backup.sh >> /var/log/mongodb-backup.log 2>&1
EOF

  filename = "./cron.d/crontab_mongodb"
  file_permission = "0777"
}
