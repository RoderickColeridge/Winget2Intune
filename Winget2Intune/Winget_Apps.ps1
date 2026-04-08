######################################### 
# Intune App Uploader
# Created by: Roderick Coleridge
# Version: 1.0.0
# Date: 26-10-2024
#########################################
# Version 1.0.1
# Added group assignment to the app upload  
# Date: 01-11-2024
#########################################
# Version 1.0.2
# Fixed an issue with detection script 
# Date: 04-11-2024
#########################################
# Version 1.0.3
# Added auto update function
# Date: 05-11-2024
#########################################
# Version 1.0.4
# Added Fixed search function
# Date: 06-11-2024
#########################################
# Version 1.0.5
# Added auto admin consent
# Date: 06-11-2024
#########################################
# Version 1.0.6
# Added Altered Log Directory
# Date: 14-11-2024
#########################################
# Version 1.0.7
# Added proactive remediation script per app to check for updates on a daily base
# Date: 19-11-2024
#########################################
# Version 1.0.8
# Fixed search function
# Fixed OOBE deployment errors
# Date: 29-11-2024
#########################################
# Version 1.0.9
# Fixed error after using remove credentials button
# Date: 29-11-2024
#########################################
# Version 1.1
# Fixed possibility to delete multiple apps
# Date: 02-12-2024
########################################## 
# Version 1.1.1
# Fixed issue with Update remediation
# Date: 17-12-2024
#########################################
# Version 1.1.2
# Added Grab Icon button and function
# Date: 18-12-2024
#########################################
# Version 1.1.3
# Minor bug fixes
# Date: 18-12-2024
#########################################
# Version 1.1.4
# Added possibility to add only Remediation script via Scripts button
# Date: 18-12-2024
#########################################
# Version 1.1.5
# Bugfix on search function
# Date: 23-01-2025
#########################################
# Version 1.1.6
# Bugfix on search function
# Date: 10-02-2025
#########################################
# Version 1.1.7
# Implemented Microsoft.WinGet.Client for search funtion
# Date: 19-02-2025
#########################################
# Version 1.1.8
# Bug fix on Module loading (Thanks to https://github.com/stefanhuibers)
# Date: 26-04-2025
#########################################
# Version 1.1.9
# Added available for uninstall $true
# Built in check foor presence of winget.exe during uninstall
# Date: 15-05-2025
#########################################
# Version 2.0.0
# Bugfixes
# Date: 18-05-2025
#########################################
# Version 2.0.1
# Bugfixes installscript
# Date: 21-05-2025
#########################################
# Version 2.0.2
# Removed proactive remediations for updating apps
# Removed Grab Icon and Scripts buttons
# Added assignment options for All Users
# Added possibility to set assignment to required or available
# Added automated logo upload function
# Rename to Winget2Intune
# Date: 16-07-2025
#########################################
# Version 2.0.3
# Fix in the detection script.
# Switch from -match to Select-String -SimpleMatch due to issues with -match in the detection script.
# Date: 24-07-2025
#########################################
# Version 2.0.4
# Removed the need to add Publisher and Description manually.
# Built in a winget version check when running the script to ensure most recent winget.
# Date: 25-07-2025
#########################################

# Suppress provider prompts
$env:POWERSHELL_UPDATECHECK = "Off"
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Auto-update script

# Define the URL of your script repository
$repoUrl = "https://raw.githubusercontent.com/RoderickColeridge/Winget2Intune/refs/heads/main/Winget2Intune/Winget2Intune.ps1"
$versionFileUrl = "https://raw.githubusercontent.com/RoderickColeridge/Winget2Intune/refs/heads/main/Winget2Intune/version.txt"

# Current version of the script
$currentVersion = "2.0.4"

# Get the directory of the current script
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$localScriptPath = Join-Path -Path $scriptRoot -ChildPath "Winget_Apps.ps1"

# Function to check for updates
function Check-ForUpdates {
    # Get the remote version
    $remoteVersion = (Invoke-WebRequest -Uri $versionFileUrl).Content.Trim()

    if ($currentVersion -ne $remoteVersion) {
        Write-Output "New version available. Updating script..."
        # Download the new script
        Invoke-WebRequest -Uri $repoUrl -OutFile $localScriptPath
        # Update the current version variable
        $script:currentVersion = $remoteVersion
        Write-Output "Script updated to version $remoteVersion"
    } else {
        Write-Output "Script is up to date."
    }
}

# Call the update function
Check-ForUpdates

# Define the Log-Message function
function Log-Message {
    param (
        [string]$Message,
        [string]$LogType = "INFO",
        [System.Management.Automation.ErrorRecord]$ErrorRecord = $null
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$LogType] - $Message"
    if ($ErrorRecord) {
        $logEntry += "`nError Details: $($ErrorRecord.Exception.Message)`nStack Trace: $($ErrorRecord.ScriptStackTrace)"
    }
    $logTextBox.AppendText("$logEntry`r`n")
    Add-Content -Path $LogFilePath -Value $logEntry
}

# Define general variables
# Get script directory
$scriptDirectory = if ($PSScriptRoot) { 
    $PSScriptRoot 
} elseif ($psISE) { 
    Split-Path -Parent $psISE.CurrentFile.FullPath 
} else { 
    Split-Path -Parent $MyInvocation.MyCommand.Path 
}

# Define log directory and files
$logDirectory = Join-Path $scriptDirectory "Logs"
$LogFilePath = Join-Path $logDirectory "IntuneUploadLog.txt"

