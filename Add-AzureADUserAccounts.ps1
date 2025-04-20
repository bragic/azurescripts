# Import Azure AD module
#Import-Module AzureAD

function Set-AzureADUserAccounts {
    param (
        [Parameter(Mandatory = $false)]
        [string]$SingleUserName,

        [Parameter(Mandatory = $false)]
        [string]$SingleUserPassword,

        [Parameter(Mandatory = $false)]
        [string]$CSVFilePath,

        [Parameter(Mandatory = $false)]
        [switch]$Delete
    )

    # Ensure the user is authenticated to Azure AD
    try {
        if (-not (Get-AzureADUser -Top 1 -ErrorAction SilentlyContinue)) {
            Write-Host "Authenticating to Azure AD..."
            Connect-AzureAD
        }
    }
    catch {
        Write-Error "Failed to authenticate to Azure AD. Please check your credentials and try again."
        return
    }

    try {
        if ($Delete) {
            # Delete user accounts
            if ($SingleUserName) {
                Write-Host "Deleting user: $SingleUserName"
                $user = Get-AzureADUser -Filter "userPrincipalName eq '$SingleUserName'" -ErrorAction Stop
                Remove-AzureADUser -ObjectId $user.ObjectId -Confirm:$false
                Write-Host "User $SingleUserName deleted successfully."
            }
            elseif ($CSVFilePath) {
                Write-Host "Deleting users from CSV file: $CSVFilePath"
                $users = Import-Csv -Path $CSVFilePath
                foreach ($user in $users) {
                    $userPrincipalName = $user.UserPrincipalName
                    Write-Host "Deleting user: $userPrincipalName"
                    $userObj = Get-AzureADUser -Filter "userPrincipalName eq '$userPrincipalName'" -ErrorAction Stop
                    Remove-AzureADUser -ObjectId $userObj.ObjectId -Confirm:$false
                    Write-Host "User $userPrincipalName deleted successfully."
                }
            }
            else {
                Write-Error "Please provide a username or CSV file for deletion."
            }
        }
        else {
            # Create user accounts
            if ($SingleUserName -and $SingleUserPassword) {
                Write-Host "Creating user: $SingleUserName"
                New-AzureADUser -DisplayName $SingleUserName -UserPrincipalName $SingleUserName -AccountEnabled $true -PasswordProfile @{Password = $SingleUserPassword; ForceChangePasswordNextLogin = $true }
                Write-Host "User $SingleUserName created successfully."
            }
            elseif ($CSVFilePath) {
                Write-Host "Creating users from CSV file: $CSVFilePath"
                $users = Import-Csv -Path $CSVFilePath
                foreach ($user in $users) {
                    $displayName = $user.DisplayName
                    $userPrincipalName = $user.UserPrincipalName
                    $password = $user.Password
                    Write-Host "Creating user: $userPrincipalName"
                    New-AzureADUser -DisplayName $displayName -UserPrincipalName $userPrincipalName -AccountEnabled $true -PasswordProfile @{Password = $password; ForceChangePasswordNextLogin = $true }
                    Write-Host "User $userPrincipalName created successfully."
                }
            }
            else {
                Write-Error "Please provide a username/password or CSV file for creation."
            }
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

# CSV File Format for Bulk Operations
# For creating users:
# DisplayName,UserPrincipalName,Password
# John Doe,johndoe@yourdomain.com,Password123!
# Jane Smith,janesmith@yourdomain.com,Password123!

# For deleting users:
# UserPrincipalName
# johndoe@yourdomain.com
# janesmith@yourdomain.com