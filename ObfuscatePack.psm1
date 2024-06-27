function Obfuscate_Pack {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Directory,

        [Parameter(Mandatory=$false)]
        [string]$FileExtension,

        [Parameter(Mandatory=$false)]
        [string]$Keyword,

        [Parameter(Mandatory=$true)]
        [string]$ZipName,

        [Parameter(Mandatory=$false)]
        [switch]$Delete
    )

    function Write-PositiveOutput {
        param ([string]$message)
        Write-Host $message -BackgroundColor Black -ForegroundColor Green
    }

    function Write-NegativeOutput {
        param ([string]$message)
        Write-Host $message -BackgroundColor Black -ForegroundColor Red
    }

    function Write-WarningOutput {
        param ([string]$message)
        Write-Host $message -BackgroundColor Black -ForegroundColor Yellow
    }

    # Validate the directory
    if (-Not (Test-Path -Path $Directory -PathType Container)) {
        Write-NegativeOutput "Directory '$Directory' does not exist."
        return
    }

    # Collect files based on parameters
    try {
        $files = Get-ChildItem -Path $Directory -Recurse -File | Where-Object {
            ($FileExtension -and $_.Extension -eq $FileExtension) -or
            ($Keyword -and $_.Name -match $Keyword)
        }
    } catch {
        Write-NegativeOutput "Error collecting files: $_"
        return
    }

    if ($files.Count -eq 0) {
        Write-NegativeOutput "No files found matching the criteria."
        return
    }

    # Display the collected files
    Write-PositiveOutput "Collected files:"
    $files | ForEach-Object { Write-PositiveOutput $_.FullName }

    # Handle delete confirmation
    if ($Delete) {
        Write-WarningOutput "Are you sure you want to delete the following files?"
        $files | ForEach-Object { Write-WarningOutput $_.FullName }
        
        $confirmation = Read-Host "Type 'Yes' or 'Y' to confirm, anything else to cancel"
        if ($confirmation -notmatch '^(Yes|Y)$') {
            Write-NegativeOutput "Operation cancelled by the user."
            return
        }
    }

    # Create a temporary directory for obfuscated files
    try {
        $tempDir = New-Item -ItemType Directory -Path (Join-Path -Path $env:TEMP -ChildPath (New-Guid).Guid)
    } catch {
        Write-NegativeOutput "Error creating temporary directory: $_"
        return
    }
    
    # Base64 encode each file and save to the temporary directory
    foreach ($file in $files) {
        try {
            $content = Get-Content -Path $file.FullName -Raw
            $encodedContent = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($content))
            $encodedFilePath = Join-Path -Path $tempDir.FullName -ChildPath $file.Name
            Set-Content -Path $encodedFilePath -Value $encodedContent
        } catch {
            Write-NegativeOutput "Error encoding file '$($file.FullName)': $_"
            continue
        }
    }

    # Create a zip file from the temporary directory
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir.FullName, $ZipName)
    } catch {
        Write-NegativeOutput "Error creating zip file: $_"
        return
    } finally {
        # Clean up the temporary directory
        try {
            Remove-Item -Path $tempDir.FullName -Recurse -Force
        } catch {
            Write-NegativeOutput "Error cleaning up temporary directory: $_"
        }
    }

    Write-PositiveOutput "Files have been obfuscated and zipped into '$ZipName'."

    # Delete the original files if confirmed
    if ($Delete) {
        $deletedFiles = @()
        foreach ($file in $files) {
            try {
                Remove-Item -Path $file.FullName -Force
                $deletedFiles += $file.FullName
            } catch {
                Write-NegativeOutput "Error deleting file '$($file.FullName)': $_"
            }
        }

        # Display deleted files
        if ($deletedFiles.Count -gt 0) {
            Write-PositiveOutput "Deleted files:"
            $deletedFiles | ForEach-Object { Write-PositiveOutput $_ }
        }
    }
}

# Export the function as a cmdlet
Export-ModuleMember -Function Obfuscate_Pack
