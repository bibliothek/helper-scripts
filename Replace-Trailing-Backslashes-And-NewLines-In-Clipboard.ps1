$content = (Get-Clipboard -Raw).ReplaceLineEndings()

$contentWithoutTrailingSlashesAndLineBreaks = $content.Replace("\" + [System.Environment]::Newline, " ").ReplaceLineEndings(" ").Trim()

$cleaned = $contentWithoutTrailingSlashesAndLineBreaks -replace '\s+', ' '

$cleaned | clip