# Create log directory if it doesn't exist
if (-not (Test-Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
}

$IntuneWinAppUtilUrl = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/refs/heads/master/IntuneWinAppUtil.exe"
$IntuneWinAppUtilPath = "C:\IntunePackages\IntuneWinAppUtil.exe"
$TempDir = "C:\IntunePackages"

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Winget2Intune"
$form.Size = New-Object System.Drawing.Size(800,600)
$form.StartPosition = "CenterScreen"

# Create ListView for apps
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(10,10)
$listView.Size = New-Object System.Drawing.Size(760,200)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.Columns.Add("Display Name", 200)
$listView.Columns.Add("Winget ID", 200)
$listView.Columns.Add("Publisher", 200)
$form.Controls.Add($listView)

# Create buttons
$appRegButton = New-Object System.Windows.Forms.Button
$appRegButton.Location = New-Object System.Drawing.Point(10,220)
$appRegButton.Size = New-Object System.Drawing.Size(75,23)
$appRegButton.Text = "App Reg"
$form.Controls.Add($appRegButton)

$removeCredButton = New-Object System.Windows.Forms.Button
$removeCredButton.Location = New-Object System.Drawing.Point(90,220)
$removeCredButton.Size = New-Object System.Drawing.Size(100,23)
$removeCredButton.Text = "Del Credentials"
$form.Controls.Add($removeCredButton)

$addButton = New-Object System.Windows.Forms.Button
$addButton.Location = New-Object System.Drawing.Point(195,220)
$addButton.Size = New-Object System.Drawing.Size(75,23)
$addButton.Text = "Add"
$form.Controls.Add($addButton)

$editButton = New-Object System.Windows.Forms.Button
$editButton.Location = New-Object System.Drawing.Point(275,220)
$editButton.Size = New-Object System.Drawing.Size(75,23)
$editButton.Text = "Edit"
$form.Controls.Add($editButton)

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Location = New-Object System.Drawing.Point(355,220)
$removeButton.Size = New-Object System.Drawing.Size(75,23)
$removeButton.Text = "Remove"
$form.Controls.Add($removeButton)

$searchButton = New-Object System.Windows.Forms.Button
$searchButton.Location = New-Object System.Drawing.Point(435,220)
$searchButton.Size = New-Object System.Drawing.Size(100,23)
$searchButton.Text = "Search Winget"
$form.Controls.Add($searchButton)

$runButton = New-Object System.Windows.Forms.Button
$runButton.Location = New-Object System.Drawing.Point(695,220)
$runButton.Size = New-Object System.Drawing.Size(75,23)
$runButton.Text = "Run"
$form.Controls.Add($runButton)

# Create log text area
$logTextBox = New-Object System.Windows.Forms.TextBox
$logTextBox.Location = New-Object System.Drawing.Point(10,250)
$logTextBox.Size = New-Object System.Drawing.Size(760,300)
$logTextBox.Multiline = $true
$logTextBox.ScrollBars = "Vertical"
$form.Controls.Add($logTextBox)

# Initialize config structure
$script:config = @{
    Apps = @()
    Credentials = @{
        TenantID = ""
        ClientID = ""
        ClientSecret = ""
        AppID = ""
    }
}

# Load existing config if it exists
$configPath = Join-Path -Path $scriptDirectory -ChildPath "config.json"
if (Test-Path $configPath) {
    $loadedConfig = Get-Content -Path $configPath | ConvertFrom-Json
    if ($loadedConfig.Apps) {
        $script:config.Apps = $loadedConfig.Apps
    }
    if ($loadedConfig.Credentials) {
        $script:config.Credentials = $loadedConfig.Credentials
    }
}

# Function to load apps from config
function Load-Apps {
    $listView.Items.Clear()
    
    # Try to get the script path
    if ($PSScriptRoot) {
        $scriptRoot = $PSScriptRoot
    } elseif ($psISE) {
        $scriptRoot = Split-Path -Parent $psISE.CurrentFile.FullPath
    } else {
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    
    # If we still don't have a valid path, use the current directory
    if (-not $scriptRoot) {
        $scriptRoot = Get-Location
    }
    
    $configPath = Join-Path -Path $scriptRoot -ChildPath "config.json"
    
    if (Test-Path $configPath) {
        try {
            $loadedConfig = Get-Content -Path $configPath | ConvertFrom-Json
            
            # Initialize the config structure if loading from an older version
            if (-not $script:config) {
                $script:config = @{
                    Apps = @()
                    Credentials = @{
                        TenantID = ""
                        ClientID = ""
                        ClientSecret = ""
                        AppId = ""
                    }
                }
            }
            
            # Copy apps from loaded config
            if ($loadedConfig.Apps) {
                $script:config.Apps = $loadedConfig.Apps
            }
            
            # Copy credentials if they exist
            if ($loadedConfig.Credentials) {
                $script:config.Credentials = $loadedConfig.Credentials
            }
            
            foreach ($app in $script:config.Apps) {
                if ($null -eq $app) { continue }
                if (-not $app.DisplayName -or -not $app.WingetId -or -not $app.Publisher) { continue }
                $item = New-Object System.Windows.Forms.ListViewItem($app.DisplayName)
                $item.SubItems.Add($app.WingetId)
                $item.SubItems.Add($app.Publisher)
                $listView.Items.Add($item)
            }

            Log-Message "Loaded apps from config file successfully."
        } catch {
            Log-Message "Error loading config file: $_" "ERROR"
        }
    } else {
        Log-Message "Config file not found at $configPath" "ERROR"
    }
}

# Function to add a new app
function Add-App {
    $addForm = New-Object System.Windows.Forms.Form
    $addForm.Text = "Add New App"
    $addForm.Size = New-Object System.Drawing.Size(300,250)
    $addForm.StartPosition = "CenterScreen"

    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Location = New-Object System.Drawing.Point(10,20)
    $nameLabel.Size = New-Object System.Drawing.Size(100,20)
    $nameLabel.Text = "Display Name:"
    $addForm.Controls.Add($nameLabel)

    $nameTextBox = New-Object System.Windows.Forms.TextBox
    $nameTextBox.Location = New-Object System.Drawing.Point(120,20)
    $nameTextBox.Size = New-Object System.Drawing.Size(150,20)
    $addForm.Controls.Add($nameTextBox)

    $wingetLabel = New-Object System.Windows.Forms.Label
    $wingetLabel.Location = New-Object System.Drawing.Point(10,50)
    $wingetLabel.Size = New-Object System.Drawing.Size(100,20)
    $wingetLabel.Text = "Winget ID:"
    $addForm.Controls.Add($wingetLabel)

    $wingetTextBox = New-Object System.Windows.Forms.TextBox
    $wingetTextBox.Location = New-Object System.Drawing.Point(120,50)
    $wingetTextBox.Size = New-Object System.Drawing.Size(150,20)
    $addForm.Controls.Add($wingetTextBox)

    $publisherLabel = New-Object System.Windows.Forms.Label
    $publisherLabel.Location = New-Object System.Drawing.Point(10,80)
    $publisherLabel.Size = New-Object System.Drawing.Size(100,20)
    $publisherLabel.Text = "Publisher:"
    $addForm.Controls.Add($publisherLabel)

    $publisherTextBox = New-Object System.Windows.Forms.TextBox
    $publisherTextBox.Location = New-Object System.Drawing.Point(120,80)
    $publisherTextBox.Size = New-Object System.Drawing.Size(150,20)
    $addForm.Controls.Add($publisherTextBox)

    $descriptionLabel = New-Object System.Windows.Forms.Label
    $descriptionLabel.Location = New-Object System.Drawing.Point(10,110)
    $descriptionLabel.Size = New-Object System.Drawing.Size(100,20)
    $descriptionLabel.Text = "Description:"
    $addForm.Controls.Add($descriptionLabel)

    $descriptionTextBox = New-Object System.Windows.Forms.TextBox
    $descriptionTextBox.Location = New-Object System.Drawing.Point(120,110)
    $descriptionTextBox.Size = New-Object System.Drawing.Size(150,60)
    $descriptionTextBox.Multiline = $true
    $addForm.Controls.Add($descriptionTextBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(120,180)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $addForm.Controls.Add($okButton)

    $addForm.AcceptButton = $okButton

    $result = $addForm.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        # Try to get the script path
        if ($PSScriptRoot) {
            $scriptRoot = $PSScriptRoot
        } elseif ($psISE) {
            $scriptRoot = Split-Path -Parent $psISE.CurrentFile.FullPath
        } else {
            $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
        }
        
        # If we still don't have a valid path, use the current directory
        if (-not $scriptRoot) {
            $scriptRoot = Get-Location
        }
        
        $configPath = Join-Path -Path $scriptRoot -ChildPath "config.json"
        
        if (Test-Path $configPath) {
            $config = Get-Content -Path $configPath | ConvertFrom-Json
        } else {
            $config = @{
                Apps = @()
            }
        }

        # Create a safe file name by replacing spaces with underscores
        $safeFileName = $nameTextBox.Text -replace '\s', '_'
        $packageId = $wingetTextBox.Text

        # Generate install and uninstall commands using the safe file name
        $installCommand = "%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe -Executionpolicy Bypass -file .\$safeFileName.ps1 -mode install -log `"$packageId.log`""
        $uninstallCommand = "%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe -Executionpolicy Bypass -file .\${safeFileName}_uninstall.ps1"

        $newApp = @{
            DisplayName = $nameTextBox.Text
            WingetId = $wingetTextBox.Text
            Publisher = $publisherTextBox.Text
            Description = $descriptionTextBox.Text
            InstallCommand = $installCommand
            UninstallCommand = $uninstallCommand
        }

        if (-not $config.Apps) {
            $config | Add-Member -NotePropertyName Apps -NotePropertyValue @()
        }

        $config.Apps = @($config.Apps) + $newApp
        $config | ConvertTo-Json | Set-Content -Path $configPath
        Load-Apps
        Log-Message "Added new app: $($nameTextBox.Text)"
    }
}

# Function to remove selected apps
function Remove-App {
    $selectedItems = $listView.SelectedItems
    if ($selectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select at least one app to remove.", 
            "No Selection", 
            [System.Windows.Forms.MessageBoxButtons]::OK, 
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $appNames = $selectedItems | ForEach-Object { $_.Text }
    $message = "Are you sure you want to remove the following apps?`n`n" + ($appNames -join "`n")
    
    $result = [System.Windows.Forms.MessageBox]::Show(
        $message,
        "Confirm Removal",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question)
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            # Remove each selected app from config
            foreach ($appName in $appNames) {
                $config.Apps = @($config.Apps | Where-Object { $_.DisplayName -ne $appName })
                Log-Message "Removed app: $appName"
            }
            
            # Save the updated config
            Save-Config
            
            # Clear and reload the ListView
            $listView.Items.Clear()
            
            # Only reload items if there are apps in the config
            if ($config.Apps -and $config.Apps.Count -gt 0) {
                foreach ($app in $config.Apps) {
                    $item = New-Object System.Windows.Forms.ListViewItem($app.DisplayName)
                    $item.SubItems.Add($app.WingetId)
                    $item.SubItems.Add($app.Publisher)
                    $listView.Items.Add($item)
                }
            }
            
            Log-Message "Successfully removed $(($appNames).Count) app(s)"
        }
        catch {
            Log-Message "Error removing apps: $($_.Exception.Message)" "ERROR"
        }
    }
}

function Update-WingetSilently {
    try {
        Log-Message "Checking current winget version..."
        $wingetVersion = ""
        try { 
            $wingetVersion = winget --version 2>$null
            # Remove any leading 'v' or whitespace
            $wingetVersion = $wingetVersion -replace '^[vV]', '' -replace '\s',''
        } catch {}

        # Get latest version from GitHub API
        $latestWingetVersion = ""
        try {
            $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest" -UseBasicParsing
            $latestWingetVersion = $releaseInfo.tag_name -replace '^[vV]', '' -replace '\s',''
            Log-Message "Latest winget version available: $latestWingetVersion"
        } catch {
            Log-Message "Could not retrieve latest winget version from GitHub. Skipping version check." "WARNING"
            return
        }

        if ($wingetVersion -and $latestWingetVersion -and ([version]$wingetVersion -ge [version]$latestWingetVersion)) {
            Log-Message "winget is up to date (version $wingetVersion)."
            return
        } else {
            Log-Message "winget is outdated or not found (current: $wingetVersion, latest: $latestWingetVersion). Updating..."
        }

        # Download latest App Installer bundle
        $installerUrl = "https://aka.ms/getwinget"
        $localPath = "$env:TEMP\AppInstaller.msixbundle"
        Invoke-WebRequest -Uri $installerUrl -OutFile $localPath -UseBasicParsing

        # Install the bundle (works for current user, admin not required for user context)
        Add-AppxPackage -Path $localPath -ForceApplicationShutdown

        # Optionally, clean up installer
        Remove-Item $localPath -Force -ErrorAction SilentlyContinue

        # Re-check version after update
        try {
            $wingetVersion = winget --version 2>$null
            $wingetVersion = $wingetVersion -replace '^[vV]', '' -replace '\s',''
            Log-Message "winget updated to version $wingetVersion."
        } catch {
            Log-Message "winget not found after update attempt." "ERROR"
        }
    } catch {
        Log-Message "Automatic winget update failed: $($_.Exception.Message)" "WARNING"
    }
}
function Remove-StoredCredentials {
    try {
        Log-Message "Starting credential removal process..."
        
        # Log current state (without showing sensitive data)
        $hasCredentials = -not [string]::IsNullOrEmpty($script:config.Credentials.TenantID)
        Log-Message "Current credentials exist: $hasCredentials"
        
        # Clear credentials from memory
        Log-Message "Clearing credentials from memory..."
        $script:config.Credentials.TenantID = ""
        $script:config.Credentials.ClientID = ""
        $script:config.Credentials.ClientSecret = ""
        $script:config.Credentials.AppId = ""
        Log-Message "Credentials cleared from memory"

        # Save the updated config to file
        $configPath = Join-Path -Path $scriptDirectory -ChildPath "config.json"
        Log-Message "Saving updated config to: $configPath"
        
        try {
            $script:config | ConvertTo-Json | Set-Content -Path $configPath
            Log-Message "Config file updated successfully"
        }
        catch {
            Log-Message "Error saving config file: $($_.Exception.Message)" "ERROR"
            throw
        }

        Log-Message "Credential removal completed successfully"
    }
    catch {
        Log-Message "Error removing credentials: $($_.Exception.Message)" "ERROR"
    }
}

function Remove-GraphCredentials {
    try {
        Log-Message "Starting Graph credential removal process..."
        
        # Check for active Graph connection and disconnect
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if ($context) {
            Disconnect-MgGraph -ErrorAction SilentlyContinue
            Log-Message "Successfully disconnected from Graph API"
        }

        # Clear token cache
        $tokenCachePath = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Microsoft", "PowerShell", "TokenCache")
        if (Test-Path $tokenCachePath) {
            Remove-Item -Path $tokenCachePath -Force -Recurse -ErrorAction SilentlyContinue
            Log-Message "Token cache cleared"
        }

        # Remove stored Graph credentials from Windows Credential Manager
        $graphCreds = cmdkey /list | Where-Object { $_ -like "*Microsoft Graph PowerShell*" }
        if ($graphCreds) {
            $graphCreds | ForEach-Object {
                if ($_ -match "Target: (.+)") {
                    cmdkey /delete:$($matches[1])
                }
            }
            Log-Message "Removed Graph credentials from Windows Credential Manager"
        }

        # Clear module cache
        $moduleCachePath = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Microsoft", "PowerShell", "ModuleCache")
        if (Test-Path $moduleCachePath) {
            Remove-Item -Path $moduleCachePath -Force -Recurse -ErrorAction SilentlyContinue
            Log-Message "Module cache cleared"
        }
    }
    catch {
        Log-Message "Error during Graph credential removal: $($_.Exception.Message)" "ERROR"
    }
}

# Add required modules array
$script:requiredModules = @(
    'Microsoft.Graph.Applications',
    'Microsoft.Graph.Identity.DirectoryManagement',
    'IntuneWin32App',
    'Microsoft.WinGet.Client'
)

function Initialize-GraphConnection {
    try {
        Log-Message "Initializing Graph connection..."
        
        # Check if we have credentials in config
        if (-not $script:config.Credentials -or 
            [string]::IsNullOrEmpty($script:config.Credentials.TenantID) -or
            [string]::IsNullOrEmpty($script:config.Credentials.ClientID) -or
            [string]::IsNullOrEmpty($script:config.Credentials.ClientSecret)) {
            Log-Message "No credentials found in config. Please register the application first."
            return $false
        }

        # Check current connection state
        $graphContext = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $graphContext) {
            Log-Message "No active Graph connection. Connecting..."
            
            # Connect to Microsoft Graph
            Connect-MgGraph -TenantId $script:config.Credentials.TenantID -ClientId $script:config.Credentials.ClientID -ClientSecret $script:config.Credentials.ClientSecret -ErrorAction Stop
            
            # Connect to Intune Graph
            Connect-MSIntuneGraph -TenantID $script:config.Credentials.TenantID `
                                -ClientID $script:config.Credentials.ClientID `
                                -ClientSecret $script:config.Credentials.ClientSecret `
                                -ErrorAction Stop
            
            Log-Message "Successfully connected to Graph APIs"
        } else {
            Log-Message "Using existing Graph connection"
        }
        
        return $true
    }
    catch {
        Log-Message "Failed to initialize Graph connection: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Initialize-RequiredModules {
    try {
        Log-Message "Starting initialization of required modules..."
        
        # Check and install NuGet provider first
        $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        $minimumVersion = [version]"2.8.5.201"

        if (-not $nugetProvider -or $nugetProvider.Version -lt $minimumVersion) {
            Log-Message "Installing NuGet provider..."
            # Add -Confirm:$false to suppress the prompt
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -Confirm:$false | Out-Null
            Log-Message "NuGet provider installed successfully"
        }
        
        foreach ($module in $script:requiredModules) {
            Log-Message "Processing module: $module"
            
            # Check if module is already loaded with correct version
            $loadedModule = Get-Module -Name $module -ErrorAction SilentlyContinue
            
            if ($loadedModule) {
                Log-Message "Module $module is already loaded (Version: $($loadedModule.Version))"
                continue
            }
            
            # Check if module is installed
            $installedModule = Get-Module -ListAvailable -Name $module | Sort-Object Version -Descending | Select-Object -First 1
            
            if (-not $installedModule) {
                Log-Message "Installing module: $module"
                Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                Log-Message "Successfully installed $module"
            }
            
            # Import module
            try {
                Log-Message "Importing module: $module"
                Import-Module -Name $module -ErrorAction Stop
                Log-Message "Successfully imported $module"
            }
            catch {
                if ($_.Exception.Message -match "Assembly with same name is already loaded") {
                    Log-Message "Module $module is already loaded (Assembly)" "WARNING"
                    continue
                }
                throw
            }
        }
        
        Log-Message "All required modules initialized successfully"
        return $true
    }
    catch {
        Log-Message "Failed to initialize required modules: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to initialize required modules: $($_.Exception.Message)",
            "Module Initialization Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
}

function Remove-AllCredentials {
    try {
        # Remove Azure AD App
        Remove-AzureADApp
        Log-Message "Azure AD App removed successfully"

        # Remove stored credentials
        Remove-StoredCredentials
        Log-Message "Stored credentials removed successfully"

        # Reset the configuration with correct structure
        $existingApps = $script:config.Apps
        $script:config = @{
            Apps = $existingApps
            Credentials = @{
                TenantID = ""
                ClientID = ""
                ClientSecret = ""
                AppId = ""
            }
        }
        
        # Save the updated config
        $configPath = Join-Path -Path $scriptDirectory -ChildPath "config.json"
        $script:config | ConvertTo-Json | Set-Content -Path $configPath
        Log-Message "Configuration reset with empty credentials"

        # Clear script-level variables
        $script:graphToken = $null
        $script:connected = $false
        
        Load-Apps  # Reload the apps in the ListView
        
        [System.Windows.Forms.MessageBox]::Show(
            "All credentials have been removed successfully.",
            "Credentials Removed",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        Log-Message "Error removing credentials: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show(
            "An error occurred while removing credentials: $($_.Exception.Message)",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}
# Function to edit a selected app
function Edit-App {
    $selectedItems = $listView.SelectedItems
    if ($selectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select an app to edit.", "No Selection", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $selectedApp = $selectedItems[0]
    $appName = $selectedApp.Text

    $editForm = New-Object System.Windows.Forms.Form
    $editForm.Text = "Edit App"
    $editForm.Size = New-Object System.Drawing.Size(300,250)
    $editForm.StartPosition = "CenterScreen"

    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Location = New-Object System.Drawing.Point(10,20)
    $nameLabel.Size = New-Object System.Drawing.Size(100,20)
    $nameLabel.Text = "Display Name:"
    $editForm.Controls.Add($nameLabel)

    $nameTextBox = New-Object System.Windows.Forms.TextBox
    $nameTextBox.Location = New-Object System.Drawing.Point(120,20)
    $nameTextBox.Size = New-Object System.Drawing.Size(150,20)
    $nameTextBox.Text = $selectedApp.SubItems[0].Text
    $editForm.Controls.Add($nameTextBox)

    $wingetLabel = New-Object System.Windows.Forms.Label
    $wingetLabel.Location = New-Object System.Drawing.Point(10,50)
    $wingetLabel.Size = New-Object System.Drawing.Size(100,20)
    $wingetLabel.Text = "Winget ID:"
    $editForm.Controls.Add($wingetLabel)

    $wingetTextBox = New-Object System.Windows.Forms.TextBox
    $wingetTextBox.Location = New-Object System.Drawing.Point(120,50)
    $wingetTextBox.Size = New-Object System.Drawing.Size(150,20)
    $wingetTextBox.Text = $selectedApp.SubItems[1].Text
    $editForm.Controls.Add($wingetTextBox)

    $publisherLabel = New-Object System.Windows.Forms.Label
    $publisherLabel.Location = New-Object System.Drawing.Point(10,80)
    $publisherLabel.Size = New-Object System.Drawing.Size(100,20)
    $publisherLabel.Text = "Publisher:"
    $editForm.Controls.Add($publisherLabel)

    $publisherTextBox = New-Object System.Windows.Forms.TextBox
    $publisherTextBox.Location = New-Object System.Drawing.Point(120,80)
    $publisherTextBox.Size = New-Object System.Drawing.Size(150,20)
    $publisherTextBox.Text = $selectedApp.SubItems[2].Text
    $editForm.Controls.Add($publisherTextBox)

    $descriptionLabel = New-Object System.Windows.Forms.Label
    $descriptionLabel.Location = New-Object System.Drawing.Point(10,110)
    $descriptionLabel.Size = New-Object System.Drawing.Size(100,20)
    $descriptionLabel.Text = "Description:"
    $editForm.Controls.Add($descriptionLabel)

    $descriptionTextBox = New-Object System.Windows.Forms.TextBox
    $descriptionTextBox.Location = New-Object System.Drawing.Point(120,110)
    $descriptionTextBox.Size = New-Object System.Drawing.Size(150,60)
    $descriptionTextBox.Multiline = $true
    $descriptionTextBox.Text = $script:config.Apps | Where-Object { $_.DisplayName -eq $appName } | Select-Object -ExpandProperty Description
    $editForm.Controls.Add($descriptionTextBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(120,180)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $editForm.Controls.Add($okButton)

    $editForm.AcceptButton = $okButton

    $result = $editForm.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        # Try to get the script path
        if ($PSScriptRoot) {
            $scriptRoot = $PSScriptRoot
        } elseif ($psISE) {
            $scriptRoot = Split-Path -Parent $psISE.CurrentFile.FullPath
        } else {
            $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
        }
        
        # If we still don't have a valid path, use the current directory
        if (-not $scriptRoot) {
            $scriptRoot = Get-Location
        }
        
        $configPath = Join-Path -Path $scriptRoot -ChildPath "config.json"
        
        if (Test-Path $configPath) {
            $config = Get-Content -Path $configPath | ConvertFrom-Json
            $appToEdit = $config.Apps | Where-Object { $_.DisplayName -eq $appName }
            
            if ($appToEdit) {
                $appToEdit.DisplayName = $nameTextBox.Text
                $appToEdit.WingetId = $wingetTextBox.Text
                $appToEdit.Publisher = $publisherTextBox.Text
                $appToEdit.Description = $descriptionTextBox.Text
                
                # Update install and uninstall commands if the name has changed
                if ($appToEdit.DisplayName -ne $appName) {
                    $safeFileName = $nameTextBox.Text -replace '\s', '_'
                    $appToEdit.InstallCommand = "%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe -Executionpolicy Bypass -file .\$safeFileName.ps1 -mode install -log `"$packageId.log`""
                    $appToEdit.UninstallCommand = "%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe -Executionpolicy Bypass -file .\${safeFileName}_uninstall.ps1"
                }
                
                $config | ConvertTo-Json | Set-Content -Path $configPath
                Load-Apps
                Log-Message "Updated app: $($nameTextBox.Text)"
            } else {
                Log-Message "App not found in config. Unable to edit." "ERROR"
            }
        } else {
            Log-Message "Config file not found. Unable to edit app." "ERROR"
        }
    }
}

