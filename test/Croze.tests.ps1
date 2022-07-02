Import-Module Croze

Describe 'basic package search operations' {
	Context 'without additional arguments' {
		It 'gets a list of installed packages' {
			Get-HomebrewPackage | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with formulae' {
		It 'gets a list of installed packages' {
			Get-HomebrewPackage -Formula | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with casks' {
		It 'gets a list of installed packages' {
			{Get-HomebrewPackage -Cask} | Should -Not -Throw
		}
	}
}

Describe 'DSC-compliant package installation and uninstallation' {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'tmux'
		}

		It 'searches for the latest version of a package' {
			Find-HomebrewPackage -Name $package | Where-Object {$_.Name -eq $package} | Should -HaveCount 1
		}
		It 'silently installs the latest version of a package' {
			Install-HomebrewPackage -Name $package | Where-Object {$_.Name -eq $package} | Should -HaveCount 1
		}
		It 'finds the locally installed package just installed' {
			Get-HomebrewPackage -Name $package | Where-Object {$_.Name -eq $package} | Should -HaveCount 1
		}
		It 'silently uninstalls the locally installed package just installed' {
			{Uninstall-HomebrewPackage -Name $package} | Should -Not -Throw
		}
	}
	Context 'with formulae' {
		BeforeAll {
			$package = 'tmux'
		}

		It 'searches for the latest version of a package' {
			Find-HomebrewPackage -Name $package -Formula | Where-Object {$_.Name -eq $package} | Should -HaveCount 1
		}
		It 'silently installs the latest version of a package' {
			Install-HomebrewPackage -Name $package -Formula | Where-Object {$_.Name -eq $package} | Should -HaveCount 1
		}
		It 'finds the locally installed package just installed' {
			Get-HomebrewPackage -Name $package -Formula | Where-Object {$_.Name -eq $package} | Should -HaveCount 1
		}
		It 'does NOT find the locally installed package just installed with the wrong type flag' {
			Get-HomebrewPackage -Name $package -Cask | Where-Object {$_.Name -eq $package} | Should -BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			{Uninstall-HomebrewPackage -Name $package -Formula} | Should -Not -Throw
		}
	}
	Context 'with casks' {
		BeforeAll {
			$package = 'discord'
		}

		It 'searches for the latest version of a package' {
			Find-HomebrewPackage -Name $package -Cask | Where-Object {$_.Name -eq $package} | Should -HaveCount 1
		}
		It 'silently installs the latest version of a package' {
			Install-HomebrewPackage -Name $package -Cask | Where-Object {$_.Name -eq $package} | Should -HaveCount 1
		}
		It 'finds the locally installed package just installed' {
			Get-HomebrewPackage -Name $package -Cask | Where-Object {$_.Name -eq $package} | Should -HaveCount 1
		}
		It 'does NOT find the locally installed package just installed with the wrong type flag' {
			Get-HomebrewPackage -Name $package -Formula | Where-Object {$_.Name -eq $package} | Should -BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			{Uninstall-HomebrewPackage -Name $package -Cask} | Should -Not -Throw
		}
	}
}

Describe 'pipline-based package installation and uninstallation' {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'tmux'
		}

		It 'searches for and silently installs the latest version of a package' {
			Find-HomebrewPackage -Name $package | Where-Object {$_.Name -eq $package} | Install-HomebrewPackage | Should -HaveCount 1
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			{Get-HomebrewPackage -Name $package | Uninstall-HomebrewPackage} | Should -Not -Throw
		}
	}
	Context 'with formulae' {
		BeforeAll {
			$package = 'tmux'
		}

		It 'searches for and silently installs the latest version of a package' {
			Find-HomebrewPackage -Name $package -Formula | Where-Object {$_.Name -eq $package} | Install-HomebrewPackage | Should -HaveCount 1
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			{Get-HomebrewPackage -Name $package -Formula | Uninstall-HomebrewPackage} | Should -Not -Throw
		}
	}
	Context 'with casks' {
		BeforeAll {
			$package = 'discord'
		}

		It 'searches for and silently installs the latest version of a package' {
			Find-HomebrewPackage -Name $package -Cask | Where-Object {$_.Name -eq $package} | Install-HomebrewPackage | Should -HaveCount 1
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			{Get-HomebrewPackage -Name $package -Cask | Uninstall-HomebrewPackage} | Should -Not -Throw
		}
	}
}

