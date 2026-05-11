[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $TargetBranch,

    [Parameter(ParameterSetName = 'UseBranch', Mandatory = $false)]
    [switch]
    $UseBranch,

    [Parameter(ParameterSetName = 'UseCommit', Mandatory = $true)]
    [string]
    $Hash,

    [Parameter(ParameterSetName = 'UseCommit', Mandatory = $true)]
    [string]
    $BranchName,
    
    [Parameter(ParameterSetName = 'UseCommit', Mandatory = $true)]
    [string]
    $PrNumber
)

if(!$UseBranch -and !$BranchName) {
    throw "Specify branch name or use switch '-UseBranch'"
}

if($UseBranch) {
    $Hash = (git rev-parse HEAD)
    $BranchName = (git rev-parse --abbrev-ref HEAD)
    $PrNumber = (gh pr view $BranchName --json number --jq .number)   
}

$currentCommitMessage = (git log $Hash^..$Hash --pretty=%B)

git checkout $TargetBranch
git pull
git checkout -b "cp/$TargetBranch/$BranchName"

git cherry-pick $Hash

git push --set-upstream origin "cp/$TargetBranch/$BranchName"

gh pr create --base $TargetBranch --body "cherry-pick from #$PrNumber" --title "🍒 $currentCommitMessage" --assignee "@me"

$clipBoard = Get-Clipboard
if ($clipBoard -notlike "👀*") {
    $originalPrUrl = gh pr view $PrNumber --json url --jq '.url'
    $clipBoard = "👀 $currentCommitMessage `n🌸 $originalPrUrl"
}
$prUrl = gh pr view --json url --jq '.url'
$clipBoard += "`n"
$clipBoard += "🍒 $prUrl"
$clipBoard | Set-Clipboard
