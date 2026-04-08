# Winget2Intune

A PowerShell GUI tool for automating Winget and Chocolatey app deployments through Microsoft Intune. Note that Windows Defender could block the script on first run. Unblock the script in Windows Defender to solve this problem.

## Overview

This script provides a graphical interface to:
<ul>
    <li>Register and consent an Azure AD application for Intune management</li>
    <li>Search and select Winget or Chocolatey packages</li>
    <li>Package and upload applications to Intune</li>
    <li>Automatically create detection and installation scripts</li>
    <li>Deploy applications to all devices, all users and set required or available</li>
</ul>

## Prerequisites

<ul>
    <li>Windows 10/11</li>
    <li>PowerShell 7</li>
    <li>Admin rights on the local machine</li>
    <li>Intune admin access</li>
    <li>Internet connectivity</li>
</ul>

## Setup Process

### First-Time Setup

<ol>
    <li>Run the script as administrator.</li>
    <li>Click the "App Reg" button to:
        <ul>
            <li>Register an Azure AD application</li>
            <li>Create necessary permissions</li>
            <li>Generate client credentials</li>
            <li>Automatically grant admin consent to the app</li>
        </ul>
    </li>
</ol>

## Adding Applications

You can add applications in three ways:

### Via Winget Search

<ol>
    <li>Click "Search Winget".</li>
    <li>Enter a search term.</li>
    <li>Select an application from the results.</li>
    <li>Click "Add" to save. Publisher and description are filled in automatically.</li>
</ol>

### Via Chocolatey Search

<ol>
    <li>Click "Search Choco".</li>
    <li>Enter a search term. Results show only the latest version of each package.</li>
    <li>Select an application from the results.</li>
    <li>Click "Add" to save. Publisher, description, and icon URL are filled in automatically.</li>
</ol>

> Chocolatey search uses the community.chocolatey.org NuGet API. No local Chocolatey installation is required on the admin machine to search and add packages.

### Manual Addition

<ol>
    <li>Click "Add".</li>
    <li>Fill in:
        <ul>
            <li>Display Name</li>
            <li>Package ID</li>
            <li>Publisher</li>
            <li>Description</li>
            <li>Source Type (Winget or Chocolatey)</li>
        </ul>
    </li>
    <li>Click OK to save.</li>
</ol>

## Application List

The main overview shows:
<ul>
    <li><strong>Display Name</strong>: The name shown in Intune and the Company Portal.</li>
    <li><strong>Package ID</strong>: The Winget or Chocolatey package identifier used for install/uninstall.</li>
    <li><strong>Publisher</strong>: The software vendor.</li>
    <li><strong>Source</strong>: <code>Winget</code> or <code>Choco</code>, so you can tell at a glance which package manager is used.</li>
</ul>

## Deploying Applications

<ol>
    <li>Select one or more applications from the list.
        <ul>
            <li>If none are selected, you'll be prompted to process all apps.</li>
        </ul>
    </li>
    <li>Click "Run" to start deployment.
        <ul>
            <li>Choose if you want to assign the "All Devices" or "All Users" group as required or available.</li>
        </ul>
    </li>
    <li>The script will:
        <ul>
            <li>Create installation scripts (Winget or Chocolatey depending on source type)</li>
            <li>Create uninstallation scripts</li>
            <li>Create detection scripts</li>
            <li>Package everything using IntuneWinAppUtil</li>
            <li>Download and attach the application icon automatically</li>
            <li>Upload to Intune</li>
            <li>Create device assignments</li>
        </ul>
    </li>
</ol>

### Chocolatey deployment notes

<ul>
    <li>The generated install script bootstraps Chocolatey on the target device if it is not already present.</li>
    <li>Detection uses <code>choco list --local-only --exact</code> to verify installation.</li>
    <li>Icons are sourced from the URL returned by the Chocolatey API at search time.</li>
</ul>

## Additional Features

<ul>
    <li><strong>Edit</strong>: Modify existing application details, including switching the source type between Winget and Chocolatey.</li>
    <li><strong>Remove</strong>: Delete applications from the list.</li>
    <li><strong>Del Credentials</strong>: Remove stored Azure AD credentials.</li>
    <li><strong>Auto-update</strong>: The script checks GitHub for a newer version on startup and updates itself automatically.</li>
    <li><strong>Logging</strong>: Detailed logs stored in the Logs directory.</li>
</ul>

## Configuration

<p>Settings are stored in: <code>[Script Directory]/config.json</code></p>
<p>Includes:</p>
<ul>
    <li>Application list (with source type per app)</li>
    <li>Azure AD credentials</li>
    <li>Application configurations</li>
</ul>

<p>Existing configs created before v2.1.0 (Winget-only) are automatically migrated on first launch. No manual changes are needed.</p>

## Cleanup

<p>The script automatically:</p>
<ul>
    <li>Removes temporary files after deployment</li>
    <li>Cleans up packaging directories</li>
    <li>Maintains organized log files</li>
    <li>Deletes credentials</li>
    <li>Deletes App registration</li>
</ul>

## Logging

<p>All actions are logged to: <code>[Script Directory]/Logs/IntuneUploadLog.txt</code></p>
<p>Individual app installation/uninstallation logs are created during deployment and can be found at <code>C:\ProgramData\Microsoft\IntuneManagementExtension\Logs</code>.</p>
