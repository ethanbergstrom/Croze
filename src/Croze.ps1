$BaseOriginalName = 'brew'

$BaseOriginalCommandElements = @()

$BaseParameters = @()

$BaseOutputHandlers = @{
    ParameterSetName = 'Default'
    Handler          = {
        param ( $output )

        # Clear the Crescendo stderr queue of Homebrew's abuse of stderr
        Pop-CrescendoNativeError
    }
}

$PackageInstallHandlers = @(
    @{
        ParameterSetName = 'Formula'
        Handler          = {
            param ( $output )

            # Clear the Crescendo stderr queue of Homebrew's abuse of stderr
            Pop-CrescendoNativeError

            $output | Select-String '🍺(.+)/(?<name>.+)/(?<version>.+):' | ForEach-Object -MemberName Matches | ForEach-Object {
                $match = ($_.Groups | Where-Object Name -in 'name', 'version').Value

                [PSCustomObject]@{
                    Name    = $match[0]
                    Version = $match[1]
                }
            }
        }
    },
    @{
        ParameterSetName = 'Cask'
        Handler          = {
            param ( $output )

            # Clear the Crescendo stderr queue of Homebrew's abuse of stderr
            Pop-CrescendoNativeError

            $output | Select-String '(?<name>\S+) was successfully' | ForEach-Object -MemberName Matches | ForEach-Object {
                $match = ($_.Groups | Where-Object Name -eq 'name').Value
                [PSCustomObject]@{
                    Name = $match
                }
            }
        }
    }
)

