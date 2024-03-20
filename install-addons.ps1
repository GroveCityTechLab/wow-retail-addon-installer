# Define the list of GitHub repositories
$githubRepos = @(
    "DeadlyBossMods/DeadlyBossMods",
    "DeadlyBossMods/DBM-Dungeons",
    "DeadlyBossMods/DBM-PvP",
    "DeadlyBossMods/DBM-Cataclysm",
    "DeadlyBossMods/DBM-WotLK",
    "DeadlyBossMods/DBM-Shadowlands",
    "DeadlyBossMods/DBM-BfA",
    "DeadlyBossMods/DBM-Legion",
    "DeadlyBossMods/DBM-WoD",
    "DeadlyBossMods/DBM-MoP",
    "DeadlyBossMods/DBM-BCVanilla",
    "WeakAuras/WeakAuras2",
    "Tercioo/Details-Damage-Meter",
    "nnoggie/MythicDungeonTools"
)

# For repos that only exist on CurseForge
$curseRepos = @(
    "wow/tomtom"
)

# Destination directory for the addons
$destDir = "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\"
Write-Host "AddOns directory: $destDir"

# Clear existing addons so we are fresh
# A poor mans uninstall
Write-Host "Clearing $destDir of existing AddOns"
Remove-Item -Path "$destDir\*" -Recurse -Force

Write-Host "Starting CurseForge repositories"
foreach($cursed in $curseRepos){

   # Generate a unique temporary directory for cloning
   $tempDir = Join-Path -Path $env:TEMP -ChildPath ([System.Guid]::NewGuid().ToString())

   # Construct the clone command with the full URL
   $command = "git clone https://repos.curseforge.com/$cursed $tempDir"

   # Execute the clone command
   Write-Host "Cloning to $tempDir"
   Write-Host "Command: $command"
   Invoke-Expression $command

   # The name of the cloned repository folder (assuming it matches the last part of the repository path)
   $repoName = $cursed -split '/' | Select-Object -Last 1

   # Full path to the cloned repository
   $clonedRepoPath = Join-Path -Path $tempDir -ChildPath ""

   # Use Robocopy for copying to handle large files/directories. `/E` copies subdirectories, including empty ones.
   robocopy $clonedRepoPath $destDir\$repoName /E

   # Cleanup: Remove the temporary directory
   Remove-Item -Path $tempDir -Recurse -Force
   Write-Host "Robocopy completed, cleaning up temp files at $tempDir"

}

Write-Host "Starting Github repositories"

# Iterate over the repository list
foreach ($repo in $githubRepos) {
    try {
        # Fetch the latest release information
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest"

        # Get the download URL of the asset (assuming it's a zip file)
        $zipUrls = $releaseInfo.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -ExpandProperty browser_download_url

        foreach ($zipUrl in $zipUrls) {
            # Define the path for the downloaded zip file
            $zipFile = Join-Path -Path $env:TEMP -ChildPath (($repo -replace '/', '_') + ".zip")

            # Download the zip file
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile

            # Extract the zip file to the destination directory
            Write-Output "Extracting $zipFile to $destDir"
            Expand-Archive -Path $zipFile -DestinationPath $destDir -Force

            # Remove the downloaded zip file
            Write-Host "Cleaning up zip file at $zipFile"
            Remove-Item -Path $zipFile
        }
    
    }
    catch {
        Write-Error "Failed to process $repo : $_"
    }
}

Write-Output "Your AddOns have been installed to $destDir"
