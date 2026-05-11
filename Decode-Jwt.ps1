<#
.SYNOPSIS
    Decodes a JWT token from stdin and displays the header and payload.
.DESCRIPTION
    This script reads a JWT token from the standard input (pipeline), removes the "Bearer " prefix if present,
    and then decodes the header and payload components of the token. The decoded header and
    payload are then displayed as PowerShell objects.
.EXAMPLE
    PS C:> 'your.jwt.token' | .\Decode-Jwt.ps1
    # The script will output the decoded header and payload.
.EXAMPLE
    PS C:> Get-Clipboard | .\Decode-Jwt.ps1
    # You can also pipe from the clipboard.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$Jwt
)

process {
    # Remove "Bearer " prefix if it exists
    if ($Jwt.StartsWith("Bearer ")) {
        $token = $Jwt.Substring(7)
    } else {
        $token = $Jwt
    }

    # Split the token into its parts
    $parts = $token.Split('.')
    if ($parts.Length -ne 3) {
        Write-Error "Invalid JWT format. A JWT must have 3 parts separated by dots."
        return
    }

    # Decode the header and payload
    $headerBase64 = $parts[0]
    $payloadBase64 = $parts[1]

    # Add padding if necessary
    $headerBase64 = $headerBase64.PadRight($headerBase64.Length + (4 - $headerBase64.Length % 4) % 4, '=')
    $payloadBase64 = $payloadBase64.PadRight($payloadBase64.Length + (4 - $payloadBase64.Length % 4) % 4, '=')

    try {
        $headerJson = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($headerBase64))
        $payloadJson = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payloadBase64))

        $header = $headerJson | ConvertFrom-Json
        $payload = $payloadJson | ConvertFrom-Json

        # Create a custom object for the payload to control formatting
        $outputPayload = [ordered]@{}
        $payload.PSObject.Properties | ForEach-Object {
            $key = $_.Name
            $value = $_.Value

            if ($key -in @('iat', 'exp', 'nbf') -and $value -is [long]) {
                # Convert Unix timestamps to readable local time
                try {
                    $datetime = [datetimeoffset]::FromUnixTimeSeconds($value).DateTime.ToLocalTime()
                    $outputPayload[$key] = "$value ($datetime)"
                } catch {
                    $outputPayload[$key] = $value # Fallback
                }
            } elseif ($key -eq 'aud') {
                # Format audience as a clean multi-line string to prevent truncation
                $audiences = @($value)
                $outputPayload[$key] = $audiences -join [System.Environment]::NewLine
            } elseif ($key -eq 'scope') {
                # Format scope as a clean multi-line string to prevent truncation
                $scopes = if ($value -is [string]) { $value.Split(' ') } else { @($value) }
                $outputPayload[$key] = $scopes -join [System.Environment]::NewLine
            } else {
                $outputPayload[$key] = $value
            }
        }

        # Output the decoded parts
        Write-Output "Header:"
        $header | Format-List

        Write-Output "Payload:"
        [pscustomobject]$outputPayload | Format-List
    }
    catch {
        Write-Error "Failed to decode JWT token. Make sure it is a valid Base64Url encoded string."
        Write-Error $_.Exception.Message
    }
}
