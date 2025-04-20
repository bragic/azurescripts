function Add-EntraUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("CreateSingle", "CreateBulk", "DeleteSingle", "DeleteBulk")]
        [string]$Action,

        [Parameter(Mandatory = $false)]
        [string]$CsvPath,

        [Parameter(Mandatory = $false)]
        [string]$UserPrincipalName,

        [Parameter(Mandatory = $false)]
        [string]$DisplayName,

        [Parameter(Mandatory = $false)]
        [string]$GivenName,

        [Parameter(Mandatory = $false)]
        [string]$Surname,

        [Parameter(Mandatory = $false)]
        [string]$MailNickname,

        [Parameter(Mandatory = $false)]
        [string]$Password,

        [Parameter(Mandatory = $false)]
        [string]$UsageLocation = "US"
    )

    # Ensure Microsoft Graph module is installed
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force
    }

    Import-Module Microsoft.Graph

    # Connect to Microsoft Graph
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes "User.ReadWrite.All"
    }

    switch ($Action) {
        "CreateSingle" {
            if (-not ($UserPrincipalName -and $DisplayName -and $GivenName -and $Surname -and $MailNickname -and $Password)) {
                Write-Error "Missing required parameters for single user creation."
                return
            }

            $PasswordProfile = @{
                Password                      = $Password
                ForceChangePasswordNextSignIn = $true
            }

            New-MgUser -AccountEnabled $true `
                -DisplayName $DisplayName `
                -GivenName $GivenName `
                -Surname $Surname `
                -UserPrincipalName $UserPrincipalName `
                -MailNickname $MailNickname `
                -PasswordProfile $PasswordProfile `
                -UsageLocation $UsageLocation
        }

        "CreateBulk" {
            if (-not (Test-Path $CsvPath)) {
                Write-Error "CSV file not found at path: $CsvPath"
                return
            }

            $Users = Import-Csv -Path $CsvPath
            foreach ($User in $Users) {
                $PasswordProfile = @{
                    Password                      = $User.Password
                    ForceChangePasswordNextSignIn = $true
                }

                try {
                    New-MgUser -AccountEnabled $true `
                        -DisplayName $User.DisplayName `
                        -GivenName $User.GivenName `
                        -Surname $User.Surname `
                        -UserPrincipalName $User.UserPrincipalName `
                        -MailNickname $User.MailNickname `
                        -PasswordProfile $PasswordProfile `
                        -UsageLocation $User.UsageLocation
                    Write-Host "Created user: $($User.UserPrincipalName)"
                }
                catch {
                    Write-Error "Failed to create user $($User.UserPrincipalName): $_"
                }
            }
        }

        "DeleteSingle" {
            if (-not $UserPrincipalName) {
                Write-Error "UserPrincipalName is required for single user deletion."
                return
            }

            try {
                Remove-MgUser -UserId $UserPrincipalName -Confirm:$false
                Write-Host "Deleted user: $UserPrincipalName"
            }
            catch {
                Write-Error "Failed to delete user $UserPrincipalName: $_"
            }
        }

        "DeleteBulk" {
            if (-not (Test-Path $CsvPath)) {
                Write-Error "CSV file not found at path: $CsvPath"
                return
            }

            $Users = Import-Csv -Path $CsvPath
            foreach ($User in $Users) {
                try {
                    Remove-MgUser -UserId $User.UserPrincipalName -Confirm:$false
                    Write-Host "Deleted user: $($User.UserPrincipalName)"
                }
                catch {
                    Write-Error "Failed to delete user $($User.UserPrincipalName): $_"
                }
            }
        }
    }
}
