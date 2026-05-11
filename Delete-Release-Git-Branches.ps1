git branch | Where-Object { $_ -match "release\/s" } | ForEach-Object { git branch -D $_.trim() }
