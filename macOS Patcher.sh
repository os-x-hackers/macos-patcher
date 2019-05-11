
#!/bin/sh

parameters="${1}${2}${3}${4}${5}${6}${7}${8}${9}"

Escape_Variables()
{
	text_progress="\033[38;5;113m"
	text_success="\033[38;5;113m"
	text_warning="\033[38;5;221m"
	text_error="\033[38;5;203m"
	text_message="\033[38;5;75m"

	text_bold="\033[1m"
	text_faint="\033[2m"
	text_italic="\033[3m"
	text_underline="\033[4m"

	erase_style="\033[0m"
	erase_line="\033[0K"

	move_up="\033[1A"
	move_down="\033[1B"
	move_foward="\033[1C"
	move_backward="\033[1D"
}

Parameter_Variables()
{
	if [[ $parameters == *"-v"* || $parameters == *"-verbose"* ]]; then
		verbose="1"
		set -x
	fi
	
	if [[ $parameters == *"-m-pk"* || $parameters == *"-modern-prelinkedkernel"* ]]; then
		modern_prelinkedkernel="1"
	fi
}

Path_Variables()
{
	script_path="${0}"
	directory_path="${0%/*}"

	resources_path="$directory_path/resources"

	system_version_path="System/Library/CoreServices/SystemVersion.plist"
	
	installer_system_macos="/Volumes/macOS Base System"
	installer_system_macosx="/Volumes/Mac OS X Base System"
	installer_system_osx="/Volumes/OS X Base System"

	installer_packages_image="/tmp/Installer Packages"
	installer_system_image="/tmp/Installer System"
}

Input_Off()
{
	stty -echo
}
Input_On()
{
	stty echo
}

Output_Off() {
	if [[ $verbose == "1" ]]; then
		"$@"
	else
		"$@" &>/dev/null
	fi
}

Check_Environment()
{
	echo ${text_progress}"> Checking system environment."${erase_style}
	if [ -d /Install\ *.app ]; then
		environment="installer"
	fi
	if [ ! -d /Install\ *.app ]; then
		environment="system"
	fi
	echo ${move_up}${erase_line}${text_success}"+ Checked system environment."${erase_style}
}

Check_Root()
{
	echo ${text_progress}"> Checking for root permissions."${erase_style}
	if [[ $environment == "installer" ]]; then
		root_check="passed"
		echo ${move_up}${erase_line}${text_success}"+ Root permissions check passed."${erase_style}
	else
		if [[ $(whoami) == "root" && $environment == "system" ]]; then
			root_check="passed"
			echo ${move_up}${erase_line}${text_success}"+ Root permissions check passed."${erase_style}
		fi
		if [[ ! $(whoami) == "root" && $environment == "system" ]]; then
			root_check="failed"
			echo ${text_error}"- Root permissions check failed."${erase_style}
			echo ${text_message}"/ Run this tool with root permissions."${erase_style}
			Input_On
			exit
		fi
	fi
}

Check_Resources()
{
	echo ${text_progress}"> Checking for resources."${erase_style}
	if [[ -d "$resources_path" ]]; then
		resources_check="passed"
		echo ${move_up}${erase_line}${text_success}"+ Resources check passed."${erase_style}
	fi
	if [[ ! -d "$resources_path" ]]; then
		resources_check="failed"
		echo ${text_error}"- Resources check failed."${erase_style}
		echo ${text_message}"/ Run this tool with the required resources."${erase_style}
		Input_On
		exit
	fi

	if [[ -d "$resources_path"/prelinkedkernel-modern ]]; then
		modern_prelinkedkernel_check="1"
	fi
}

Input_Operation()
{
	echo ${text_message}"/ What operation would you like to run?"${erase_style}
	echo ${text_message}"/ Input an operation number."${erase_style}
	echo ${text_message}"/     1 - Patch installer"${erase_style}
	echo ${text_message}"/     2 - Patch update"${erase_style}
	Input_On
	read -e -p "/ " operation
	Input_Off

	if [[ $operation == "1" ]]; then
		Input_Installer
		Check_Installer_Stucture
		Check_Installer_Version
		Check_Installer_Support
		Input_Volume
		Create_Installer
		Patch_Installer
		Repair_Permissions
	fi
	if [[ $operation == "2" ]]; then
		Input_Package
		Patch_Package
	fi
}

