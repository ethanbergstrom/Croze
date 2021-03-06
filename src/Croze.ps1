$BaseOriginalName = 'brew'

$BaseOriginalCommandElements = @()

$BaseParameters = @()

$BaseOutputHandlers = @{
    ParameterSetName = 'Default'
    Handler = {
        param ( $output )
    }
}

$PackageInstallHandlers = @{
    ParameterSetName = 'Default'
    Handler = {
        param ( $output )

        if ($output -match 'Pouring') {
            # Formula output - capture package and dependency name and version
            $output | Select-String 'Pouring (?<name>\S+)(?<=\w)(-+)(?<version>\d+\.{0,1}\d*\.(?=\d)\d*)' | ForEach-Object -MemberName Matches | ForEach-Object {
                $match = ($_.Groups | Where-Object Name -in 'name','version').Value

                [PSCustomObject]@{
                    Name = $match[0]
                    Version = $match[1]
                }
            }
        } elseif ($output -match 'was successfully') {
            # Cask output - capture package only
            $output | Select-String '(?<name>\S+) was successfully' | ForEach-Object -MemberName Matches | ForEach-Object {
                $match = ($_.Groups | Where-Object Name -eq 'name').Value
                [PSCustomObject]@{
                    Name = $match
                }
            }
        }
    }
}

