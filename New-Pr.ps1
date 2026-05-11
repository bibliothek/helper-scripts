[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $CommitMessage, 
    [switch]
    $AddAndCommit
)

if($AddAndCommit)
{
    git add .
    git commit -m "$CommitMessage"
}

gpsup

gh pr create -b "## Description `n`n$CommitMessage" -t $CommitMessage --assignee=@me
$prUrl = gh pr view --json url --jq '.url'

$clipboard = "👀 $CommitMessage`n$prUrl"
$clipboard | Set-Clipboard

