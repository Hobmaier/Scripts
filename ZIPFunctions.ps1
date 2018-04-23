#Source http://purple-screen.com/?p=440

Add-Type -As System.IO.Compression.FileSystem

function New-ZipFile {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string[]] $InputObject,
        [Parameter(Mandatory)]
        [string] $ZipFilePath,
        [ValidateSet('Optimal','Fastest','NoCompression')]
        [System.IO.Compression.CompressionLevel] $Compression = 'Optimal',
        [switch] $Append,
        [switch] $Force
    )
    Begin {
        if (-not (Split-Path $ZipFilePath)) { $ZipFilePath = Join-Path $Pwd $ZipFilePath }
        if (Test-Path $ZipFilePath) {
            if ($Append.IsPresent) {
                Write-Verbose 'Appending to the destination file'
                $Archive = [System.IO.Compression.ZipFile]::Open($ZipFilePath,'Update')
            } elseif ($Force.IsPresent) {
                Write-Verbose 'Removing the destination file'
                Remove-Item $ZipFilePath
                $Archive = [System.IO.Compression.ZipFile]::Open($ZipFilePath,'Create')
            } else {
                Write-Error 'Output file already exists. Specify -Force option to replace it or -Append to add/replace files in existing archive'
                break
            }
        } else {
            $Archive = [System.IO.Compression.ZipFile]::Open($ZipFilePath,'Create')
        }
    }
    Process {
        foreach ($Obj in $InputObject) {
            try {
                switch ((Get-Item $Obj -ea Stop).GetType().Name) {
                    FileInfo {
                        $EntryName = Split-Path $Obj -Leaf
                        $Entry = $Archive.Entries | ? FullName -eq $EntryName
                        if ($Entry) {
                            if ($Force.IsPresent) {
                                Write-Verbose "Removing $EntryName from the archive"
                                $Entry.Delete()
                            } else {
                                throw "File $EntryName already exists in the archive"
                            }
                        }
                        $Verbose = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive,$Obj,$EntryName,$Compression)
                        Write-Verbose $Verbose
                    }
                    DirectoryInfo {
                        Push-Location $Obj
                        (Get-ChildItem . -Recurse -File).FullName | % {
                            $EntryName = (Join-Path (Split-Path $Obj -Leaf) (Resolve-Path $_ -Relative).TrimStart('.\')) -replace '\\','/'
                            $Entry = $Archive.Entries | ? FullName -eq $EntryName 
                            if ($Entry) {
                                if ($Force.IsPresent) {
                                    Write-Verbose "Removing $EntryName from the archive"
                                    $Entry.Delete()
                                } else {
                                    throw "File $EntryName already exists in the archive"
                                }
                            }
                            $Verbose = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive,$_,$EntryName,$Compression)
                            Write-Verbose $Verbose
                        }
                        Pop-Location
                    }
                }
            } catch {
                Write-Error $_
                $Archive.Dispose()
                Pop-Location
                if ($_.CategoryInfo.TargetType -ne [string] -and -not $Append.IsPresent) {
                    Remove-Item $ZipFilePath
                }
                return
            }
        }
    }
    End {
        $Archive.Dispose()
        Get-Item $ZipFilePath
    }
}

function Extract-ZipFile {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string] $ZipFilePath,
        [string] $OutputPath = $Pwd,
        [string[]] $FilesToExtract = '*',
        [switch] $CreateSubfolder,
        [Parameter(HelpMessage='Replace files in destination if exist')]
        [switch] $Force
    )
    try {
        $Archive = [System.IO.Compression.ZipFile]::Open($ZipFilePath,'Read')
        if ($CreateSubfolder.IsPresent) {
            $Destination = New-Item (Join-Path $OutputPath (Get-Item $ZipFilePath).BaseName) -ItemType Directory -Force:($Force.IsPresent) -ea Stop
        } elseif (Test-Path $OutputPath) {
            $Destination = Get-Item $OutputPath
        } else {
            $Destination = New-Item $OutputPath -ItemType Directory -ea Stop
        }
        Write-Verbose "Destination path: $($Destination.FullName)"
        Push-Location $Destination
        $FilesToExtract = $FilesToExtract | % {
            for ($FullPath = $_; $FullPath; $FullPath = (Split-Path $FullPath -Parent) -replace '\\','/') {$FullPath}
        }
        $FoldersToExtract = $FilesToExtract | ? {$_.EndsWith('/')}
        $Entries = ?: {$FilesToExtract -ne '*'} { $Archive.Entries | ? {
            $_.FullName.TrimEnd('/') -in $FilesToExtract -or
            $_.FullName -like "$FoldersToExtract*"
        } } { $Archive.Entries }
        $Extracted = $false
        $Entries | Sort Name,FullName | % {
            if (-not $_.Name) {
                $Verbose = New-Item -Path $_.FullName -ItemType Directory -Force:($Force.IsPresent) -ea Stop
                Write-Verbose "$Verbose created"
            } else {
                Write-Verbose "Extracting $($_.FullName)"
                $DestPath = Join-Path $Destination $_.FullName
                if (-not (Test-Path (Split-Path $DestPath))) {
                    $Verbose = New-Item -Path (Split-Path $DestPath) -ItemType Directory -Force:($Force.IsPresent) -ea Stop
                    Write-Verbose "$Verbose created"
                }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_,$DestPath,$Force.IsPresent)
                $Extracted = $true
            }
        }
        #return $Extracted
    } catch {
        Write-Error $_
        return
    } finally {
        Pop-Location
        $Archive.Dispose()
    }
}