$BaseOriginalName = 'brew'

$BaseOriginalCommandElements = @()

$BaseParameters = @()

$BaseOutputHandlers = @{
    ParameterSetName = 'Default'
    Handler = {
        param ( $output )
    }
}

# The general structure of this hashtable is to define noun-level attributes, which are -probably- common across all commands for the same noun, but still allow for customization at more specific verb-level defition for that noun.
# The following three command attributes have the following order of precedence:
# 	OriginalCommandElements will be MERGED in the order of Noun + Verb + Base
#		Example: Noun HomeBrewSource's element 'source', Verb Register's element 'add', and Base elements are merged to become 'HomeBrew source add --limit-output --yes'
# 	Parameters will be MERGED in the order of Noun + Verb + Base
#		Example: Noun HomeBrewPackage's parameters for package name and version and Verb Install's parameter specifying source information are merged to become '<packageName> --version=<packageVersion> --source=<packageSource>'.
#			These are then appended to the merged original command elements, to create 'HomeBrew install <packageName> --version=<packageVersion> --source=<packageSource> --limit-output --yes'
# 	OutputHandler sets will SUPERCEDE each other in the order of: Verb -beats-> Noun -beats-> Base. This allows reusability of PowerShell parsing code.
#		Example: Noun HomeBrewPackage has inline output handler PowerShell code with complex regex that works for both Install-HomeBrewPackage and Uninstall-HomeBrewPackage, but Get-HomeBrewPackage's native output uses simple vertical bar delimiters.
#		Example 2: The native commands for Register-HomeBrewSource and Unregister-HomeBrewSource don't return any output, and until Crescendo supports error handling by exit codes, a base required default output handler that doesn't do anything can be defined and reused in multiple places.
$Commands = @(
    @{
        Noun = 'HomeBrewPackage'
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
                Description = 'Install a new package with HomeBrew'
                OriginalCommandElements = @('install')
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = {
                        param ( $output )

                        if ($output -match 'Pouring') {
                            # Formula output - capture package and dependency name and version
                            $output | Select-String 'Pouring (?<name>\S+)(?=--)--(?<version>\d+\.{0,1}\d*\.(?=\d)\d*)' | ForEach-Object -MemberName Matches | ForEach-Object {
                                $match = ($_.Groups | Select-Object -Skip 1).Value

                                [PSCustomObject]@{
                                    Name = $match[0]
                                    Version = $match[1]
                                }
                            }
                        } elseif ($output -match 'was successfully') {
                            # Cask output - capture package only
                            $output | Select-String '(?<name>\S+) was successfully' | ForEach-Object -MemberName Matches | ForEach-Object {
                                $match = ($_.Groups | Select-Object -Skip 1).Value
                                [PSCustomObject]@{
                                    Name = $match
                                }
                            }
                        }
                    }
                }
            },
            @{
                Verb = 'Get'
                Description = 'Get a list of installed HomeBrew packages'
                OriginalCommandElements = @('list','--versions')
                DefaultParameterSetName = 'Default'
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
                Description = 'Find a list of available HomeBrew packages'
                OriginalCommandElements = @('search')
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = {
                        param ( $output )

                        # Do we have formulae in the results?
                        $formulaeStartIndex = $output.IndexOf('==> Formulae')
                        
                        # Do we have casks in the results?
                        $casksStartIndex = $output.IndexOf('==> Casks')
                        
                        # Determine the range of formulae output based on whether we also have cask output
                        $formulaeEndIndex = $(
                            if ($formulaeStartIndex -ne -1) {
                                if ($casksStartIndex -ne -1) {
                                    # Stop capturing formulae output two rows before the start of the Cask index
                                    $casksStartIndex-2
                                }
                                else {
                                    # Capture to the entire output
                                    $output.Length
                                }
                            }
                        )
                        
                        if ($formulaeStartIndex -ne -1) {
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
            },
            @{
                Verb = 'Update'
                Description = 'Updates an installed package to the latest version'
                OriginalCommandElements = @('upgrade')
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = {
                        param ( $output )

                        if ($output -match 'Pouring') {
                            # Formula output - capture package and dependency name and version
                            $packageInfo = @{}

                            $output | Select-String 'Pouring (?<name>\S+)(?=--)--(?<version>\d+\.{0,1}\d*\.(?=\d)\d*)' | ForEach-Object -MemberName Matches | ForEach-Object {
                                $match = ($_.Groups | Select-Object -Skip 1).Value
                                $packageInfo.add($match[0],$match[1])
                            }

                            $packageInfo
                        } elseif ($output -match 'was successfully') {
                            # Successful Cask output. We should be able to get the new version of the upgraded package
                            $output | Select-String '(?<name>\S+) (?<oldVerison>\S+) -> (?<version>\d+\.{0,1}\d*\.(?=\d)\d*)' | ForEach-Object -MemberName Matches | ForEach-Object {
                                $match = ($_.Groups | Select-Object -Skip 1).Value
                                $packageInfo.add($match[0],$match[1])
                            }

                            $packageInfo
                        } else {
                            # Cask output - does not have much useful output other than if installation fails
                            if ($output) {Write-Error ($output)}
                        }
                    }
                }
            },
            @{
                Verb = 'Uninstall'
                Description = 'Uninstall an existing package with HomeBrew'
                OriginalCommandElements = @('uninstall')
            }
        )
    },
    @{
        Noun = 'HomeBrewPackageInfo'
        Verbs = @(
            @{
                Verb = 'Get'
                Description = 'Shows information on a specific HomeBrew package'
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
                DefaultParameterSetName = 'Default'
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = {
                        param ( $output )

                        $result = @()

                        $result += $output | ConvertFrom-Json | Select-Object -ExpandProperty formulae
                        $result += $output | ConvertFrom-Json | Select-Object -ExpandProperty casks

                        $result
                    }
                }
            }
        )
    }
)