function Show-AssignmentSelectionDialog {
    # Returns a hashtable: 
    # @{ AllDevices = $true/$false; AllDevicesRequired = $true/$false; AllUsers = $true/$false; AllUsersRequired = $true/$false; NoAssignment = $true/$false }
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Assignment Selection"
    $form.Size = New-Object System.Drawing.Size(420,270)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $font = New-Object System.Drawing.Font("Segoe UI", 11)

    # All Devices
    $allDevicesCheck = New-Object System.Windows.Forms.CheckBox
    $allDevicesCheck.Text = "Assign All Devices"
    $allDevicesCheck.Location = New-Object System.Drawing.Point(30,30)
    $allDevicesCheck.Size = New-Object System.Drawing.Size(180,30)
    $allDevicesCheck.Font = $font
    $form.Controls.Add($allDevicesCheck)

    $allDevicesRequiredCheck = New-Object System.Windows.Forms.CheckBox
    $allDevicesRequiredCheck.Text = "Required"
    $allDevicesRequiredCheck.Checked = $true
    $allDevicesRequiredCheck.Location = New-Object System.Drawing.Point(230,30)
    $allDevicesRequiredCheck.Size = New-Object System.Drawing.Size(120,30)
    $allDevicesRequiredCheck.Font = $font
    $allDevicesRequiredCheck.Enabled = $false
    $form.Controls.Add($allDevicesRequiredCheck)

    # All Users
    $allUsersCheck = New-Object System.Windows.Forms.CheckBox
    $allUsersCheck.Text = "Assign All Users"
    $allUsersCheck.Location = New-Object System.Drawing.Point(30,70)
    $allUsersCheck.Size = New-Object System.Drawing.Size(180,30)
    $allUsersCheck.Font = $font
    $form.Controls.Add($allUsersCheck)

    $allUsersRequiredCheck = New-Object System.Windows.Forms.CheckBox
    $allUsersRequiredCheck.Text = "Required"
    $allUsersRequiredCheck.Checked = $true
    $allUsersRequiredCheck.Location = New-Object System.Drawing.Point(230,70)
    $allUsersRequiredCheck.Size = New-Object System.Drawing.Size(120,30)
    $allUsersRequiredCheck.Font = $font
    $allUsersRequiredCheck.Enabled = $false
    $form.Controls.Add($allUsersRequiredCheck)

    # No Assignment
    $noAssignmentCheck = New-Object System.Windows.Forms.CheckBox
    $noAssignmentCheck.Text = "No Assignment"
    $noAssignmentCheck.Location = New-Object System.Drawing.Point(30,120)
    $noAssignmentCheck.Size = New-Object System.Drawing.Size(250,30)
    $noAssignmentCheck.Font = $font
    $form.Controls.Add($noAssignmentCheck)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(150,180)
    $okButton.Size = New-Object System.Drawing.Size(100,32)
    $form.Controls.Add($okButton)

    # Enable/disable required checkboxes based on assignment selection
    $allDevicesCheck.Add_CheckedChanged({
        $allDevicesRequiredCheck.Enabled = $allDevicesCheck.Checked
        if ($allDevicesCheck.Checked -or $allUsersCheck.Checked) {
            $noAssignmentCheck.Checked = $false
            $noAssignmentCheck.Enabled = $false
        } else {
            $noAssignmentCheck.Enabled = $true
        }
    })
    $allUsersCheck.Add_CheckedChanged({
        $allUsersRequiredCheck.Enabled = $allUsersCheck.Checked
        if ($allDevicesCheck.Checked -or $allUsersCheck.Checked) {
            $noAssignmentCheck.Checked = $false
            $noAssignmentCheck.Enabled = $false
        } else {
            $noAssignmentCheck.Enabled = $true
        }
    })
    $noAssignmentCheck.Add_CheckedChanged({
        if ($noAssignmentCheck.Checked) {
            $allDevicesCheck.Checked = $false
            $allUsersCheck.Checked = $false
        }
    })

    $assignmentChoice = @{
        AllDevices = $false
        AllDevicesRequired = $true
        AllUsers = $false
        AllUsersRequired = $true
        NoAssignment = $false
    }

    $okButton.Add_Click({
        $assignmentChoice.AllDevices = $allDevicesCheck.Checked
        $assignmentChoice.AllDevicesRequired = $allDevicesRequiredCheck.Checked
        $assignmentChoice.AllUsers = $allUsersCheck.Checked
        $assignmentChoice.AllUsersRequired = $allUsersRequiredCheck.Checked
        $assignmentChoice.NoAssignment = $noAssignmentCheck.Checked
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })

    $form.AcceptButton = $okButton
    $result = $form.ShowDialog()

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }
    return $assignmentChoice
}

