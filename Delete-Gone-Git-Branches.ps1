git fetch -p;

$goneBranches = git branch -vv | awk '/: gone]/{print $1}';

foreach ($item in $goneBranches) {
    git branch -D $item;
}