# The general structure of this hashtable is to define noun-level attributes, which are -probably- common across all commands for the same noun, but still allow for customization at more specific verb-level defition for that noun.
# The following three command attributes have the following order of precedence:
# 	OriginalCommandElements will be MERGED in the order of Noun + Verb + Base
#		Example: Noun HomebrewSource's element 'source', Verb Register's element 'add', and Base elements are merged to become 'Homebrew source add --limit-output --yes'
# 	Parameters will be MERGED in the order of Noun + Verb + Base
#		Example: Noun HomebrewPackage's parameters for package name and version and Verb Install's parameter specifying source information are merged to become '<packageName> --version=<packageVersion> --source=<packageSource>'.
#			These are then appended to the merged original command elements, to create 'Homebrew install <packageName> --version=<packageVersion> --source=<packageSource> --limit-output --yes'
# 	OutputHandler sets will SUPERCEDE each other in the order of: Verb -beats-> Noun -beats-> Base. This allows reusability of PowerShell parsing code.
#		Example: Noun HomebrewPackage has inline output handler PowerShell code with complex regex that works for both Install-HomebrewPackage and Uninstall-HomebrewPackage, but Get-HomebrewPackage's native output uses simple vertical bar delimiters.
#		Example 2: The native commands for Register-HomebrewSource and Unregister-HomebrewSource don't return any output, and until Crescendo supports error handling by exit codes, a base required default output handler that doesn't do anything can be defined and reused in multiple places.
$Commands = @(
    @{
        Noun = 'HomebrewTap'
        Verbs = @(
            @{
                Verb = 'Get'
                Description = 'Return Homebrew taps'
                OriginalCommandElements = @('tap')
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = {
                        param ($output)
                        if ($output) {
                            $output | ForEach-Object {
                                [PSCustomObject]@{
                                    Name = $_
                                }
                            }
                        }
                    }
                }
            },
            @{
                Verb = 'Register'
                Description = 'Register a new Homebrew tap'
                OriginalCommandElements = @('tap')
                Parameters = @(
                    @{
                        Name = 'Name'
                        ParameterType = 'string'
                        Description = 'Source Name'
                        Mandatory = $true
                    },
                    @{
                        Name = 'Location'
                        ParameterType = 'string'
                        Description = 'Source Location'
                    }
                )
            },
            @{
                Verb = 'Unregister'
                Description = 'Unregister an existing Homebrew tap'
                OriginalCommandElements = @('untap','-f')
                Parameters = @(
                    @{
                        Name = 'Name'
                        ParameterType = 'string'
                        Description = 'Source Name'
                        Mandatory = $true
                        ValueFromPipelineByPropertyName = $true
                    }
                )
            }
        )
    },
    @{
        Noun = 'HomebrewPackage'
        Parameters = @(
            @{
                Name = 'Name'
                ParameterType = 'string'
                Description = 'Package Name'
                ValueFromPipelineByPropertyName = $true
            },
            @{
                Name = 'Formula'
                OriginalName = '--formula'
                ParameterType = 'switch'
                Description = 'Formula'
            },
            @{
                Name = 'Cask'
                OriginalName = '--cask'
                ParameterType = 'switch'
                Description = 'Cask'
            }
        )
        Verbs = @(
            @{
                Verb = 'Install'
                Description = 'Install a new package with Homebrew'
                OriginalCommandElements = @('install')
                OutputHandlers = $PackageInstallHandlers
            },
            @{
                Verb = 'Get'
                Description = 'Get a list of installed Homebrew packages'
                OriginalCommandElements = @('list','--versions')
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = {
                        param ( $output )

                        if ($output) {
                            $output | ConvertFrom-StringData -Delimiter ' ' | ForEach-Object {
                                # Brew supports installing multiple versions side-by-side, but instead of listing them as separate rows, it puts multiple versions on the same row. 
                                # To present this package data in a way that's idiomatic to PowerShell, we need to list each version as a separate object:
                                $_.GetEnumerator() | ForEach-Object {
                                    $name = $_.Name
                                    $_.Value -split ' ' | Select-Object -Property @{
                                        Name = 'Name'
                                        Expression = {$name}
                                    },
                                    @{
                                        Name = 'Version'
                                        Expression = {$_}
                                    }
                                }
                            } | Select-Object Name,Version
                        }
                    }
                }
            },
            @{
                Verb = 'Find'
                Description = 'Find a list of available Homebrew packages'
                OriginalCommandElements = @('search')
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = {
                        param ( $output )

                        if ($output) {

                            $output | Select-String '==>' | Select-Object -ExpandProperty LineNumber | ForEach-Object {
                                # The line numbers from Select-Object start at 1 instead of 0
                                $index = $_ - 1
                                switch -WildCard ($output[$index]) {
                                    '*Formulae*' {
                                        $formulaeStartIndex = $index
                                    }
                                    '*Casks*' {
                                        $casksStartIndex = $index
                                    }
                                }   
                            }
                            
                            # Determine the range of formulae output based on whether we also have cask output
                            $formulaeEndIndex = $(
                                if ($formulaeStartIndex) {
                                    if ($casksStartIndex) {
                                        # Stop capturing formulae output two rows before the start of the Cask index
                                        $casksStartIndex-2
                                    }
                                    else {
                                        # Capture to the entire output
                                        $output.Length
                                    }
                                }
                            )
                            
                            if ($formulaeStartIndex) {
                                $output[($formulaeStartIndex+1)..$formulaeEndIndex] | ForEach-Object {
                                    [PSCustomObject]@{
                                        Name = $_
                                        Type = 'Formula'
                                    }
                                }
                            }
                            
                            if ($casksStartIndex -ne -1) {
                                $output[($casksStartIndex+1)..($output.Length)] | ForEach-Object {
                                    [PSCustomObject]@{
                                        Name = $_
                                        Type = 'Cask'
                                    }
                                }
                            }
                        }
                    }
                }
            },
            @{
                Verb = 'Update'
                Description = 'Updates an installed package to the latest version'
                OriginalCommandElements = @('upgrade')
                OutputHandlers = $PackageInstallHandlers
            },
            @{
                Verb = 'Uninstall'
                Description = 'Uninstall an existing package with Homebrew'
                OriginalCommandElements = @('uninstall')
            }
        )
    },
    @{
        Noun = 'HomebrewPackageInfo'
        Verbs = @(
            @{
                Verb = 'Get'
                Description = 'Shows information on a specific Homebrew package'
                OriginalCommandElements = @('info','--json=v2')
                Parameters = @(
                    @{
                        Name = 'Name'
                        ParameterType = 'string'
                        Description = 'Package Name'
                        ValueFromPipelineByPropertyName = $true
                    },
                    @{
                        Name = 'Formula'
                        OriginalName = '--formula'
                        ParameterType = 'switch'
                        Description = 'Formula'
                    },
                    @{
                        Name = 'Cask'
                        OriginalName = '--cask'
                        ParameterType = 'switch'
                        Description = 'Cask'
                    }
                )
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = {
                        param ( $output )

                        $output | ConvertFrom-Json | ForEach-Object {
                            $_.formulae
                            $_.casks
                        }
                    }
                }
            }
        )
    }
    @{
        Noun = 'HomebrewTapInfo'
        Verbs = @(
            @{
                Verb = 'Get'
                Description = 'Shows information on a specific Homebrew package'
                OriginalCommandElements = @('tap-info','--json')
                Parameters = @(
                    @{
                        Name = 'Name'
                        ParameterType = 'string'
                        Description = 'Package Name'
                        ValueFromPipelineByPropertyName = $true
                    }
                )
                DefaultParameterSetName = 'Default'
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = {
                        param ( $output )

                        $output | ConvertFrom-Json
                    }
                }
            }
        )
    }
)