Input_Installer()
{
	echo ${text_message}"/ What installer would you like to use?"${erase_style}
	echo ${text_message}"/ Input an installer path."${erase_style}

	Input_On
	read -e -p "/ " installer_application_path
	Input_Off

	installer_images_path="$installer_application_path/Contents/SharedSupport"
}

Check_Installer_Stucture()
{
	Output_Off hdiutil attach "$installer_images_path"/InstallESD.dmg -mountpoint "$installer_packages_image" -nobrowse

	echo ${text_progress}"> Checking installer structure."${erase_style}
	if [[ -e "$installer_packages_image"/BaseSystem.dmg ]]; then
		installer_contents="1"
	fi
	if [[ -e "$installer_packages_image"/AppleDiagnostics.dmg ]]; then
		installer_contents="2"
	fi
	if [[ -e "$installer_images_path"/BaseSystem.dmg ]]; then
		installer_contents="3"
	fi
	echo ${move_up}${erase_line}${text_success}"+ Checked installer structure."${erase_style}

	echo ${text_progress}"> Mounting installer disk images."${erase_style}
	if [[ $installer_contents == "1" || $installer_contents == "2" ]]; then
		Output_Off hdiutil attach "$installer_packages_image"/BaseSystem.dmg -mountpoint "$installer_system_image" -nobrowse
	fi
	if [[ $installer_contents == "3" ]]; then
		Output_Off hdiutil attach "$installer_images_path"/BaseSystem.dmg -mountpoint "$installer_system_image" -nobrowse
	fi
	echo ${move_up}${erase_line}${text_success}"+ Mounted installer disk images."${erase_style}
}

Check_Installer_Version()
{
	echo ${text_progress}"> Checking installer version."${erase_style}	
	installer_version="$(grep -A1 "ProductVersion" "$installer_system_image/$system_version_path")"

	installer_version="${installer_version#*<string>}"
	installer_version="${installer_version%</string>*}"

	installer_version_short="${installer_version:0:5}"
	echo ${move_up}${erase_line}${text_success}"+ Checked installer version."${erase_style}	
}

Check_Installer_Support()
{
	echo ${text_progress}"> Checking installer support."${erase_style}
	if [[ $installer_version_short == "10.13" || $installer_version_short == "10.14" ]]; then
		installer_patch_required="1"
	fi
	if [[ $installer_version_short == "10.12" || $installer_version_short == "10.13" ]]; then
		installer_patch_supported="1"
	fi

	if [[ $installer_version == "10.12" ]]; then
		installer_prelinkedkernel="10.12"
	fi
	if [[ $installer_version == "10.12.1" || $installer_version == "10.12.2" || $installer_version == "10.12.3" ]]; then
		installer_prelinkedkernel="10.12.1"
	fi
	if [[ $installer_version == "10.12.4" || $installer_version == "10.12.5" || $installer_version == "10.12.6" ]]; then
		installer_prelinkedkernel="10.12.4"
	fi

	if [[ $installer_version == "10.13" || $installer_version == "10.13.1" || $installer_version == "10.13.2" || $installer_version == "10.13.3" ]]; then
		installer_prelinkedkernel="10.13"
	fi
	if [[ $installer_version == "10.13.4" || $installer_version == "10.13.5" || $installer_version == "10.13.6" ]]; then
		installer_prelinkedkernel="10.13.4"
	fi

	if [[ $installer_version == "10.14" ]]; then
		installer_prelinkedkernel="10.14"
		installer_patch_supported="1"
	fi
	if [[ $installer_version == "10.14.1" || $installer_version == "10.14.2" || $installer_version == "10.14.3" ]]; then
		installer_prelinkedkernel="10.14.1"
		installer_patch_supported="1"
	fi
	if [[ $installer_version == "10.14.4" ]]; then
		installer_prelinkedkernel="10.14.4"
		installer_patch_supported="1"
	fi

	if [[ $installer_patch_supported == "1" ]]; then
		echo ${move_up}${erase_line}${text_success}"+ Installer support check passed."${erase_style}
	fi
	if [[ ! $installer_patch_supported == "1" ]]; then
		echo ${text_error}"- Installer support check failed."${erase_style}
		echo ${text_message}"/ Run this tool with a supported installer."${erase_style}
		Input_On
		exit
	fi
}