# Not test-able, since Brew doesn't support specifying an initial version to install
# Describe 'package upgrade' {
# 	Context 'with formulae' {
# 		BeforeAll {
# 			$package = 'tmux'
# 			$version = '1.95'
# 			Install-HomebrewPackage -Name $package -Version $version
# 		}
# 		AfterAll {
# 			Uninstall-HomebrewPackage -Name $package
# 		}

# 		It 'upgrades a specific package to the latest version' {
# 			Update-HomebrewPackage -Name $package | Where-Object {$_.Name -eq $package} | Where-Object {[version]$_.version -gt [version]$version} | Should -Not -BeNullOrEmpty
# 		}
# 		It 'upgrades again, and returns no output, because everything is up to date' {
# 			Update-HomebrewPackage -Name $package | Where-Object {$_.Name -eq $package} | Where-Object {[version]$_.version -gt [version]$version} | Should -BeNullOrEmpty
# 		}
# 	}
# }

# Describe 'Homebrew error handling' {
# 	Context 'with formulae' {
# 		BeforeAll {
# 			$package = 'Cisco.*'
# 		}

# 		It 'searches for an ID that will never exist' {
# 			{Find-HomebrewPackage -Name $package} | Should -Not -Throw
# 		}
# 		It 'searches for an ID that will never exist' {
# 			{Get-HomebrewPackage -Name $package} | Should -Not -Throw
# 		}
# 	}
# }

Describe "multi-source support" {
	BeforeAll {
		$tapName = 'pyroscope-io/brew'
		$tapLocation = 'https://github.com/pyroscope-io/homebrew-brew'
		$package = join-path -path $tapName -ChildPath 'pyroscope'
	}

	It 'registers an alternative tap, assuming just GitHub userame' {
		{ Register-HomebrewTap -Name $tapName } | Should -Not -Throw
		Get-HomebrewTap | Where-Object {$_.Name -eq $tapName} | Should -HaveCount 1
	}
	It 'returns tap location information' {
		Get-HomebrewTapInfo -Name $tapName | Select-Object -ExpandProperty remote | Should -Be $tapLocation
	}
	It 'searches for and installs the latest version of a package from an alternate source' {
		Find-HomebrewPackage -Name $package | Should -Not -BeNullOrEmpty
		Install-HomebrewPackage -Name $package | Should -HaveCount 1
	}
	It 'finds and uninstalls a package installed from an alternate source' {
		{ Get-HomebrewPackage -Name $package | Uninstall-HomebrewPackage } | Should -Not -Throw
	}
	It 'unregisters an alternative tap with a full URL' {
		Unregister-HomebrewTap -Name $tapName
		Get-HomebrewTap | Where-Object {$_.Name -eq $tapName} | Should -BeNullOrEmpty
	}
}

Describe 'package metadata retrieval' {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'tmux'
		}

		It 'returns package metadata' {
			Get-HomebrewPackageInfo -Name $package | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with formulae' {
		BeforeAll {
			$package = 'tmux'
		}

		It 'returns package metadata' {
			Get-HomebrewPackageInfo -Name $package -Formula | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with casks' {
		BeforeAll {
			$package = 'discord'
		}

		It 'returns package metadata' {
			Get-HomebrewPackageInfo -Name $package -Cask | Where-Object {$_.Token -eq $package} | Should -Not -BeNullOrEmpty
		}
	}
}
