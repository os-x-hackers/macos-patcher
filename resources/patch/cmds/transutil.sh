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
}

Path_Variables()
{
	script_path="${0}"
	directory_path="${0%/*}"

	system_version_path="System/Library/CoreServices/SystemVersion.plist"
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

Check_SIP()
{
	echo ${text_progress}"> Checking System Integrity Protection status."${erase_style}
	if [[ $(csrutil status) == *disabled* ]]; then
		echo ${move_up}${erase_line}${text_success}"+ System Integrity Protection status check passed."${erase_style}
	fi
	if [[ $(csrutil status) == *enabled* ]]; then
		echo ${text_error}"- System Integrity Protection status check failed."${erase_style}
		echo ${text_message}"/ Run this tool with System Integrity Protection disabled."${erase_style}
		Input_On
		exit
	fi
}

Check_Internet()
{
	echo ${text_progress}"> Checking for internet conectivity."${erase_style}
	if [[ $(ping -c 5 www.google.com) == *transmitted* && $(ping -c 5 www.google.com) == *received* ]]; then
		echo ${move_up}${erase_line}${text_success}"+ Integrity conectivity check passed."${erase_style}
	else
		echo ${text_error}"- Integrity conectivity check failed."${erase_style}
		echo ${text_message}"/ Run this tool while connected to the internet."${erase_style}
		Input_On
		exit
	fi
}

Import_Variables()
{
	curl -L -s -o /tmp/resources.zip https://github.com/rmc-team/macos-patcher-resources/archive/master.zip
	unzip -q /tmp/resources.zip -d /tmp
	chmod +x /tmp/macos-patcher-resources-master/resources/hybrid_var.sh
	chmod +x /tmp/macos-patcher-resources-master/resources/flat_var.sh
	source /tmp/macos-patcher-resources-master/resources/hybrid_var.sh
	source /tmp/macos-patcher-resources-master/resources/flat_var.sh
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
	read -e -p "/ " volume_name
	Input_Off

	volume_path="/Volumes/$volume_name"
}

Check_Volume_Version()
{
	echo ${text_progress}"> Checking system version."${erase_style}	
	volume_version="$(grep -A1 "ProductVersion" "$volume_path/$system_version_path")"

	volume_version="${volume_version#*<string>}"
	volume_version="${volume_version%</string>*}"

	volume_version_short="${volume_version:0:5}"
	volume_version_underscore="${volume_version//./_}"
	echo ${move_up}${erase_line}${text_success}"+ Checked system version."${erase_style}

	echo ${text_progress}"> Checking system support."${erase_style}
	if [[ $volume_version_short == "10.12" || $volume_version_short == "10.13" || $volume_version_short == "10.14" ]]; then
		volume_patch_supported="1"
	fi

	if [[ $volume_patch_supported == "1" ]]; then
		echo ${move_up}${erase_line}${text_success}"+ System support check passed."${erase_style}
	fi
	if [[ ! $volume_patch_supported == "1" ]]; then
		echo ${text_error}"- System support check failed."${erase_style}
		echo ${text_message}"/ Run this tool on a supported system."${erase_style}
		Input_On
		exit
	fi

	if [[ -e "$volume_path"/System/Library/PrivateFrameworks/CoreUI.framework/Versions/Current/CoreUI-bak ]]; then
		volume_patch_hybrid_mode="1"
	fi
	if [[ -e "$volume_path"/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit-bak ]]; then
		volume_patch_flat_mode="1"
	fi
	if [[ -e "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox-bak ]]; then
		volume_patch_menubar="1"
	fi
}

Input_Operation()
{
	echo ${text_message}"/ What operation would you like to run?"${erase_style}
	echo ${text_message}"/ Input an operation number."${erase_style}
	echo ${text_message}"/     1 - Enable Reduce Transparency"${erase_style}
	echo ${text_message}"/     2 - Disable Reduce Transparency"${erase_style}
	echo ${text_message}"/     3 - Install Hybrid Mode patch"${erase_style}
	echo ${text_message}"/     4 - Install Flat Mode patch"${erase_style}
	Input_On
	read -e -p "/ " operation
	Input_Off

	if [[ $operation == "1" ]]; then
		Enable_Reduce_Transparency
	fi
	if [[ $operation == "2" ]]; then
		Disable_Reduce_Transparency
	fi
	if [[ $operation == "3" || $operation == "4" ]]; then
		if [[ $volume_patch_hybrid_mode == "1" && $operation == "3" ]]||[[ $volume_patch_flat_mode == "1" && $operation == "4" ]]; then
			Input_Operation_Overwrite
		else
			if [[ $volume_patch_hybrid_mode == "1" && $operation == "4" ]]||[[ $volume_patch_flat_mode == "1" && $operation == "3" ]]; then
				echo ${text_error}"! Another transparency patch is already installed."${erase_style}
				echo ${text_message}"/ Run this tool with another operation."${erase_style}
				Input_On
				exit
			fi

			if [[ $operation == "3" ]]; then
				Install_Hybrid_Mode
			fi
			if [[ $operation == "4" ]]; then
				Install_Flat_Mode
			fi
		fi
	fi
}

Input_Operation_Overwrite()
{
	echo ${text_warning}"! A transparency patch backup already exists."${erase_style}
	echo ${text_message}"/ What operation would you like to run?"${erase_style}
	echo ${text_message}"/ Input an operation number."${erase_style}
	echo ${text_message}"/     1 - Abort and keep backup"${erase_style}
	echo ${text_message}"/     2 - Proceed and overwrite backup"${erase_style}
	Input_On
	read -e -p "/ " operation_overwrite
	Input_Off

	if [[ $operation_overwrite == "1" ]]; then
		echo "\033[6A"${text_error}"! A transparency patch backup already exists."${erase_style}
		echo ${text_message}"/ Run this tool with another operation."${erase_style}
		Input_On
		exit
	fi
	if [[ $operation_overwrite == "2" ]]; then
		echo "\033[7A"
		if [[ $operation == "3" ]]; then
			Install_Hybrid_Mode
		fi
		if [[ $operation == "4" ]]; then
			Install_Flat_Mode
		fi
	fi
}

Enable_Reduce_Transparency()
{
	echo ${text_progress}"> Enabling Reduce Transparency."${erase_style}
	for template in "$volume_path"/System/Library/User\ Template/*; do 
		if [[ -e "$template"/Library/Preferences/com.apple.universalaccess.plist ]]; then
			plutil -replace reduceTransparency -bool true "$template"/Library/Preferences/com.apple.universalaccess.plist
		else
			Output_Off cp /tmp/macos-patcher-resources-master/resources/com.apple.universalaccess.plist "$template"/Library/Preferences
		fi
	done

	for users in "$volume_path"/Users/*; do
		if [[ -e "$users"/Library/Preferences/com.apple.universalaccess.plist ]]; then
			plutil -replace reduceTransparency -bool true "$users"/Library/Preferences/com.apple.universalaccess.plist
		else
			Output_Off cp /tmp/macos-patcher-resources-master/resources/com.apple.universalaccess.plist "$users"/Library/Preferences
		fi
	done

	if [[ -e "$volume_path"/private/var/root/Library/Preferences/com.apple.universalaccess.plist ]]; then
		plutil -replace reduceTransparency -bool true "$volume_path"/private/var/root/Library/Preferences/com.apple.universalaccess.plist
	else
		Output_Off cp /tmp/macos-patcher-resources-master/resources/com.apple.universalaccess.plist "$volume_path"/private/var/root/Library/Preferences/
	fi

	if [[ $(diskutil info "$volume_name"|grep "Mount Point") == *"/" && ! $(diskutil info "$volume_name"|grep "Mount Point") == *"/Volumes" ]]; then
		defaults write com.apple.universalaccess reduceTransparency -bool true
	fi
	echo ${move_up}${erase_line}${text_success}"+ Enabled Reduce Transparency."${erase_style}
}

Disable_Reduce_Transparency()
{
	echo ${text_progress}"> Disabling Reduce Transparency."${erase_style}
	for template in "$volume_path"/System/Library/User\ Template/*; do
		Output_Off plutil -remove reduceTransparency "$template"/Library/Preferences/com.apple.universalaccess.plist
	done

	for users in "$volume_path"/Users/*; do 
		Output_Off plutil -remove reduceTransparency "$users"/Library/Preferences/com.apple.universalaccess.plist
	done

	Output_Off plutil -remove reduceTransparency "$volume_path"/private/var/root/Library/Preferences/com.apple.universalaccess.plist

	if [[ $(diskutil info "$volume_name"|grep "Mount Point") == *"/" && ! $(diskutil info "$volume_name"|grep "Mount Point") == *"/Volumes" ]]; then
		defaults write com.apple.universalaccess reduceTransparency -bool false
	fi
	echo ${move_up}${erase_line}${text_success}"+ Disabled Reduce Transparency."${erase_style}
}

Install_Hybrid_Mode()
{
	echo ${text_progress}"> Installing Hybrid Mode patch."${erase_style}
	curl -L -s -o /tmp/Hybrid\ Mode.zip https://github.com/SpiraMira/HybridMode-Public/releases/download/${!hybrid_url}.zip
	unzip -o -q /tmp/Hybrid\ Mode.zip -d /tmp
	cp "$volume_path"/System/Library/PrivateFrameworks/CoreUI.framework/Versions/Current/CoreUI "$volume_path"/System/Library/PrivateFrameworks/CoreUI.framework/Versions/Current/CoreUI-bak
	cp /tmp/CoreUI* "$volume_path"/System/Library/PrivateFrameworks/CoreUI.framework/Versions/Current/CoreUI

	if [[ ! $volume_patch_menubar == "1" ]]; then
		cp "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox-bak
		cp /tmp/HIToolbox* "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox
	fi
	echo ${move_up}${erase_line}${text_success}"+ Installed Hybrid Mode patch."${erase_style}
}

Install_Flat_Mode()
{
	echo ${text_progress}"> Installing Flat Mode patch."${erase_style}
	curl -L -s -o /tmp/Flat\ Mode.zip https://github.com/SpiraMira/HybridMode-Public/releases/download/${!flat_url}.zip
	unzip -o -q /tmp/Flat\ Mode.zip -d /tmp
	cp "$volume_path"/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit "$volume_path"/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit-bak
	cp /tmp/AppKit* "$volume_path"/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit

	if [[ ! $volume_patch_menubar == "1" ]]; then
		cp "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox-bak
		cp /tmp/HIToolbox* "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox
	fi
	echo ${move_up}${erase_line}${text_success}"+ Installed Flat Mode patch."${erase_style}
}

Repair_755()
{
	chown -R 0:0 "$@"
	chmod -R 755 "$@"
}

Repair_700()
{
	chown -R 0:0 "$@"
	chmod -R 700 "$@"
}

Repair_Permissions()
{
	echo ${text_progress}"> Repairing permissions."${erase_style}
	Repair_755 "$volume_path"/System/Library/PrivateFrameworks/CoreUI.framework
	Repair_755 "$volume_path"/System/Library/Frameworks/AppKit.framework
	Repair_755 "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework
	Repair_700 "$volume_path"/System/Library/User\ Template/*/Library/Preferences/
	Repair_700 "$volume_path"/private/var/root/Library/Preferences/
	chmod -R 700 "$volume_path"/Users/*/Library/Preferences/
	echo ${move_up}${erase_line}${text_success}"+ Repaired permissions."${erase_style}
}

Restart()
{
	echo ${text_progress}"> Removing temporary files."${erase_style}
	Output_Off rm -R /tmp/*
	echo ${move_up}${erase_line}${text_success}"+ Removed temporary files."${erase_style}

	if [[ $(diskutil info "$volume_name"|grep "Mount Point") == *"/" && ! $(diskutil info "$volume_name"|grep "Mount Point") == *"/Volumes" ]]; then
		echo ${text_message}"/ Your machine will restart soon."${erase_style}
		echo ${text_message}"/ Thank you for using macOS Patcher."${erase_style}
		reboot
	else
		echo ${text_message}"/ Thank you for using macOS Patcher."${erase_style}
		Input_On
		exit
	fi

}

Input_Off
Escape_Variables
Parameter_Variables
Path_Variables
Check_Environment
Check_Root
Check_SIP
Check_Internet
Input_Volume
Check_Volume_Version
Import_Variables
Input_Operation
Repair_Permissions
Restart