# Define cleanup function
function Cleanup-TempFiles {
    param (
        [string]$TempDir
    )
    try {
        Get-ChildItem -Path $TempDir -File | ForEach-Object {
            Remove-Item -Path $_.FullName -Force -ErrorAction Stop
            Log-Message "Removed temporary file: $($_.FullName)"
        }
        Remove-Item -Path $TempDir -Force -Recurse -ErrorAction Stop
        Log-Message "Removed temporary directory: $TempDir"
    } catch {
        Log-Message "Error during cleanup" "ERROR" $_
    }
}

function Register-IntuneApp {
    try {
        Log-Message "Starting app registration process..."
        
        # Connect to Microsoft Graph with required permissions
        Log-Message "Connecting to Microsoft Graph..."
        $graphScopes = @(
            'Application.ReadWrite.All',
            'Directory.ReadWrite.All',
            'AppRoleAssignment.ReadWrite.All',
            'RoleAssignmentSchedule.ReadWrite.Directory',
            'Domain.Read.All',
            'Domain.ReadWrite.All',
            'Directory.Read.All',
            'Policy.ReadWrite.ConditionalAccess',
            'DeviceManagementApps.ReadWrite.All',
            'DeviceManagementConfiguration.ReadWrite.All',
            'DeviceManagementManagedDevices.ReadWrite.All'
        )
        Connect-MgGraph -Scopes $graphScopes | Out-Null

        # Create Azure AD Application
        $appName = "Winget-Intune-App-Deployment"
        Log-Message "Creating Azure AD Application: $appName"

        # Define Microsoft Graph permissions
        $msGraphSpn = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
        
        $requiredResourceAccess = @(
            @{
                ResourceAppId = $msGraphSpn.AppId
                ResourceAccess = @(
                    @{
                        Id = ($msGraphSpn.AppRoles | Where-Object { $_.Value -eq "DeviceManagementApps.ReadWrite.All" }).Id
                        Type = "Role"
                    }
                    @{
                        Id = ($msGraphSpn.AppRoles | Where-Object { $_.Value -eq "DeviceManagementConfiguration.ReadWrite.All" }).Id
                        Type = "Role"
                    }
                    @{
                        Id = ($msGraphSpn.AppRoles | Where-Object { $_.Value -eq "DeviceManagementManagedDevices.ReadWrite.All" }).Id
                        Type = "Role"
                    }
                    @{
                        Id = ($msGraphSpn.AppRoles | Where-Object { $_.Value -eq "Directory.Read.All" }).Id
                        Type = "Role"
                    }
                    @{
                        Id = ($msGraphSpn.AppRoles | Where-Object { $_.Value -eq "Group.ReadWrite.All" }).Id
                        Type = "Role"
                    }
                    @{
                        Id = ($msGraphSpn.AppRoles | Where-Object { $_.Value -eq "DeviceManagementRBAC.Read.All" }).Id
                        Type = "Role"
                    }
                    @{
                        Id = ($msGraphSpn.AppRoles | Where-Object { $_.Value -eq "DeviceManagementRBAC.ReadWrite.All" }).Id
                        Type = "Role"
                    }
                    @{
                        Id = ($msGraphSpn.AppRoles | Where-Object { $_.Value -eq "Application.ReadWrite.All" }).Id
                        Type = "Role"
                    }
                )
            }
        )

        # Create the application
        $params = @{
            DisplayName = $appName
            SignInAudience = "AzureADMyOrg"
            RequiredResourceAccess = $requiredResourceAccess
            Web = @{
                RedirectUris = @("https://login.microsoftonline.com/common/oauth2/nativeclient")
            }
        }

        $app = New-MgApplication @params
        Log-Message "Created Azure AD Application"

        # Create service principal
        Log-Message "Creating service principal..."
        $sp = New-MgServicePrincipal -AppId $app.AppId
        Log-Message "Created service principal"

        # Create client secret
        Log-Message "Creating client secret..."
        $secretEndDate = (Get-Date).AddYears(2)
        $passwordCred = @{
            displayName = "WinGet Deployment Secret"
            endDateTime = $secretEndDate
        }
        $secret = Add-MgApplicationPassword -ApplicationId $app.Id -PasswordCredential $passwordCred

        # Get tenant details
        $org = Get-MgOrganization
        $tenantId = $org.Id

        # Automatically grant admin consent
        Log-Message "Granting admin consent for application permissions..."
        foreach ($resource in $requiredResourceAccess) {
            foreach ($permission in $resource.ResourceAccess) {
                if ($permission.Type -eq "Role") {
                    try {
                        $appRole = $msGraphSpn.AppRoles | Where-Object { $_.Id -eq $permission.Id }
                        
                        $appRoleAssignment = @{
                            PrincipalId = $sp.Id
                            ResourceId = $msGraphSpn.Id
                            AppRoleId = $permission.Id
                        }

                        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -BodyParameter $appRoleAssignment
                        Log-Message "Granted consent for $($appRole.Value)"
                    }
                    catch {
                        Log-Message "Error granting consent for role: $($appRole.Value)" "ERROR" $_
                    }
                }
            }
        }

        # Store the values in config
        if (-not $script:config) {
            $script:config = @{
                Apps = @()
                Credentials = @{
                    TenantID = ""
                    ClientID = ""
                    ClientSecret = ""
                    AppId = ""
                }
            }
        }

        $script:config.Credentials.TenantID = $tenantId
        $script:config.Credentials.ClientID = $app.AppId
        $script:config.Credentials.ClientSecret = $secret.SecretText
        $script:config.Credentials.AppId = $app.Id

        # Save to config file
        $configPath = Join-Path -Path $scriptDirectory -ChildPath "config.json"
        $script:config | ConvertTo-Json | Set-Content -Path $configPath
        Log-Message "Saved credentials to config file"

        # Show success message
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            "Application registered successfully!",
            "Registration Complete",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)

    }
    catch {
        Log-Message "Error during application registration: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show(
            "Error during application registration: $($_.Exception.Message)",
            "Registration Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}


function Remove-AzureADApp {
    try {
        Log-Message "Starting Azure AD app removal process..."
        
        # Check if we have the app ID in the config
        if (-not $script:config.Credentials.AppId) {
            Log-Message "No App ID found in config, skipping app removal"
            return
        }

        Log-Message "Found App ID: $($script:config.Credentials.AppId)"

        # Connect to Microsoft Graph with required scope
        Log-Message "Connecting to Microsoft Graph..."
        Connect-MgGraph -Scopes "Application.ReadWrite.All" | Out-Null
        Log-Message "Successfully connected to Microsoft Graph"

        # Remove the application
        try {
            Log-Message "Attempting to remove Azure AD application..."
            Remove-MgApplication -ApplicationId $script:config.Credentials.AppId -ErrorAction Stop
            Log-Message "Successfully removed Azure AD application"
        } catch {
            if ($_.Exception.Message -match 'Request_ResourceNotFound') {
                Log-Message "Application not found, may have been already removed"
            } else {
                Log-Message "Error removing Azure AD application: $($_.Exception.Message)" "ERROR"
                throw
            }
        }
    } catch {
        Log-Message "Critical error removing Azure AD application: $($_.Exception.Message)" "ERROR"
    }
}

# Main script function
function Run-MainScript {
    try {
        # Ensure Graph connection is established
        if (-not (Initialize-GraphConnection)) {
            throw "Failed to establish Graph connection"
        }
        
        # Explicitly connect to Intune Graph with stored credentials
        try {
            Connect-MSIntuneGraph -TenantID $script:config.Credentials.TenantID `
                                -ClientID $script:config.Credentials.ClientID `
                                -ClientSecret $script:config.Credentials.ClientSecret `
                                -ErrorAction Stop
            Log-Message "Connected to Intune Graph API successfully"
        }
        catch {
            throw "Failed to connect to Intune Graph API: $($_.Exception.Message)"
        }

        # Start transcript logging
        $transcriptFileName = "MainScript_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $transcriptPath = Join-Path -Path $LogDirectory -ChildPath $transcriptFileName
        Start-Transcript -Path $transcriptPath
        Log-Message "Started transcript logging to: $transcriptPath"

        # Load config if it exists
        $configPath = Join-Path -Path $scriptDirectory -ChildPath "config.json"
        if (Test-Path $configPath) {
            Log-Message "Loading existing configuration from: $configPath"
            $loadedConfig = Get-Content -Path $configPath | ConvertFrom-Json
            
            # Convert PSCustomObject to hashtable for credentials
            $script:config.Credentials = @{
                TenantID = $loadedConfig.Credentials.TenantID
                ClientID = $loadedConfig.Credentials.ClientID
                ClientSecret = $loadedConfig.Credentials.ClientSecret
                AppId = $loadedConfig.Credentials.AppId
            }
            Log-Message "Configuration loaded successfully"
        } else {
            Log-Message "No existing configuration found at: $configPath"
        }

        # Show the new assignment selection dialog
        $assignmentChoice = Show-AssignmentSelectionDialog
        if (-not $assignmentChoice) {
            Log-Message "Assignment selection cancelled by user."
            return
        }
        Log-Message "User selected assignment: AllDevices=$($assignmentChoice.AllDevices), AllUsers=$($assignmentChoice.AllUsers), NoAssignment=$($assignmentChoice.NoAssignment)"

        # Validate credentials
        if ([string]::IsNullOrWhiteSpace($script:config.Credentials.TenantID) -or 
            [string]::IsNullOrWhiteSpace($script:config.Credentials.ClientID) -or 
            [string]::IsNullOrWhiteSpace($script:config.Credentials.ClientSecret)) {
            
            [System.Windows.Forms.MessageBox]::Show(
                "Please register the application first using the 'App Reg' button.",
                "Missing Credentials",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        # Process apps
        $selectedItems = $listView.SelectedItems
        if ($selectedItems.Count -eq 0) {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "No apps selected. Do you want to process all apps?",
                "Confirm Action",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question)
            
            if ($result -eq [System.Windows.Forms.DialogResult]::No) {
                Log-Message "Operation cancelled. No apps processed."
                return
            }
            $appsToProcess = $script:config.Apps
        } else {
            $appsToProcess = $selectedItems | ForEach-Object {
                $displayName = $_.Text
                $script:config.Apps | Where-Object { $_.DisplayName -eq $displayName }
            }
        }

        $totalApps = $appsToProcess.Count
        if ($totalApps -eq 0) {
            Log-Message "No apps to process. Please add apps before running."
            return
        }

        try {
            # Ensure C:\IntunePackages exists
            if (-not (Test-Path -Path $TempDir)) {
                New-Item -Path $TempDir -ItemType Directory -ErrorAction Stop | Out-Null
                Log-Message "Created C:\IntunePackages directory."
            } else {
                Log-Message "C:\IntunePackages directory already exists."
            }

            # Download IntuneWinAppUtil.exe if it doesn't exist
            if (-not (Test-Path $IntuneWinAppUtilPath)) {
                Invoke-WebRequest -Uri $IntuneWinAppUtilUrl -OutFile $IntuneWinAppUtilPath -ErrorAction Stop
                Log-Message "Downloaded IntuneWinAppUtil.exe successfully."
            } else {
                Log-Message "IntuneWinAppUtil.exe already exists."
            }

            # Process each application
            foreach ($app in $appsToProcess) {
                try {
                    Log-Message "Starting process for $($app.DisplayName)"
                    
                    # Create a safe file name by replacing spaces with underscores
                    $safeFileName = $app.DisplayName -replace '\s', '_'

                    # Create Winget install script
                    $wingetInstallScriptPath = Join-Path -Path $TempDir -ChildPath "$safeFileName.ps1"
                    $wingetInstallScriptContent = @"
# Define the Winget Package Name
`$PackageName = '$($app.WingetId)'

function Write-Log(`$message) {
    `$LogMessage = ((Get-Date -Format "MM-dd-yy HH:MM:ss ") + `$message)
    `$LogPath = "`$env:programdata\Microsoft\IntuneManagementExtension\Logs"
    if (-not (Test-Path `$LogPath)) {
        try {
            New-Item -Path `$LogPath -ItemType Directory -Force | Out-Null
            Write-Host "Created log directory: `$LogPath"
        }
        catch {
            Write-Host "Failed to create log directory: `$(`$_.Exception.Message)"
        }
    }
    `$logFileName = if ([string]::IsNullOrWhiteSpace(`$PackageName)) { 
        "WingetInstall_20250521_115118" 
    } else { 
        `$PackageName.Replace(" ", "_").Replace("/", "_")
    }
    if (Test-Path `$LogPath) {
        `$logFilePath = Join-Path -Path `$LogPath -ChildPath "`$logFileName.log"
        Out-File -InputObject `$LogMessage -FilePath `$logFilePath -Append -Encoding utf8
    }
    Write-Host `$message
}

function Download-Winget {
    `$ProgressPreference = 'SilentlyContinue'
    `$7zipFolder = "`${env:WinDir}\Temp\7zip"
    try {
        Write-Log "Downloading WinGet..."
        # Create staging folder
        New-Item -ItemType Directory -Path "`${env:WinDir}\Temp\WinGet-Stage" -Force
        # Download Desktop App Installer msixbundle
        Invoke-WebRequest -UseBasicParsing -Uri https://aka.ms/getwinget -OutFile "`${env:WinDir}\Temp\WinGet-Stage\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    }
    catch {
        Write-Log "Failed to download WinGet!"
        Write-Log `$_.Exception.Message
        exit 1
    }
    try {
        Write-Log "Downloading 7zip CLI executable..."
        # Create temp 7zip CLI folder
        New-Item -ItemType Directory -Path `$7zipFolder -Force
        Invoke-WebRequest -UseBasicParsing -Uri https://www.7-zip.org/a/7zr.exe -OutFile "`$7zipFolder\7zr.exe"
        Invoke-WebRequest -UseBasicParsing -Uri https://www.7-zip.org/a/7z2408-extra.7z -OutFile "`$7zipFolder\7zr-extra.7z"
        Write-Log "Extracting 7zip CLI executable to `${7zipFolder}..."
        
        # Fixed argument formatting for 7zip extraction
        `$arguments = @(
            "x",
            "``"`$7zipFolder\7zr-extra.7z``"",
            "-o``"`$7zipFolder``"",
            "-y"
        )
        Start-Process -FilePath "`$7zipFolder\7zr.exe" -ArgumentList `$arguments -Wait -NoNewWindow
    }
    catch {
        Write-Log "Failed to download 7zip CLI executable!"
        Write-Log `$_.Exception.Message
        exit 1
    }
    try {
        # Create Folder for DesktopAppInstaller inside %ProgramData%
        New-Item -ItemType Directory -Path "`${env:ProgramData}\Microsoft.DesktopAppInstaller" -Force
        Write-Log "Extracting WinGet..."
        
        # Fixed argument formatting for WinGet bundle extraction
        `$bundleArguments = @(
            "x",
            "``"`${env:WinDir}\Temp\WinGet-Stage\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle``"",
            "-o``"`${env:WinDir}\Temp\WinGet-Stage``"",
            "-y"
        )
        Start-Process -FilePath "`$7zipFolder\7za.exe" -ArgumentList `$bundleArguments -Wait -NoNewWindow

        # Fixed argument formatting for AppInstaller extraction
        `$installerArguments = @(
            "x",
            "``"`${env:WinDir}\Temp\WinGet-Stage\AppInstaller_x64.msix``"",
            "-o``"`${env:ProgramData}\Microsoft.DesktopAppInstaller``"",
            "-y"
        )
        Start-Process -FilePath "`$7zipFolder\7za.exe" -ArgumentList `$installerArguments -Wait -NoNewWindow
    }
    catch {
        Write-Log "Failed to extract WinGet!"
        Write-Log `$_.Exception.Message
        exit 1
    }
    if (-Not (Test-Path "`${env:ProgramData}\Microsoft.DesktopAppInstaller\WinGet.exe")) {
        Write-Log "Failed to extract WinGet!"
        exit 1
    }
    `$script:WinGet = "`${env:ProgramData}\Microsoft.DesktopAppInstaller\WinGet.exe"
}

function Install-VisualC {
    try {
        Write-Log "Downloading Visual C++ Runtime..."
        `$url = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
        `$webClient = New-Object System.Net.WebClient
        `$webClient.DownloadFile(`$url, "`$env:Temp\vc_redist.x64.exe")
        `$webClient.Dispose()
    }
    catch {
        Write-Log "Failed to download Visual C++!"
        Write-Log `$_.Exception.Message
        exit 1
    }
    try {
        Write-Log "Installing Visual C++ Runtime..."
        `$processInfo = Start-Process -FilePath "`$env:temp\vc_redist.x64.exe" -ArgumentList "/q /norestart" -Wait -PassThru -NoNewWindow
        `$exitCode = `$processInfo.ExitCode
        Write-Log "Visual C++ installation completed with exit code: `$exitCode"
        Remove-Item "`$env:Temp\vc_redist.x64.exe" -Force -ErrorAction SilentlyContinue
        return `$exitCode
    }
    catch {
        Write-Log `$_.Exception.Message
        exit 1
    }
}

function WingetInstallPackage {
    try {
        Write-Log "Attempting to install `$PackageName using WinGet"
        `$arguments = @(
            "install"
            "--id", `$PackageName
            "--source", "winget"
            "--silent"
            "--accept-package-agreements"
            "--accept-source-agreements"
        )
        `$output = & `$WinGet @arguments 2>&1
        Write-Log "WinGet output: `$output"
        `$exitCode = `$LASTEXITCODE
        Write-Log "WinGet installation completed with exit code: `$exitCode"
        return `$exitCode
    }
    catch {
        Write-Log "Error during WinGet installation: `$(`$_.Exception.Message)"
        return 1
    }
}

function Test-AppInstalled {
    param (
        [string]`$AppName
    )
    
    `$installed = Get-CimInstance -ClassName Win32_Product | Where-Object { `$_.Name -like "*`$AppName*" }
    return `$null -ne `$installed
}

function Resolve-WinGetPath {
    # Look for Winget install in WindowsApps folder
    `$WinAppFolderPath = Get-ChildItem -Path "C:\Program Files\WindowsApps" -Recurse -Filter "winget.exe" | Where-Object {`$_.VersionInfo.FileVersion -ge 1.20}
    if (`$WinAppFolderPath) {
        `$script:WinGet = `$WinAppFolderPath | Select-Object -ExpandProperty Fullname | Sort-Object -Descending | Select-Object -First 1
        Write-Log "WinGet.exe found at path `$WinGet"
        return `$true
    }
    else {
        # Check if WinGet copy has already been extracted to ProgramData folder
        if (Test-Path "`${env:ProgramData}\Microsoft.DesktopAppInstaller\WinGet.exe") {
            Write-Log "WinGet.exe found in `${env:ProgramData}\Microsoft.DesktopAppInstaller"
            `$script:WinGet = "`${env:ProgramData}\Microsoft.DesktopAppInstaller\WinGet.exe"
            return `$true
        }
        else {
            Write-Log "WinGet.exe not found"
            return `$false
        }
    }
}

