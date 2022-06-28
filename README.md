[![CI](https://github.com/ethanbergstrom/Croze/actions/workflows/CI.yml/badge.svg)](https://github.com/ethanbergstrom/Croze/actions/workflows/CI.yml)

# Croze
Croze is a simple PowerShell Crescendo wrapper for Homebrew

## Requirements
In addition to PowerShell 7+ and an Internet connection on a Windows machine, [Homebrew](https://brew.sh/) must also be installed.

## Install Croze
```PowerShell
Install-Module Croze -Force
```

## Sample usages
### Search for a package
```PowerShell
Find-HomebrewPackage -Name jq

Find-HomebrewPackage -Name firefox
```

### Get a package's detailed information from the repository
```PowerShell
Get-HomebrewPackageInfo -Name jq

Find-HomebrewPackage -Name firefox | Get-HomebrewPackageInfo
```

### Get all available versions of a package
```PowerShell
Get-HomebrewPackageInfo -Name jq

Find-HomebrewPackage -Name firefox | Get-HomebrewPackageInfo
```

### Install a package
```PowerShell
Find-HomebrewPackage jq | Install-HomebrewPackage

Install-HomebrewPackage jq
```

### Install a list of packages
```PowerShell
@('jq','firefox') | ForEach-Object { Install-HomebrewPackage $_ }
```


### Get list of installed packages
```PowerShell
Get-HomebrewPackage jq
```

### Upgrade a package
```PowerShell
Update-HomebrewPackage jq
```

### Upgrade a list of packages
```PowerShell
@('jq','firefox') | ForEach-Object { Update-HomebrewPackage -Name $_ }
```

### Upgrade all packages
> :warning: **Use at your own risk!** Homebrew will try to upgrade all layered software it finds, may not always succeed, may upgrade software you don't want upgraded, and may prompt for a password.
```PowerShell
Update-HomebrewPackage
```

### Uninstall a package
```PowerShell
Get-HomebrewPackage jq | Uninstall-HomebrewPackage

Uninstall-HomebrewPackage firefox
```

### Manage package sources
```PowerShell
Register-HomebrewTap pyroscope-io/brew
Find-HomebrewPackage pyroscope-io/brew/pyroscope | Install-HomebrewPackage
Unregister-HomebrewTap pyroscope-io/brew
```

## Legal and Licensing
Croze is licensed under the [MIT license](./LICENSE.txt).
