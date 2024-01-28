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
Find-HomebrewPackage -Name jq -Formula

Find-HomebrewPackage -Name firefox -Cask
```

### Get a package's detailed information from the repository
```PowerShell
Get-HomebrewPackageInfo -Name jq

Find-HomebrewPackage -Name firefox -Cask | Get-HomebrewPackageInfo
```

### Get all available versions of a package
```PowerShell
Get-HomebrewPackageInfo -Name jq

Find-HomebrewPackage -Name firefox -Cask | Get-HomebrewPackageInfo
```

### Install a package
```PowerShell
Find-HomebrewPackage -Name jq -Formula | Install-HomebrewPackage

Install-HomebrewPackage -Name jq -Formula
```

### Get list of installed packages
```PowerShell
Get-HomebrewPackage -Formula
Get-HomebrewPackage -Name firefox -Cask
```

### Upgrade a package
```PowerShell
Update-HomebrewPackage -Name jq -Formula
Update-HomebrewPackage -Name firefox -Cask
```

### Upgrade all packages
> :warning: **Use at your own risk!** Homebrew will try to upgrade all layered software it finds, may not always succeed, may upgrade software you don't want upgraded, and may prompt for a password.
```PowerShell
Update-HomebrewPackage -Formula
Update-HomebrewPackage -Cask
```

### Uninstall a package
```PowerShell
Get-HomebrewPackage -Formula jq | Uninstall-HomebrewPackage

Uninstall-HomebrewPackage -Name firefox -Cask
```

### Manage package sources
```PowerShell
Register-HomebrewTap pyroscope-io/brew
Get-HomebrewTap | Get-HomebrewTapInfo | Select-Object Name, Official, Remote
Find-HomebrewPackage -Name pyroscope-io/brew/pyroscope -Formula | Install-HomebrewPackage
Unregister-HomebrewTap pyroscope-io/brew
```

## Legal and Licensing
Croze is licensed under the [MIT license](./LICENSE.txt).
