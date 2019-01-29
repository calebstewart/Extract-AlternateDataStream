<#
.SYNOPSIS
    Inspect files for alternate data streams and extract them to the given
    directory

.DESCRIPTION
    Look at all given files, and check for NTFS alternate datastreams. If
    an alternate datastream is found, then it will extract the stream to
    a separate file in the given `ExtractTo` directory. The new name will
    be `[old-name]-[stream-name]`.

.PARAMETER Path
    A path (or list of paths) to check. A directory will cause the script
    to search all files in the given directory.

.PARAMETER Recurse
    Whether or not to be recursive in the search.

.PARAMETER ExtractTo
    The directory to place all extracted Alternate Data Streams in. This
    directory must already exist.

.OUTPUTS
    None.

.NOTES
    Name: Extract-AlternateDataStream.ps1
    Author: Caleb Stewart
    DateCreated: 29JAN2019

.LINK
    https://github.com/Caleb1994/Extract-AlternateDataStream

.EXAMPLE
    PS C:\> Extract-AlternateDataStream -Path C:\SuspiciousDirectory -Recurse -ExtractTo C:\ADS-Extract

.EXAMPLE
    PS C:\> Get-ChildItem -Recurse -Force -Path C:\ -Include "*suspicious-name*" | Extract-AlternateDataStream -Recurse -ExtractTo C:\ADS-Extract
#>
param(
    [Parameter(Mandatory=$true, Position=0,
        ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)] `
    [Alias('PsPath')] `
    [string[]]$Path,
    [switch]$Recurse,
    [Parameter(mandatory=$true)][string]$ExtractTo
)

# Initialize the file list
$FileList = @()
# Iterator for completion percentage
$iter = 0

# Make sure the extraction directory exists
if( -not (Test-Path $ExtractTo -PathType Container) ){
    Write-Error "extraction directory `"$ExtractTo`" does not exist."
    return $null   
}

# Get the list of files (individual, single directory or recursive)
$FileList = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction Stop

# Grab any Alternate Data Streams and extract them
ForEach( $file in $FileList ){
    # Update current progress
    Write-Progress -Activity "Extract-AlternateDataStream" `
        -Status "Checking $($file.FullName) for Alternate Data Streams" `
        -PercentComplete (([float]$iter/$FileList.Count)*100.0)

    # Iterate over all alternate data streams
    $item = Get-Item $file.FullName -Stream * | Where-Object { $_.Stream -ne ':$Data' } | ForEach-Object {
        Write-Progress -Activity "Extract-AlternateDataStream" `
            -Status "Extracting $($_.Stream) from $($file.BaseName)" `
            -PercentComplete (([float]$iter/$FileList.Count)*100.0)
        Get-Content "$($_.FileName):$($_.Stream)" | Out-File "$ExtractTo\$($file.BaseName)-$($_.Stream)"
    }

    # Increment iterator
    $iter += 1
}