Input_Volume()
{
	echo ${text_message}"/ What volume would you like to use?"${erase_style}
	echo ${text_message}"/ Input a volume name."${erase_style}
	for volume_path in /Volumes/*; do 
		volume_name="${volume_path#/Volumes/}"
		if [[ ! "$volume_name" == com.apple* ]]; then
			echo ${text_message}"/     ${volume_name}"${erase_style} | sort -V
		fi
	done
	Input_On
	read -e -p "/ " installer_volume_name
	Input_Off

	installer_volume_path="/Volumes/$installer_volume_name"
}

Create_Installer()
{
	echo ${text_progress}"> Restoring installer disk image."${erase_style}
	if [[ $installer_contents == "1" || $installer_contents == "2" ]]; then
		Output_Off asr restore -source "$installer_packages_image"/BaseSystem.dmg -target "$installer_volume_path" -noprompt -noverify -erase
	fi
	if [[ $installer_contents == "3" ]]; then
		Output_Off asr restore -source "$installer_images_path"/BaseSystem.dmg -target "$installer_volume_path" -noprompt -noverify -erase
	fi
	sleep 1
	echo ${move_up}${erase_line}${text_success}"+ Restored installer disk image."${erase_style}

	echo ${text_progress}"> Renaming installer volume."${erase_style}
	if [[ -d "$installer_system_macosx" ]]; then
		Output_Off diskutil rename "$installer_system_macosx" "$installer_volume_name"
	fi
	if [[ -d "$installer_system_osx" ]]; then
		Output_Off diskutil rename "$installer_system_osx" "$installer_volume_name"
	fi
	if [[ -d "$installer_system_macos" ]]; then
		Output_Off diskutil rename "$installer_system_macos" "$installer_volume_name"
	fi
		bless --folder "$installer_volume_path"/System/Library/CoreServices --label "$installer_volume_name"
	echo ${move_up}${erase_line}${text_success}"+ Renamed installer volume."${erase_style}

	echo ${text_progress}"> Copying installer packages."${erase_style}
	rm "$installer_volume_path"/System/Installation/Packages
	cp -R "$installer_packages_image"/Packages "$installer_volume_path"/System/Installation/
	echo ${move_up}${erase_line}${text_success}"+ Copied installer packages."${erase_style}

	echo ${text_progress}"> Copying installer disk images."${erase_style}
	if [[ $installer_contents == "1" || $installer_contents == "2" ]]; then
		cp "$installer_packages_image"/BaseSystem* "$installer_volume_path"/
	fi
	if [[ $installer_contents == "2" ]]; then
		cp "$installer_packages_image"/AppleDiagnostics* "$installer_volume_path"/
	fi
	if [[ $installer_contents == "3" ]]; then
		cp "$installer_images_path"/BaseSystem* "$installer_volume_path"/
		cp "$installer_images_path"/AppleDiagnostics* "$installer_volume_path"/
	fi
	echo ${move_up}${erase_line}${text_success}"+ Copied installer disk images."${erase_style}

	echo ${text_progress}"> Unmounting installer disk images."${erase_style}
	Output_Off hdiutil detach "$installer_packages_image"
	Output_Off hdiutil detach "$installer_system_image"
	echo ${move_up}${erase_line}${text_success}"+ Unmounted installer disk images."${erase_style}
}

Patch_Installer()
{
	echo ${text_progress}"> Patching installer menu."${erase_style}
	cp "$resources_path"/menu/"$installer_version_short"/InstallerMenuAdditions.plist "$installer_volume_path"/System/Installation/CDIS/*Installer.app/Contents/Resources
	echo ${move_up}${erase_line}${text_success}"+ Patched installer menu."${erase_style}

	if [[ $installer_patch_required == "1" ]]; then
		Patch_Supported
	fi
	Patch_Unsupported
}

Patch_Supported()
{
	echo ${text_progress}"> Patching installer app."${erase_style}
	cp -R "$installer_volume_path"/System/Installation/CDIS/macOS\ Installer.app "$installer_volume_path"/tmp/macOS\ Installer-original.app
	cp -R "$resources_path"/macOS\ Installer.app "$installer_volume_path"/tmp/macOS\ Installer-patched.app
	cp "$installer_volume_path"/tmp/macOS\ Installer-original.app/Contents/Resources/X.tiff "$installer_volume_path"/tmp/macOS\ Installer-patched.app/Contents/Resources/
	cp "$installer_volume_path"/tmp/macOS\ Installer-original.app/Contents/Resources/OSXTheme.car "$installer_volume_path"/tmp/macOS\ Installer-patched.app/Contents/Resources/
	cp "$installer_volume_path"/tmp/macOS\ Installer-original.app/Contents/Resources/ReleaseNameTheme.car "$installer_volume_path"/tmp/macOS\ Installer-patched.app/Contents/Resources/
	cp "$installer_volume_path"/tmp/macOS\ Installer-original.app/Contents/Resources/InstallerMenuAdditions.plist "$installer_volume_path"/tmp/macOS\ Installer-patched.app/Contents/Resources/
	rm -R "$installer_volume_path"/System/Installation/CDIS/macOS\ Installer.app
	cp -R "$installer_volume_path"/tmp/macOS\ Installer-patched.app "$installer_volume_path"/System/Installation/CDIS/macOS\ Installer.app
	echo ${move_up}${erase_line}${text_success}"+ Patched installer app."${erase_style}

	echo ${text_progress}"> Patching installer framework."${erase_style}
	rm -R "$installer_volume_path"/System/Library/PrivateFrameworks/OSInstaller.framework
	cp -R "$resources_path"/OSInstaller.framework "$installer_volume_path"/System/Library/PrivateFrameworks/
	echo ${move_up}${erase_line}${text_success}"+ Patched installer framework."${erase_style}

	if [[ $installer_version_short == "10.14" ]]; then
		echo ${text_progress}"> Patching system migration frameworks."${erase_style}
		rm -R "$installer_volume_path"/System/Library/PrivateFrameworks/SystemMigration.framework
		rm -R "$installer_volume_path"/System/Library/PrivateFrameworks/SystemMigrationUtils.framework
		cp -R "$resources_path"/SystemMigration.framework "$installer_volume_path"/System/Library/PrivateFrameworks/
		cp -R "$resources_path"/SystemMigrationUtils.framework "$installer_volume_path"/System/Library/PrivateFrameworks/
		echo ${move_up}${erase_line}${text_success}"+ Patched system migration frameworks."${erase_style}
	fi

	echo ${text_progress}"> Patching graphics driver."${erase_style}
	cp -R "$installer_volume_path"/System/Library/Frameworks/Quartz.framework "$installer_volume_path"/tmp/Quartz-original.framework
	cp -R "$resources_path"/Quartz.framework "$installer_volume_path"/tmp/Quartz-patched.framework
	rm -R "$installer_volume_path"/tmp/Quartz-patched.framework/Versions/A/Frameworks/QuickLookUI.framework
	cp -R "$installer_volume_path"/tmp/Quartz-original.framework/Versions/A/Frameworks/QuickLookUI.framework "$installer_volume_path"/tmp/Quartz-patched.framework/Versions/A/Frameworks/
	rm -R "$installer_volume_path"/System/Library/Frameworks/Quartz.framework
	cp -R "$installer_volume_path"/tmp/Quartz-patched.framework "$installer_volume_path"/System/Library/Frameworks/Quartz.framework
	echo ${move_up}${erase_line}${text_success}"+ Patched graphics driver."${erase_style}
}

Patch_Unsupported()
{
	if [[ $installer_version_short == "10.12" ]]; then
		echo ${text_progress}"> Patching installer framework."${erase_style}
		rm -R "$installer_volume_path"/System/Library/PrivateFrameworks/OSInstaller.framework
		cp -R "$resources_path"/OSInstaller.framework "$installer_volume_path"/System/Library/PrivateFrameworks/
		echo ${move_up}${erase_line}${text_success}"+ Patched installer framework."${erase_style}
	fi

	echo ${text_progress}"> Patching installer package."${erase_style}
	cp "$installer_volume_path"/System/Installation/Packages/OSInstall.mpkg "$installer_volume_path"/tmp
	pkgutil --expand "$installer_volume_path"/tmp/OSInstall.mpkg "$installer_volume_path"/tmp/OSInstall
	sed -i '' 's/cpuFeatures\[i\] == "VMM"/1 == 1/' "$installer_volume_path"/tmp/OSInstall/Distribution
	sed -i '' 's/nonSupportedModels.indexOf(currentModel)&gt;= 0/1 == 0/' "$installer_volume_path"/tmp/OSInstall/Distribution
	sed -i '' 's/boardIds.indexOf(boardId)== -1/1 == 0/' "$installer_volume_path"/tmp/OSInstall/Distribution
	pkgutil --flatten "$installer_volume_path"/tmp/OSInstall "$installer_volume_path"/tmp/OSInstall.mpkg
	cp "$installer_volume_path"/tmp/OSInstall.mpkg "$installer_volume_path"/System/Installation/Packages
	echo ${move_up}${erase_line}${text_success}"+ Patched installer package."${erase_style}

	echo ${text_progress}"> Patching input drivers."${erase_style}
	cp -R "$resources_path"/patch/LegacyUSBInjector.kext "$installer_volume_path"/System/Library/Extensions
	echo ${move_up}${erase_line}${text_success}"+ Patched input drivers."${erase_style}

	echo ${text_progress}"> Patching platform support check."${erase_style}
	rm "$installer_volume_path"/System/Library/CoreServices/PlatformSupport.plist
	echo ${move_up}${erase_line}${text_success}"+ Patched platform support check."${erase_style}

	echo ${text_progress}"> Patching kernel cache."${erase_style}
	rm "$installer_volume_path"/System/Library/PrelinkedKernels/prelinkedkernel
	if [[ $modern_prelinkedkernel == "1" && $modern_prelinkedkernel_check == "1" ]]; then
		cp "$resources_path"/prelinkedkernel-modern/"$installer_prelinkedkernel"/prelinkedkernel "$installer_volume_path"/System/Library/PrelinkedKernels
	else
		cp "$resources_path"/prelinkedkernel/"$installer_prelinkedkernel"/prelinkedkernel "$installer_volume_path"/System/Library/PrelinkedKernels
	fi
	chflags uchg "$installer_volume_path"/System/Library/PrelinkedKernels/prelinkedkernel
	echo ${move_up}${erase_line}${text_success}"+ Patched kernel cache."${erase_style}

	echo ${text_progress}"> Patching System Integrity Protection."${erase_style}
	cp -R "$resources_path"/patch/SIPManager.kext "$installer_volume_path"/System/Library/Extensions
	echo ${move_up}${erase_line}${text_success}"+ Patched System Integrity Protection."${erase_style}

	echo ${text_progress}"> Copying patcher utilities."${erase_style}
	cp -R "$resources_path"/patch "$installer_volume_path"/usr/
	cp "$resources_path"/cmds/patch.sh "$installer_volume_path"/usr/bin/patch
	cp "$resources_path"/cmds/restore.sh "$installer_volume_path"/usr/bin/restore
	chmod +x "$installer_volume_path"/usr/bin/patch
	chmod +x "$installer_volume_path"/usr/bin/restore
	echo ${move_up}${erase_line}${text_success}"+ Copied patcher utilities."${erase_style}
}

Repair()
{
	chown -R 0:0 "$@"
	chmod -R 755 "$@"
}

Repair_Permissions()
{
	echo ${text_progress}"> Repairing permissions."${erase_style}
	Repair "$installer_volume_path"/System/Installation/CDIS/*Installer.app

	if [[ $installer_patch_required == "1" ]]; then
		Repair "$installer_volume_path"/System/Library/PrivateFrameworks/OSInstaller.framework

		if [[ $installer_version_short == "10.14" ]]; then
			Repair "$installer_volume_path"/System/Library/PrivateFrameworks/SystemMigration.framework
			Repair "$installer_volume_path"/System/Library/PrivateFrameworks/SystemMigrationUtils.framework
		fi

		Repair "$installer_volume_path"/System/Library/Frameworks/Quartz.framework
	fi

	Repair "$installer_volume_path"/System/Installation/Packages/OSInstall.mpkg

	Repair "$installer_volume_path"/System/Library/Extensions/LegacyUSBInjector.kext
	Repair "$installer_volume_path"/System/Library/Extensions/SIPManager.kext

	Repair "$installer_volume_path"/usr/patch
	Repair "$installer_volume_path"/usr/bin/patch
	Repair "$installer_volume_path"/usr/bin/restore
	echo ${move_up}${erase_line}${text_success}"+ Repaired permissions."${erase_style}
}

Input_Package()
{
	echo ${text_message}"/ What update would you like to use?"${erase_style}
	echo ${text_message}"/ Input an update path."${erase_style}
	Input_On
	read -e -p "/ " package_path
	Input_Off

	package_folder="${package_path%.*}"
}

Patch_Package()
{
	echo ${text_progress}"> Expanding update package."${erase_style}
	pkgutil --expand "$package_path" "$package_folder"
	echo ${move_up}${erase_line}${text_success}"+ Expanded update package."${erase_style}

	echo ${text_progress}"> Patching update package."${erase_style}
	sed -i '' 's|<pkg-ref id="com\.apple\.pkg\.FirmwareUpdate" auth="Root" packageIdentifier="com\.apple\.pkg\.FirmwareUpdate">#FirmwareUpdate\.pkg<\/pkg-ref>||' "$package_folder"/Distribution
	sed -i "" "s/my.target.filesystem &amp;&amp; my.target.filesystem.type == 'hfs'/1 == 0/" "$package_folder"/Distribution
	sed -i '' 's/cpuFeatures\[i\] == "VMM"/1 == 1/' "$package_folder"/Distribution
	sed -i '' 's/nonSupportedModels.indexOf(currentModel)&gt;= 0/1 == 0/' "$package_folder"/Distribution
	sed -i '' 's/boardIds.indexOf(boardId)== -1/1 == 0/' "$package_folder"/Distribution
	echo ${move_up}${erase_line}${text_success}"+ Patched update package."${erase_style}

	echo ${text_progress}"> Preparing update package."${erase_style}
	pkgutil --flatten "$package_folder" "$package_path"
	echo ${move_up}${erase_line}${text_success}"+ Prepared update package."${erase_style}

	echo ${text_progress}"> Removing temporary files."${erase_style}
	Output_Off rm -R "$package_folder"
	echo ${move_up}${erase_line}${text_success}"+ Removed temporary files."${erase_style}
}

End()
{
	if [[ $operation == "1" ]]; then
		echo ${text_progress}"> Removing temporary files."${erase_style}
		Output_Off rm -R "$installer_volume_path"/tmp/*
		echo ${move_up}${erase_line}${text_success}"+ Removed temporary files."${erase_style}
	fi

	echo ${text_message}"/ Thank you for using macOS Patcher."${erase_style}
	Input_On
	exit
}

Input_Off
Escape_Variables
Parameter_Variables
Path_Variables
Check_Environment
Check_Root
Check_Resources
Input_Operation
End