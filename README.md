[![CI](https://github.com/ethanbergstrom/Croze/actions/workflows/CI.yml/badge.svg)](https://github.com/ethanbergstrom/Croze/actions/workflows/CI.yml)

# Croze
Croze is a simple PowerShell Crescendo wrapper for HomeBrew

## Requirements
In addition to PowerShell 7+ and an Internet connection on a Windows machine, [HomeBrew](https://brew.sh/) must also be installed.

## Install Croze
```PowerShell
Install-Module Croze -Force
```

## Sample usages
### Search for a package
```PowerShell
Find-HomeBrewPackage -Name jq

Find-HomeBrewPackage -Name firefox
```

### Get a package's detailed information from the repository
```PowerShell
Get-HomeBrewPackageInfo -Name jq

Find-HomeBrewPackage -Name firefox | Get-HomeBrewPackageInfo
```

### Get all available versions of a package
```PowerShell
Get-HomeBrewPackageInfo -Name jq

Find-HomeBrewPackage -Name firefox | Get-HomeBrewPackageInfo
```

### Install a package
```PowerShell
Find-HomeBrewPackage jq | Install-HomeBrewPackage

Install-HomeBrewPackage jq
```

### Install a list of packages
```PowerShell
@('jq','firefox') | ForEach-Object { Install-HomeBrewPackage $_ }
```


### Get list of installed packages
```PowerShell
Get-HomeBrewPackage jq
```

### Upgrade a package
```PowerShell
Update-HomeBrewPackage jq
```

### Upgrade a list of packages
```PowerShell
@('jq','firefox') | ForEach-Object { Update-HomeBrewPackage -Name $_ }
```

### Upgrade all packages
> :warning: **Use at your own risk!** HomeBrew will try to upgrade all layered software it finds, may not always succeed, may upgrade software you don't want upgraded, and may prompt for a password.
```PowerShell
Update-HomeBrewPackage
```

### Uninstall a package
```PowerShell
Get-HomeBrewPackage jq | Uninstall-HomeBrewPackage

Uninstall-HomeBrewPackage firefox
```

### Manage package sources
```PowerShell
Register-HomeBrewTap pyroscope-io/brew
Find-HomeBrewPackage pyroscope-io/brew/pyroscope | Install-HomeBrewPackage
Unregister-HomeBrewTap pyroscope-io/brew
```

## Legal and Licensing
Croze is licensed under the [MIT license](./LICENSE.txt).
