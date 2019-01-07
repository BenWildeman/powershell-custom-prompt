# reset the home directory so that it's correct
Remove-Variable -Force HOME
Set-Variable HOME "$env:homedrive$env:homepath"
(get-psprovider 'FileSystem').Home = $HOME # this sets the ~ shortcut to be the same as the home above

# remove the ls alias so that we can use the bash ls version, and wrap it with a couple of default args
Remove-Item alias:ls
function ls {
    & "C:/Program Files/Git/usr/bin/ls.exe" --color=auto -A $args
}

# remove other powershell bash aliases so that we can use the bash versions
Remove-Item alias:rm
Remove-Item alias:cat
Remove-Item alias:echo
Remove-Item alias:curl

# setup custom prompt to be more like git bash
function prompt {
        # show git branch and colour it based on whether there's staged/unstaged changes or ready to push
        function Write-Git {
            $path = $ExecutionContext.SessionState.Path.CurrentLocation.Path
            $gitPath = $path + "\.git"

            # check to see if this is a git repository
            if (Test-Path $gitPath) {
                # check to see if git is actually installed
                if (Get-Command git -errorAction SilentlyContinue) {
                    $branch = git branch | grep \* | grep -o "[^ ]*$"
                    $status = git -c core.quotepath=false -c color.status=false status --short
                    $diff = git diff --shortstat
                    $modded = $status.length
                    $added = $diff.length
                    $colour = "Gray"

                    if ($modded -gt 0) {
                        if ($added -eq 0) {
                            $colour = "Cyan" # staged changes
                        } else {
                            $colour = "Red" # unstaged changes
                        }
                    } else {
                        $canPush = git rev-list HEAD...origin/$branch --count

                        if ($canPush -gt 0) {
                            $colour = "Green" # ready to push
                        }
                    }
                    
                    if ($branch -gt 0) {
                        Write-Host " (" -ForegroundColor Yellow -NoNewLine
                        Write-Host $branch -ForegroundColor $colour -NoNewLine
                        Write-Host ")" -ForegroundColor Yellow -NoNewLine
                    }
                }
            }
        }

    # write the package.json name and version if it exists
    function Write-Package {
        $path = $ExecutionContext.SessionState.Path.CurrentLocation.Path
        $packPath = $path + "\package.json"

        if (Test-Path $packPath) {
            $pack = Get-Content -Raw -Path package.json | ConvertFrom-Json

            if ($pack.name -gt 0) {
                Write-Host " (" -ForegroundColor Yellow -NoNewLine
                Write-Host $pack.name -ForegroundColor Gray -NoNewLine
            
                if ($pack.version -gt 0) {
                    Write-Host "@" -ForegroundColor Gray -NoNewLine
                    Write-Host $pack.version -ForegroundColor Cyan -NoNewLine
                }
                
                Write-Host ")" -ForegroundColor Yellow -NoNewLine
            }
        }
    }

    $curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path

    # show the home path as ~ instead of the full path
    if ($curPath.ToLower().StartsWith($HOME.ToLower())) {
        $rPath = $curPath.SubString($HOME.Length)
        $curPath = "~"

        if ($rPath.Length -gt 0) {
            $curPath = $curPath + "\$rPath"
        }
    }

    Write-Host "" # start with new line
    write-Host "$env:username@$(hostname) " -ForegroundColor DarkGreen -NoNewLine #show the logged in user and host
    Write-Host $curPath -ForegroundColor DarkMagenta -NoNewLine  # show current directory
    Write-Git # show git information when necessary
    Write-Package  # show the node package information when necessary
    "`n$('♇' * ($nestedPromptLevel + 1)) " # push the input onto a new line like bash with pluto symbol instead of > or $
}