# The general structure of this hashtable is to define noun-level attributes, which are -probably- common across all commands for the same noun, but still allow for customization at more specific verb-level defition for that noun.
# The following three command attributes have the following order of precedence:`
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
        Noun  = 'HomebrewTap'
        Verbs = @(
            @{
                Verb                    = 'Get'
                Description             = 'Return Homebrew taps'
                OriginalCommandElements = @('tap')
                OutputHandlers          = @{
                    ParameterSetName = 'Default'
                    Handler          = {
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
                Verb                    = 'Register'
                Description             = 'Register a new Homebrew tap'
                OriginalCommandElements = @('tap')
                Parameters              = @(
                    @{
                        Name          = 'Name'
                        ParameterType = 'string'
                        Description   = 'Source Name'
                        Mandatory     = $true
                    },
                    @{
                        Name          = 'Location'
                        ParameterType = 'string'
                        Description   = 'Source Location'
                    }
                )
            },
            @{
                Verb                    = 'Unregister'
                Description             = 'Unregister an existing Homebrew tap'
                OriginalCommandElements = @('untap', '-f')
                Parameters              = @(
                    @{
                        Name                            = 'Name'
                        ParameterType                   = 'string'
                        Description                     = 'Source Name'
                        Mandatory                       = $true
                        ValueFromPipelineByPropertyName = $true
                    }
                )
            }
        )
    },
    @{
        Noun       = 'HomebrewPackage'
        Parameters = @(
            @{
                Name                            = 'Name'
                ParameterType                   = 'string'
                Description                     = 'Package Name'
                ValueFromPipelineByPropertyName = $true
                ParameterSetName                = @('Formula', 'Cask')
            },
            @{
                Name                            = 'Formula'
                OriginalName                    = '--formula'
                ParameterType                   = 'switch'
                Description                     = 'Formula'
                ValueFromPipelineByPropertyName = $true
                ParameterSetName                = 'Formula'
            },
            @{
                Name                            = 'Cask'
                OriginalName                    = '--cask'
                ParameterType                   = 'switch'
                Description                     = 'Cask'
                ValueFromPipelineByPropertyName = $true
                ParameterSetName                = 'Cask'
            }
        )
        Verbs      = @(
            @{
                Verb                    = 'Install'
                Description             = 'Install a new package with Homebrew'
                OriginalCommandElements = @('install')
                OutputHandlers          = $PackageInstallHandlers
                Parameters              = @(
                    @{
                        Name             = 'Force'
                        OriginalName     = '--force'
                        ParameterType    = 'switch'
                        Description      = 'Force'
                        ParameterSetName = @('Formula', 'Cask')
                    }
                )
            },
            @{
                Verb                    = 'Get'
                Description             = 'Get a list of installed Homebrew packages'
                OriginalCommandElements = @('list', '--versions')
                OutputHandlers          = @(
                    @{
                        ParameterSetName = 'Formula'
                        Handler          = {
                            param ( $output )
                        
                            $output | Where-Object { $_ } | ConvertFrom-StringData -Delimiter ' ' | ForEach-Object {
                                # Brew supports installing multiple versions side-by-side, but instead of listing them as separate rows, it puts multiple versions on the same row. 
                                # To present this package data in a way that's idiomatic to PowerShell, we need to list each version as a separate object:
                                $_.GetEnumerator() | ForEach-Object {
                                    $name = $_.Name
                                    $_.Value -split ' ' | Select-Object -Property @{
                                        Name       = 'Name'
                                        Expression = { $name }
                                    },
                                    @{
                                        Name       = 'Version'
                                        Expression = { $_ }
                                    },
                                    @{
                                        Name       = 'Formula'
                                        Expression = { $true }
                                    }
                                }
                            }
                        }
                    },
                    @{
                        ParameterSetName = 'Cask'
                        Handler          = {
                            param ( $output )
                        
                            $output | Where-Object { $_ } | ConvertFrom-StringData -Delimiter ' ' | ForEach-Object {
                                # Brew supports installing multiple versions side-by-side, but instead of listing them as separate rows, it puts multiple versions on the same row. 
                                # To present this package data in a way that's idiomatic to PowerShell, we need to list each version as a separate object:
                                $_.GetEnumerator() | ForEach-Object {
                                    $name = $_.Name
                                    $_.Value -split ' ' | Select-Object -Property @{
                                        Name       = 'Name'
                                        Expression = { $name }
                                    },
                                    @{
                                        Name       = 'Version'
                                        Expression = { $_ }
                                    },
                                    @{
                                        Name       = 'Cask'
                                        Expression = { $true }
                                    }
                                }
                            }
                        }
                    }
                )
            },
            @{
                Verb                    = 'Find'
                Description             = 'Find a list of available Homebrew packages'
                OriginalCommandElements = @('search')
                OutputHandlers          = @(
                    @{
                        ParameterSetName = 'Formula'
                        Handler          = {
                            param ($output)

                            $output | ForEach-Object {
                                [PSCustomObject]@{
                                    Name    = $_
                                    Formula = $true
                                }
                            }
                        }
                    },
                    @{
                        ParameterSetName = 'Cask'
                        Handler          = {
                            param ($output)

                            $output | ForEach-Object {
                                [PSCustomObject]@{
                                    Name = $_
                                    Cask = $true
                                }
                            }
                        }
                    }
                )
            },
            @{
                Verb                    = 'Update'
                Description             = 'Updates an installed package to the latest version'
                OriginalCommandElements = @('upgrade')
                OutputHandlers          = $PackageInstallHandlers
            },
            @{
                Verb                    = 'Uninstall'
                Description             = 'Uninstall an existing package with Homebrew'
                OriginalCommandElements = @('uninstall')
            }
        )
    },
    @{
        Noun  = 'HomebrewPackageInfo'
        Verbs = @(
            @{
                Verb                    = 'Get'
                Description             = 'Shows information on a specific Homebrew package'
                OriginalCommandElements = @('info', '--json=v2')
                Parameters              = @(
                    @{
                        Name                            = 'Name'
                        ParameterType                   = 'string'
                        Description                     = 'Package Name'
                        ValueFromPipelineByPropertyName = $true
                    },
                    @{
                        Name          = 'Formula'
                        OriginalName  = '--formula'
                        ParameterType = 'switch'
                        Description   = 'Formula'
                    },
                    @{
                        Name          = 'Cask'
                        OriginalName  = '--cask'
                        ParameterType = 'switch'
                        Description   = 'Cask'
                    }
                )
                OutputHandlers          = @{
                    ParameterSetName = 'Default'
                    Handler          = {
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
        Noun  = 'HomebrewTapInfo'
        Verbs = @(
            @{
                Verb                    = 'Get'
                Description             = 'Shows information on a specific Homebrew package'
                OriginalCommandElements = @('tap-info', '--json')
                Parameters              = @(
                    @{
                        Name                            = 'Name'
                        ParameterType                   = 'string'
                        Description                     = 'Package Name'
                        ValueFromPipelineByPropertyName = $true
                    }
                )
                DefaultParameterSetName = 'Default'
                OutputHandlers          = @{
                    ParameterSetName = 'Default'
                    Handler          = {
                        param ( $output )

                        $output | ConvertFrom-Json
                    }
                }
            }
        )
    }
)
