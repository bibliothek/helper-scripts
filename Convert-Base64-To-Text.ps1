$input | ForEach-Object {
    foreach ($line in $_) {
        $decodedBytes = [System.Convert]::FromBase64String($line)
        $decodedString = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
        Write-Output $decodedString
    }
}
