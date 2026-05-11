#!/

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Name,
    [Parameter(Mandatory = $false)]
    [ValidateSet("DE", "EN")]
    [string]
    $Language = "DE"
)

switch ($Language) {
    "DE" {
        $response = "Hallo $Name,`n`nich bin happy in meiner aktuellen Position und nicht auf der Suche nach etwas Neuem.`n`nLG"        
    }
    "EN" {
        $response = "Hi $Name,`n`nI'm happy in my current position and not looking for something new.`n`nBR"
    }
}

$response | Set-Clipboard
Write-Host "Copied to clipboard"