function Test-WinGetOutput {
    if (-Not (Test-Path `$WinGet)) {
        Write-Log "WinGet path not found at Test-WinGetOutput function!"
        Write-Log "WinGet variable : `$WinGet"
        return `$false
    }
    try {
        `$maxAttempts = 3
        `$attempt = 1
        `$success = `$false

        while (-not `$success -and `$attempt -le `$maxAttempts) {
            Write-Log "Attempt `$attempt of `$maxAttempts to test WinGet"
            `$processInfo = Start-Process -FilePath `$WinGet -ArgumentList "--version" -Wait -PassThru -NoNewWindow
            if (`$processInfo.ExitCode -eq 0) {
                Write-Log "WinGet executable test successful"
                `$success = `$true
                return `$true
            } elseif (`$processInfo.ExitCode -eq -1073741701) {
                Write-Log "WinGet executable test failed with DLL error (0xC000007B). Waiting before retry..."
                Start-Sleep -Seconds 60
                `$attempt++
            } else {
                Write-Log "WinGet executable test failed with exit code: `$(`$processInfo.ExitCode)"
                return `$false
            }
        }

        if (-not `$success) {
            Write-Log "All WinGet test attempts failed"
            return `$false
        }
    }
    catch {
        Write-Log "WinGet executable test failed: `$(`$_.Exception.Message)"
        return `$false
    }
}

function Ensure-WinGetReady {
    `$maxAttempts = 5
    `$attempt = 1
    `$success = `$false

    while (-not `$success -and `$attempt -le `$maxAttempts) {
        Write-Log "Attempt `$attempt of `$maxAttempts to ensure WinGet is ready"
        
        Resolve-WinGetPath
        if (Test-WinGetOutput) {
            `$success = `$true
            Write-Log "WinGet is ready"
            return `$true
        } else {
            Write-Log "WinGet not ready. Waiting before retry..."
            Start-Sleep -Seconds 60
            `$attempt++
        }
    }

    if (-not `$success) {
        Write-Log "Failed to get WinGet ready after `$maxAttempts attempts"
        return `$false
    }
}

#region Script
# Install Visual C++ Runtime first
Write-Log "Installing Visual C++ Runtime prerequisites..."
`$vcInstall = Install-VisualC
if (`$vcInstall -ne 0 -and `$vcInstall -ne 3010) {
    Write-Log "Failed to install Visual C++ Runtime. Exit code: `$vcInstall"
    exit 1
}

# Get path for Winget executable
if (-not (Resolve-WinGetPath)) {
    Write-Log "WinGet not found. Attempting to download and install WinGet..."
    Download-Winget
}

if (-not (Test-Path `$WinGet)) {
    Write-Log "Unable to find or install WinGet. Cannot proceed with installation."
    exit 1
}
try {
    Write-Log -message "Starting installation of `$PackageName"
    `$Install = WingetInstallPackage
    Write-Log "Installation completed with result: `$Install"
    
    if (`$Install -eq 0) {
        Write-Log "Installation completed successfully"
        exit 0
    } 
    elseif (`$Install -eq -4294967041 -or `$Install -eq -1073741701) {
        Write-Log "Installation reported failure. Checking if app is actually installed..."
        if (Test-AppInstalled -AppName `$PackageName) {
            Write-Log "App appears to be installed despite reported failure. Considering installation successful."
            exit 0
        } else {
            Write-Log "App does not appear to be installed. Installation failed."
            exit `$Install
        }
    }
    else {
        Write-Log "Installation failed with exit code: `$Install"
        exit `$Install
    }
}
catch {
    Write-Log "Critical error during installation: `$(`$_.Exception.Message)"
    exit 1
}
finally {
    Write-Log "Script execution completed. Exiting."
}
#endregion
"@
                    $wingetInstallScriptContent | Out-File -FilePath $wingetInstallScriptPath -Encoding UTF8 -ErrorAction Stop
                    Log-Message "Created Winget install script for $($app.DisplayName)."

                    # Create Winget uninstall script
                    $wingetUninstallScriptPath = Join-Path -Path $TempDir -ChildPath "${safeFileName}_uninstall.ps1"
                    $wingetUninstallScriptContent = @"
function Write-Log(`$message) #Log script messages to temp directory
{
    `$LogMessage = ((Get-Date -Format "MM-dd-yy HH:MM:ss ") + `$message)
    `$LogPath = "`$env:programdata\Microsoft\IntuneManagementExtension\Logs"
    
    # Create log directory if it doesn't exist
    if (-not (Test-Path `$LogPath)) {
        try {
            New-Item -Path `$LogPath -ItemType Directory -Force | Out-Null
            Write-Host "Created log directory: `$LogPath"
        }
        catch {
            Write-Host "Failed to create log directory: `$(`$_.Exception.Message)"
        }
    }

    # Ensure we have a valid package name for the log file
    `$logFileName = if ([string]::IsNullOrWhiteSpace(`$PackageName)) { 
        "WingetInstall_$(Get-Date -Format 'yyyyMMdd_HHmmss')" 
    } else { 
        `$PackageName.Replace(" ", "_").Replace("/", "_")
    }

    if (Test-Path `$LogPath) {
        `$logFilePath = Join-Path -Path `$LogPath -ChildPath "`$logFileName.log"
        Out-File -InputObject `$LogMessage -FilePath `$logFilePath -Append -Encoding utf8
    }
    Write-Host `$message
}

# Define the Winget Package Name
`$PackageName = '$($app.WingetId)'

function Download-Winget {
    `$ProgressPreference = 'SilentlyContinue'
    `$7zipFolder = "`${env:WinDir}\Temp\7zip"
    try {
        Write-Log "Downloading WinGet..."
        New-Item -ItemType Directory -Path "`${env:WinDir}\Temp\WinGet-Stage" -Force | Out-Null
        Invoke-WebRequest -UseBasicParsing -Uri https://aka.ms/getwinget -OutFile "`${env:WinDir}\Temp\WinGet-Stage\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    }
    catch {
        Write-Log "Failed to download WinGet!"
        Write-Log `$_.Exception.Message
        exit 1
    }
    try {
        Write-Log "Downloading 7zip CLI executable..."
        New-Item -ItemType Directory -Path `$7zipFolder -Force | Out-Null
        Invoke-WebRequest -UseBasicParsing -Uri https://www.7-zip.org/a/7zr.exe -OutFile "`$7zipFolder\7zr.exe"
        Invoke-WebRequest -UseBasicParsing -Uri https://www.7-zip.org/a/7z2408-extra.7z -OutFile "`$7zipFolder\7zr-extra.7z"
        Write-Log "Extracting 7zip CLI executable to `${7zipFolder}..."
        `$arguments = @(
            "x",
            "``"`$7zipFolder\7zr-extra.7z``"",
            "-o``"`$7zipFolder``"",
            "-y"
        )
        Start-Process -FilePath "`$7zipFolder\7zr.exe" -ArgumentList `$arguments -Wait -NoNewWindow
    }
    catch {
        Write-Log "Failed to download 7zip CLI executable!"
        Write-Log `$_.Exception.Message
        exit 1
    }
    try {
        New-Item -ItemType Directory -Path "`${env:ProgramData}\Microsoft.DesktopAppInstaller" -Force | Out-Null
        Write-Log "Extracting WinGet..."
        `$bundleArguments = @(
            "x",
            "``"`${env:WinDir}\Temp\WinGet-Stage\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle``"",
            "-o``"`${env:WinDir}\Temp\WinGet-Stage``"",
            "-y"
        )
        Start-Process -FilePath "`$7zipFolder\7za.exe" -ArgumentList `$bundleArguments -Wait -NoNewWindow
        `$installerArguments = @(
            "x",
            "``"`${env:WinDir}\Temp\WinGet-Stage\AppInstaller_x64.msix``"",
            "-o``"`${env:ProgramData}\Microsoft.DesktopAppInstaller``"",
            "-y"
        )
        Start-Process -FilePath "`$7zipFolder\7za.exe" -ArgumentList `$installerArguments -Wait -NoNewWindow
    }
    catch {
        Write-Log "Failed to extract WinGet!"
        Write-Log `$_.Exception.Message
        exit 1
    }
    if (-Not (Test-Path "`${env:ProgramData}\Microsoft.DesktopAppInstaller\WinGet.exe")) {
        Write-Log "Failed to extract WinGet!"
        exit 1
    }
    `$script:WinGet = "`${env:ProgramData}\Microsoft.DesktopAppInstaller\WinGet.exe"
}

# Find Winget executable path
`$wingetExe = "C:\ProgramData\Microsoft.DesktopAppInstaller\winget.exe"
if (-not (Test-Path `$wingetExe)) {
    Write-Log "winget.exe not found. Attempting to download and install WinGet..."
    Download-Winget
    `$wingetExe = `$script:WinGet
}

if (Test-Path `$wingetExe) {
    Write-Log "Found Winget at: `$wingetExe"
    # Check if app is installed
    `$InstalledApps = & `$wingetExe list --id `$PackageName
    if (`$InstalledApps -match `$PackageName) {
        Write-Log "Trying to uninstall `$PackageName"
        try {
            & `$wingetExe uninstall --id `$PackageName --silent
            if (`$LASTEXITCODE -eq 0) {
                Write-Log "Successfully uninstalled `$PackageName"
                Exit 0
            } else {
                Write-Log "Failed to uninstall `$PackageName. Exit code: `$LASTEXITCODE"
                Exit 1
            }
        }
        catch {
            Write-Log "Error during uninstall: `$(`$_.Exception.Message)"
            Exit 1
        }
    }
    else {
        Write-Log "`$PackageName is not installed or detected"
        Exit 0
    }
} else {
    Write-Log "Winget executable not found at expected location"
    Exit 1
}
"@
                    $wingetUninstallScriptContent | Out-File -FilePath $wingetUninstallScriptPath -Encoding UTF8 -ErrorAction Stop
                    Log-Message "Created Winget uninstall script for $($app.DisplayName)."

                    # Package the script using IntuneWinAppUtil.exe
                    $outputFolder = "C:\IntunePackages"
                    $intuneWinFile = Join-Path -Path $outputFolder -ChildPath "$safeFileName.intunewin"
                    $arguments = @("-c", $TempDir, "-s", "$safeFileName.ps1", "-o", $outputFolder)
                    Start-Process -FilePath $IntuneWinAppUtilPath -ArgumentList $arguments -Wait -NoNewWindow -ErrorAction Stop
                    Log-Message "Packaged $($app.DisplayName) into $intuneWinFile successfully."

                    # Create detection script
                    $detectionScriptPath = Join-Path -Path $outputFolder -ChildPath "${safeFileName}_DetectionScript.ps1"
                    $detectionScriptContent = @"
# Detection Script for $($app.DisplayName)

`$PackageName = '$($app.WingetId)'

# Try ProgramData location first
`$ProgramDataPath = "`${env:ProgramData}\Microsoft.DesktopAppInstaller"
if (Test-Path `$ProgramDataPath) {
    `$WingetPath = `$ProgramDataPath
}
# If not found, check WindowsApps
else {
    `$ResolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" -ErrorAction SilentlyContinue
    if (`$ResolveWingetPath) {
        `$WingetPath = `$ResolveWingetPath[-1].Path
    }
    else {
        Write-Output "WinGet not found"
        exit 1
    }
}

try {
    `$config
    cd `$WingetPath
    `$listResult = .\winget.exe list --id `$PackageName --accept-source-agreements

    if (`$listResult | Select-String -SimpleMatch `$PackageName) {
        Write-Output "`$PackageName detected"
        exit 0
    }
    else {
        Write-Output "Application not found"
        exit 1
    }
}
catch {
    Write-Output "Error in detection script"
    exit 1
}
"@
                    $detectionScriptContent | Out-File -FilePath $detectionScriptPath -Encoding UTF8 -ErrorAction Stop
                    Log-Message "Created enhanced detection script for $($app.DisplayName)."

                    # Get metadata and create rules
                    $intuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $intuneWinFile
                    $requirementRule = New-IntuneWin32AppRequirementRule -Architecture "All" -MinimumSupportedWindowsRelease "W10_1607"
                    $detectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile $detectionScriptPath -EnforceSignatureCheck $false -RunAs32Bit $false

                    # Check for icon
                    $iconsDir = Join-Path -Path $scriptDirectory -ChildPath "Icons"
                    $iconPath = Join-Path -Path $iconsDir -ChildPath "$($app.WingetId).png"

                    # Create the base parameters for Add-IntuneWin32App
                    $intuneAppParams = @{
                        FilePath = $intuneWinFile
                        DisplayName = $app.DisplayName
                        Description = $app.Description
                        Publisher = $app.Publisher
                        InstallExperience = "system"
                        RestartBehavior = "suppress"
                        DetectionRule = $detectionRule
                        RequirementRule = $requirementRule
                        InstallCommandLine = $app.InstallCommand
                        UninstallCommandLine = $app.UninstallCommand
                        CompanyPortalFeaturedApp = $true
                        AllowAvailableUninstall = $true
                        Verbose = $true
                        ErrorAction = "Stop"
                    }

                    # Check if icon file exists, if not, download it
                        if (-not (Test-Path $iconPath)) {
                            $iconUrl = "https://api.winstall.app/icons/$($app.WingetId).png"
                            try {
                                Invoke-WebRequest -Uri $iconUrl -OutFile $iconPath -ErrorAction Stop
                                Log-Message "Downloaded icon from $iconUrl"
                            } catch {
                                Log-Message "Could not download icon from $iconUrl"
                        }
                    }

                    # Add icon if it exists
                    if (Test-Path $iconPath) {
                        Log-Message "Found icon file for $($app.DisplayName) at: $iconPath"
                        try {
                            # Convert icon to Base64
                            $iconBytes = [System.IO.File]::ReadAllBytes($iconPath)
                            $iconBase64 = [System.Convert]::ToBase64String($iconBytes)
                            $intuneAppParams.Icon = $iconBase64
                            Log-Message "Successfully converted icon to Base64"
                        }
                        catch {
                            Log-Message "Failed to convert icon to Base64: $($_.Exception.Message)" "WARNING"
                        }
                    } else {
                        Log-Message "No icon file found for $($app.DisplayName), proceeding without icon"
                    }

                    # Upload the app to Intune
                    Log-Message "Uploading $($app.DisplayName) to Intune..."
                    $intuneApp = Add-IntuneWin32App @intuneAppParams

                    Log-Message "Successfully uploaded $($app.DisplayName) to Intune"
                    Log-Message "App ID: $($intuneApp.id)"
                    Log-Message "Display Name: $($intuneApp.displayName)"
                    Log-Message "Description: $($intuneApp.description)"
                    Log-Message "Publisher: $($intuneApp.publisher)"

                    # Add assignment only if user selected Yes
                    if ($assignmentChoice.AllDevices) {
                        Log-Message "Adding 'All Devices' assignment to $($app.DisplayName)"
                        Add-IntuneWin32AppAssignmentAllDevices -ID $intuneApp.id -Intent ($assignmentChoice.AllDevicesRequired ? "required" : "available") -Notification "showAll" -Verbose
                        Log-Message "Successfully added 'All Devices' assignment to $($app.DisplayName)"
                    }
                    if ($assignmentChoice.AllUsers) {
                        Log-Message "Adding 'All Users' assignment to $($app.DisplayName)"
                        Add-IntuneWin32AppAssignmentAllUsers -ID $intuneApp.id -Intent ($assignmentChoice.AllUsersRequired ? "required" : "available") -Notification "showAll" -Verbose
                        Log-Message "Successfully added 'All Users' assignment to $($app.DisplayName)"
                    }
                    if ($assignmentChoice.NoAssignment) {
                        Log-Message "No assignment selected for $($app.DisplayName)"
                        # No assignment logic needed
                    } 

                } catch {
                    Log-Message "Error processing $($app.DisplayName)" "ERROR" $_
                }
            }

        } catch {
            Log-Message "Critical error in main script execution" "ERROR" $_
        } finally {
            # Perform cleanup operations
            Log-Message "Starting cleanup operations..."
            Cleanup-TempFiles -TempDir $TempDir
            Log-Message "Script execution completed. Intune Graph session will close automatically."
        }

        # Show completion message
        [System.Windows.Forms.MessageBox]::Show(
            "Process completed. Check the logs for details.",
            "Process Complete",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        Log-Message "Critical error in main script execution" "ERROR" $_
        [System.Windows.Forms.MessageBox]::Show(
            "An error occurred. Please check the error log for details.`n`nError: $($_.Exception.Message)",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    finally {
        # Stop transcript before cleanup
        try {
            Stop-Transcript
            Log-Message "Stopped transcript logging"
        }
        catch {
            Log-Message "Error stopping transcript" "ERROR" $_
        }
    }
}

# Define cleanup function
function Cleanup-TempFiles {
    param (
        [string]$TempDir
    )
    try {
        Get-ChildItem -Path $TempDir -File | ForEach-Object {
            Remove-Item -Path $_.FullName -Force -ErrorAction Stop
            Log-Message "Removed temporary file: $($_.FullName)"
        }
        Remove-Item -Path $TempDir -Force -Recurse -ErrorAction Stop
        Log-Message "Removed temporary directory: $TempDir"
    } catch {
        Log-Message "Error during cleanup" "ERROR" $_
    }
}

# Define the Search-WingetApps function
function Search-WingetApps {
    $searchForm = New-Object System.Windows.Forms.Form
    $searchForm.Text = "Search Winget Apps"
    $searchForm.Size = New-Object System.Drawing.Size(800,400)
    $searchForm.StartPosition = "CenterScreen"

    $searchLabel = New-Object System.Windows.Forms.Label
    $searchLabel.Location = New-Object System.Drawing.Point(10,20)
    $searchLabel.Size = New-Object System.Drawing.Size(100,20)
    $searchLabel.Text = "Search Term:"
    $searchForm.Controls.Add($searchLabel)

    $searchTextBox = New-Object System.Windows.Forms.TextBox
    $searchTextBox.Location = New-Object System.Drawing.Point(120,20)
    $searchTextBox.Size = New-Object System.Drawing.Size(350,20)
    $searchForm.Controls.Add($searchTextBox)

    $searchButton = New-Object System.Windows.Forms.Button
    $searchButton.Location = New-Object System.Drawing.Point(480,20)
    $searchButton.Size = New-Object System.Drawing.Size(75,23)
    $searchButton.Text = "Search"
    $searchForm.Controls.Add($searchButton)

    $resultListView = New-Object System.Windows.Forms.ListView
    $resultListView.Location = New-Object System.Drawing.Point(10,50)
    $resultListView.Size = New-Object System.Drawing.Size(760,250)
    $resultListView.View = [System.Windows.Forms.View]::Details
    $resultListView.FullRowSelect = $true
    $resultListView.Columns.Add("Name", 200)
    $resultListView.Columns.Add("ID", 200)
    $resultListView.Columns.Add("Version", 100)
    $resultListView.Columns.Add("Source", 100)
    $searchForm.Controls.Add($resultListView)

    $addButton = New-Object System.Windows.Forms.Button
    $addButton.Location = New-Object System.Drawing.Point(350,310)
    $addButton.Size = New-Object System.Drawing.Size(75,23)
    $addButton.Text = "Add"
    $addButton.Enabled = $false
    $searchForm.Controls.Add($addButton)

    # Create the search function
    $performSearch = {
        $resultListView.Items.Clear()
        $searchTerm = $searchTextBox.Text
        
        # Disable search button and show searching status
        $searchButton.Enabled = $false
        $searchButton.Text = "Searching..."
        $searchForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        
        try {
            # Perform the search using Find-WinGetPackage
            $searchResults = Find-WinGetPackage -Query $searchTerm

            # Process results
            foreach ($result in $searchResults) {
                $item = New-Object System.Windows.Forms.ListViewItem($result.Name)
                $item.SubItems.Add($result.Id)
                $item.SubItems.Add($result.Version)
                $item.SubItems.Add($result.Source)
                $resultListView.Items.Add($item)
            }

            if ($resultListView.Items.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show(
                    "No results found for: $searchTerm",
                    "No Results",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Error during search: $($_.Exception.Message)",
                "Search Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error)
        }
        finally {
            $searchButton.Enabled = $true
            $searchButton.Text = "Search"
            $searchForm.Cursor = [System.Windows.Forms.Cursors]::Default
        }
    }

    # Add Enter key handler for the search textbox
    $searchTextBox.Add_KeyDown({
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            $_.SuppressKeyPress = $true  # Prevents the "ding" sound
            & $performSearch
        }
    })

    # Add click handler for the search button
    $searchButton.Add_Click($performSearch)

    $resultListView.Add_SelectedIndexChanged({
        $addButton.Enabled = $resultListView.SelectedItems.Count -gt 0
    })

    $addButton.Add_Click({
        if ($resultListView.SelectedItems.Count -gt 0) {
            $selectedApp = $resultListView.SelectedItems[0]
            $displayName = $selectedApp.Text
            $wingetId = $selectedApp.SubItems[1].Text
            $version = $selectedApp.SubItems[2].Text

# Run winget show and capture output
$tempWingetFile = [System.IO.Path]::GetTempFileName()
winget show $wingetId | Out-File -FilePath $tempWingetFile -Encoding utf8
$wingetOutput = Get-Content -Path $tempWingetFile -Encoding utf8
Remove-Item $tempWingetFile -Force

# Extract Publisher
$publisher = ($wingetOutput | Where-Object { $_ -match "^\s*Publisher\s*:\s*(.+)$" }) -replace "^\s*Publisher\s*:\s*", ""

# Extract Description (single-line or multi-line)
$description = ""
$descriptionStarted = $false
$descriptionLines = @()
foreach ($line in $wingetOutput) {
    # Handle single-line description
    if ($line -match "^\s*Description\s*:\s*(.+)$") {
        $description = $Matches[1].Trim()
        break
    }
    # Handle multi-line description
    if ($line -match "^\s*Description\s*:\s*$") {
        $descriptionStarted = $true
        continue
    }
    if ($descriptionStarted) {
        if ($line -match "^\S") { break }
        $descriptionLines += $line.Trim()
    }
}
if (-not $description) {
    $description = $descriptionLines -join " "
}

# Fix encoding issues
$description = $description -replace 'ÔÇ£', '"'
$description = $description -replace 'ÔÇØ', '"'
$description = $description -replace 'ÔÇÖ', "'"
$description = $description -replace 'ÔÇô', '-'
$description = $description -replace 'â€“', '-'
$description = $description -replace 'â€”', '--'
$description = $description -replace 'â€˜', "'"
$description = $description -replace 'â€™', "'"
$description = $description -replace 'â€œ', '"'
$description = $description -replace 'â€�', '"'

            $safeFileName = $displayName -replace '\s', '_'
            $installCommand = "%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe -Executionpolicy Bypass -file .\$safeFileName.ps1 -mode install -log `"$wingetId.log`""
            $uninstallCommand = "%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe -Executionpolicy Bypass -file .\${safeFileName}_uninstall.ps1"

            $newApp = @{
                DisplayName = $displayName
                WingetId = $wingetId
                Publisher = $publisher
                Description = $description
                InstallCommand = $installCommand
                UninstallCommand = $uninstallCommand
            }

            $script:config.Apps += $newApp
            Save-Config
            Load-Apps
            Log-Message "Added new app from Winget: $displayName"
            $searchForm.Close()
        }
    })

    $searchForm.ShowDialog()
}

# Define the Save-Config function
function Save-Config {
    if ($PSScriptRoot) {
        $scriptRoot = $PSScriptRoot
    } elseif ($psISE) {
        $scriptRoot = Split-Path -Parent $psISE.CurrentFile.FullPath
    } else {
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    
    if (-not $scriptRoot) {
        $scriptRoot = Get-Location
    }
    
    $configPath = Join-Path -Path $scriptRoot -ChildPath "config.json"
    $script:config | ConvertTo-Json | Set-Content -Path $configPath
}
# Add event handlers
$appRegButton.Add_Click({ Register-IntuneApp })
$removeCredButton.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to remove all credentials?",
        "Confirm Removal",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        Remove-AllCredentials
    }
})
$addButton.Add_Click({ Add-App })
$editButton.Add_Click({ Edit-App })
$removeButton.Add_Click({ Remove-App })
$runButton.Add_Click({ Run-MainScript })
$searchButton.Add_Click({ Search-WingetApps })

# Modify the form load event to initialize modules
$form.Add_Shown({
    if (Initialize-RequiredModules) {
        Update-WingetSilently
        Load-Apps  # This will just load any existing apps from config without connecting
    }
})

# Add form closing event handler
$form.Add_FormClosing({
    param($sender, $e)
    
    [System.Windows.Forms.MessageBox]::Show(
        "All credentials will be removed.",
        "Closing Application",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information)
    
    try {
        # Execute cleanup in specified order
        Remove-AzureADApp
        Remove-StoredCredentials
        
        # Check if Microsoft.Graph.Authentication module is loaded
        if (Get-Module -Name Microsoft.Graph.Authentication) {
            try {
                Disconnect-MgGraph -ErrorAction SilentlyContinue
            }
            catch {
                # Ignore any disconnect errors
            }
        }
        
        # Remove Graph credentials without trying to load the module again
        Remove-GraphCredentials
    }
    catch {
        Log-Message "Cleanup error during form closing: $($_.Exception.Message)" "WARNING"
    }
})

# Show the form
$form.ShowDialog()