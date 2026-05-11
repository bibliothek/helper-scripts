#! /snap/bin/pwsh
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $RootPath = "~/notes/dailynote",
    
    [Parameter()]
    [datetime]
    $StartDate,

    [Parameter()]
    [int]
    $Month,

    [Parameter()]
    [int]
    $Year,

    [Parameter()]
    [switch]
    $InferStartDate
)

function CreateFile {
    param (
        $date
    )
    $folderPath = Join-Path $RootPath -ChildPath "$($date.Year)/$($date.Month)"

    if(-not (Test-Path $folderPath)){
        mkdir $folderPath
    }

    $weekday = "";

    switch ($date.DayOfWeek) {
        "Sunday" { $weekday = "Sonntag"  }
        "Monday" { $weekday = "Montag"  }
        "Tuesday" { $weekday = "Dienstag"  }
        "Wednesday" { $weekday = "Mittwoch"  }
        "Thursday" { $weekday = "Donnerstag"  }
        "Friday" { $weekday = "Freitag"  }
        "Saturday" { $weekday = "Samstag"  }
        Default {}
    }

    $datename = "{0:yyyy-MM-dd}" -f $date
    $year = get-date -Format yyyy

    $filename = "0_$($datename)-$($weekday).md"

    $newFilePath = Join-Path $folderPath $filename

    Write-Output $newFilePath

    Add-Content -path $newFilePath -Value "# $($datename)-$weekday`n`n#dailynote #y$year`n`n---`n`n"
}

function CreateFiles {
    param (
        $startDate,
        $endDate
    )
    $dates = @()

    $date = $startDate
    while ($date -lt $endDate) {
        $dates += $date
        $date = $date.AddDays(1)
    }
    $dates | ForEach-Object {CreateFile $_}
}

if (($Month -gt 0) -and ($Year -gt 0)) {
    $start = get-date -Year $Year -Month $Month -Day 1
    $daysInMonth = [DateTime]::DaysInMonth($Year, $Month)
    $end = get-date -Year $Year -Month $Month -Day $daysInMonth
    CreateFiles $start $end
} elseif (-not $StartDate -and -not $InferStartDate) { 
    CreateFile (Get-Date)
} elseif ($InferStartDate) {
    $lastCreatedDate = [datetime] (Get-ChildItem (Get-ChildItem $RootPath | Select-Object -last 1)  | Select-Object -last 1).Name.Substring(0,10)
    $currentDate = (get-date)
    CreateFiles $lastCreatedDate.AddDays(1) $currentDate
}
else {
    $currentDate = (get-date)
    CreateFiles $start $currentDate
}
