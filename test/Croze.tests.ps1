Import-Module Croze

Describe 'basic package search operations' {
	Context 'without additional arguments' {
		It 'gets a list of installed packages' {
			Get-HomeBrewPackage | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with formulae' {
		It 'gets a list of installed packages' {
			Get-HomeBrewPackage -Formula | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with casks' {
		It 'gets a list of installed packages' {
			{Get-HomeBrewPackage -Cask} | Should -Not -Throw
		}
	}
}

Describe 'DSC-compliant package installation and uninstallation' {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'tmux'
		}

		It 'searches for the latest version of a package' {
			Find-HomeBrewPackage -Name $package | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-HomeBrewPackage -Name $package | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-HomeBrewPackage -Name $package | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			{Uninstall-HomeBrewPackage -Name $package} | Should -Not -Throw
		}
	}
	Context 'with formulae' {
		BeforeAll {
			$package = 'tmux'
		}

		It 'searches for the latest version of a package' {
			Find-HomeBrewPackage -Name $package -Formula | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-HomeBrewPackage -Name $package -Formula | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-HomeBrewPackage -Name $package -Formula | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'does NOT find the locally installed package just installed with the wrong type flag' {
			Get-HomeBrewPackage -Name $package -Cask | Where-Object {$_.Name -eq $package} | Should -BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			{Uninstall-HomeBrewPackage -Name $package -Formula} | Should -Not -Throw
		}
	}
	Context 'with casks' {
		BeforeAll {
			$package = 'discord'
		}

		It 'searches for the latest version of a package' {
			Find-HomeBrewPackage -Name $package -Cask | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-HomeBrewPackage -Name $package -Cask | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-HomeBrewPackage -Name $package -Cask | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'does NOT find the locally installed package just installed with the wrong type flag' {
			Get-HomeBrewPackage -Name $package -Formula | Where-Object {$_.Name -eq $package} | Should -BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			{Uninstall-HomeBrewPackage -Name $package -Cask} | Should -Not -Throw
		}
	}
}

Describe 'pipline-based package installation and uninstallation' {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'tmux'
		}

		It 'searches for and silently installs the latest version of a package' {
			Find-HomeBrewPackage -Name $package | Where-Object {$_.Name -eq $package} | Install-HomeBrewPackage | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			{Get-HomeBrewPackage -Name $package | Uninstall-HomeBrewPackage} | Should -Not -Throw
		}
	}
	Context 'with formulae' {
		BeforeAll {
			$package = 'tmux'
		}

		It 'searches for and silently installs the latest version of a package' {
			Find-HomeBrewPackage -Name $package -Formula | Where-Object {$_.Name -eq $package} | Install-HomeBrewPackage | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			{Get-HomeBrewPackage -Name $package -Formula | Uninstall-HomeBrewPackage} | Should -Not -Throw
		}
	}
	Context 'with casks' {
		BeforeAll {
			$package = 'discord'
		}

		It 'searches for and silently installs the latest version of a package' {
			Find-HomeBrewPackage -Name $package -Cask | Where-Object {$_.Name -eq $package} | Install-HomeBrewPackage | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			{Get-HomeBrewPackage -Name $package -Cask | Uninstall-HomeBrewPackage} | Should -Not -Throw
		}
	}
}

# Not test-able, since Brew doesn't support specifying an initial version to install
# Describe 'package upgrade' {
# 	Context 'with formulae' {
# 		BeforeAll {
# 			$package = 'tmux'
# 			$version = '1.95'
# 			Install-HomeBrewPackage -Name $package -Version $version
# 		}
# 		AfterAll {
# 			Uninstall-HomeBrewPackage -Name $package
# 		}

# 		It 'upgrades a specific package to the latest version' {
# 			Update-HomeBrewPackage -Name $package | Where-Object {$_.Name -eq $package} | Where-Object {[version]$_.version -gt [version]$version} | Should -Not -BeNullOrEmpty
# 		}
# 		It 'upgrades again, and returns no output, because everything is up to date' {
# 			Update-HomeBrewPackage -Name $package | Where-Object {$_.Name -eq $package} | Where-Object {[version]$_.version -gt [version]$version} | Should -BeNullOrEmpty
# 		}
# 	}
# }

# Describe 'HomeBrew error handling' {
# 	Context 'with formulae' {
# 		BeforeAll {
# 			$package = 'Cisco.*'
# 		}

# 		It 'searches for an ID that will never exist' {
# 			{Find-HomeBrewPackage -Name $package} | Should -Not -Throw
# 		}
# 		It 'searches for an ID that will never exist' {
# 			{Get-HomeBrewPackage -Name $package} | Should -Not -Throw
# 		}
# 	}
# }

Describe 'package metadata retrieval' {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'tmux'
		}

		It 'returns package metadata' {
			Get-HomeBrewPackageInfo -Name $package | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with formulae' {
		BeforeAll {
			$package = 'tmux'
		}

		It 'returns package metadata' {
			Get-HomeBrewPackageInfo -Name $package -Formula | Where-Object {$_.Name -eq $package} | Should -Not -BeNullOrEmpty
		}
	}
	Context 'with casks' {
		BeforeAll {
			$package = 'discord'
		}

		It 'returns package metadata' {
			Get-HomeBrewPackageInfo -Name $package -Cask | Where-Object {$_.Token -eq $package} | Should -Not -BeNullOrEmpty
		}
	}
}
