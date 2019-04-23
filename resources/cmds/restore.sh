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
	system_version_pip_path="System/Library/CoreServices/SystemVersion-pip.plist"
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

Input_Model()
{
model_list="/     iMac7,1
/     iMac8,1
/     iMac9,1
/     iMac10,1
/     iMac10,2
/     iMac11,1
/     iMac11,2
/     iMac11,3
/     iMac12,1
/     iMac12,2
/     MacBook4,1
/     MacBook5,1
/     MacBook5,2
/     MacBook6,1
/     MacBook7,1
/     MacBookAir2,1
/     MacBookAir3,1
/     MacBookAir3,2
/     MacBookAir4,1
/     MacBookAir4,2
/     MacBookPro4,1
/     MacBookPro5,1
/     MacBookPro5,2
/     MacBookPro5,3
/     MacBookPro5,4
/     MacBookPro5,5
/     MacBookPro6,1
/     MacBookPro6,2
/     MacBookPro7,1
/     MacBookPro8,1
/     MacBookPro8,2
/     MacBookPro8,3
/     Macmini3,1
/     Macmini4,1
/     Macmini5,1
/     Macmini5,2
/     Macmini5,3
/     MacPro3,1
/     MacPro4,1
/     Xserve2,1
/     Xserve3,1"
	
	model_detected="$(sysctl -n hw.model)"

	echo ${text_progress}"> Detecting model."${erase_style}
	echo ${move_up}${erase_line}${text_success}"+ Detected model as $model_detected."${erase_style}

	echo ${text_message}"/ What model would you like to use?"${erase_style}
	echo ${text_message}"/ Input an model option."${erase_style}
	echo ${text_message}"/     1 - Use detected model"${erase_style}
	echo ${text_message}"/     2 - Use manually selected model"${erase_style}
	Input_On
	read -e -p "/ " model_option
	Input_Off

	if [[ $model_option == "1" ]]; then
		model="$model_detected"
		echo ${text_success}"+ Using $model_detected as model."${erase_style}
	fi

	if [[ $model_option == "2" ]]; then
		echo ${text_message}"/ What model would you like to use?"${erase_style}
		echo ${text_message}"/ Input your model."${erase_style}
		echo ${text_message}"$model_list"${erase_style}
		Input_On
		read -e -p "/ " model_selected
		Input_Off
		model="$model_selected"
		echo ${text_success}"+ Using $model_selected as model."${erase_style}
	fi

	if [[ $model == "MacBookAir2,1" || $model == "MacBookPro4,1" || $model == "iMac7,1" || $model == "iMac8,1" || $model == "Macmini3,1" || $model == "MacPro3,1" ]]; then
		model_airport="1"
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
	read -e -p "/ " volume_name
	Input_Off

	volume_path="/Volumes/$volume_name"
}

Check_Volume_Version()
{
	echo ${text_progress}"> Checking system version."${erase_style}	
	volume_version="{$(grep -A1 "ProductVersion" "$volume_path/$system_version_path")"

	volume_version="${volume_version#*<string>}"
	volume_version="${volume_version%</string>*}"

	volume_version_short="${volume_version:0:5}"
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

	if [ -e $volume_path/Library/LaunchAgents/com.dd1* ]||[ -e $volume_path/Library/LaunchAgents/com.dosdude1* ]; then
		volume_patch_variant="2"
	else
		volume_patch_variant="1"
	fi

	if [[ -e /Volumes/EFI/EFI/BOOT/BOOTX64.efi || -e /Volumes/EFI/EFI/apfs.efi ]]; then
		volume_patch_apfs="1"
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

Mount_EFI()
{
	disk_identifier="$(diskutil info "$volume_name"|grep "Device Identifier")"
	disk_identifier="disk${disk_identifier#*disk}"
	disk_identifier_whole="$(diskutil info "$volume_name"|grep "Part of Whole")"
	disk_identifier_whole="disk${disk_identifier_whole#*disk}"
	
	if [[ "$(diskutil info "$volume_name"|grep "APFS")" == *"APFS"* ]]; then
		disk_identifier_whole="$(diskutil list|grep "\<$disk_identifier_whole\>")"
		disk_identifier_whole="${disk_identifier_whole#*disk}"
		disk_identifier_whole="${disk_identifier_whole#*disk}"
		disk_identifier_whole="disk${disk_identifier_whole:0:1}"
		disk_identifier_efi="${disk_identifier_whole}s1"
	fi
	
	if [[ "$(diskutil info "$volume_name"|grep "HFS")" == *"HFS"* ]]; then
		disk_identifier_efi="${disk_identifier_whole}s1"
	fi

	Output_Off diskutil mount $disk_identifier_efi
}


Input_Operation()
{
	echo ${text_message}"/ What operation would you like to run?"${erase_style}
	echo ${text_message}"/ Input an operation number."${erase_style}
	echo ${text_message}"/     1 - Remove system patches"${erase_style}
	echo ${text_message}"/     2 - Remove transparency patches"${erase_style}
	Input_On
	read -e -p "/ " operation
	Input_Off

	if [[ $operation == "1" ]]; then
		echo ${text_message}"/ What operation would you like to run?"${erase_style}
		echo ${text_message}"/ Input an operation number."${erase_style}
		echo ${text_message}"/     1 - Remove all system patches"${erase_style}
		if [[ $volume_patch_apfs == "1" ]]; then
			echo ${text_message}"/     2 - Remove APFS system patch"${erase_style}
		fi
		Input_On
		read -e -p "/ " operation_system
		Input_Off
	fi
	if [[ $operation == "2" ]]; then
		if [[ $volume_patch_hybrid_mode == "1" || $volume_patch_flat_mode == "1" ]]; then
			echo ${text_message}"/ What operation would you like to run?"${erase_style}
			echo ${text_message}"/ Input an operation number."${erase_style}
			if [[ $volume_patch_hybrid_mode == "1" ]]; then
				echo ${text_message}"/     1 - Remove hybrid mode patch"${erase_style}
			fi
			if [[ $volume_patch_flat_mode == "1" ]]; then
				echo ${text_message}"/     1 - Remove flat mode patch"${erase_style}
			fi
		else
			echo ${text_warning}"! No transparency patches are installed."${erase_style}
			echo ${text_message}"/ Run this tool with another operation."${erase_style}
			Input_Operation
		fi
		Input_On
		read -e -p "/ " operation_transparency
		Input_Off
	fi
}

Run_Operation()
{
	if [[ $operation_system == "1" ]]; then
		if [[ $volume_patch_variant == "1" ]]; then
			Restore_Volume
		fi
		if [[ $volume_patch_variant == "2" ]]; then
			Restore_Volume_dosdude
		fi

		if [[ $volume_patch_hybrid_mode == "1" ]]; then
			Restore_Hybrid_Mode
			Repair_Permissions_Volume
		fi
		if [[ $volume_patch_flat_mode == "1" ]]; then
			Restore_Flat_Mode
			Repair_Permissions_Volume
		fi
	fi
	if [[ $operation_system == "2" && $volume_patch_apfs == "1" ]]; then
		Restore_APFS
	fi

	if [[ $operation_transparency == "1" && $volume_patch_hybrid_mode == "1" ]]; then
		Restore_Hybrid_Mode
		Repair_Permissions_Volume
	fi
	if [[ $operation_transparency == "1" && $volume_patch_flat_mode == "1" ]]; then
		Restore_Flat_Mode
		Repair_Permissions_Volume
	fi
}

Restore_Volume()
{
	echo ${text_progress}"> Removing input drivers patch."${erase_style}
	rm -R "$volume_path"/System/Library/Extensions/LegacyUSBEthernet.kext
	rm -R "$volume_path"/System/Library/Extensions/LegacyUSBInjector.kext

	if [[ $volume_version_short == "10.14" ]]; then
		rm -R "$volume_path"/System/Library/Extensions/AppleUSBACM.kext
		rm -R "$volume_path"/System/Library/Extensions/IOUSBFamily.kext
		rm -R "$volume_path"/System/Library/Extensions/IOUSBHostFamily.kext
	fi

	if [[ $model == "MacBook4,1" ]]; then
		rm -R "$volume_path"/System/Library/Extensions/AppleHIDMouse.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleHSSPIHIDDriver.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleIRController.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleMultitouchDriver.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleTopCase.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleUSBMultitouch.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleUSBTopCase.kext
		rm -R "$volume_path"/System/Library/Extensions/IOBDStorageFamily.kext
		rm -R "$volume_path"/System/Library/Extensions/IOSerialFamily.kext
		rm -R "$volume_path"/System/Library/Extensions/IOUSBFamily.kext
		rm -R "$volume_path"/System/Library/Extensions/IOUSBHostFamily.kext
		rm -R "$volume_path"/System/Library/Extensions/IOUSBMassStorageClass.kext
	fi

	if [[ $model == "MacBook5,2" ]]; then
		rm -R "$volume_path"/System/Library/Extensions/AppleTopCase.kext
	fi
	echo ${move_up}${erase_line}${text_success}"+ Removed input drivers patch."${erase_style}

	echo ${text_progress}"> Removing graphics drivers patch."${erase_style}
	if [[ $volume_version_short == "10.13" || $volume_version_short == "10.14" ]]; then
		rm -R "$volume_path"/System/Library/Extensions/AMDRadeonX3000.kext
		rm -R "$volume_path"/System/Library/Extensions/AMDRadeonX3000GLDriver.bundle
		rm -R "$volume_path"/System/Library/Extensions/AMDRadeonX4000.kext
		rm -R "$volume_path"/System/Library/Extensions/AMDRadeonX4000GLDriver.bundle
		rm -R "$volume_path"/System/Library/Extensions/IOAccelerator2D.plugin
		rm -R "$volume_path"/System/Library/Extensions/IOAcceleratorFamily2.kext
	fi

	if [[ $volume_version_short == "10.14" ]]; then
		rm -R "$volume_path"/System/Library/Extensions/AMD2400Controller.kext
		rm -R "$volume_path"/System/Library/Extensions/AMD2600Controller.kext
		rm -R "$volume_path"/System/Library/Extensions/AMD3800Controller.kext
		rm -R "$volume_path"/System/Library/Extensions/AMD4600Controller.kext
		rm -R "$volume_path"/System/Library/Extensions/AMD4800Controller.kext
		rm -R "$volume_path"/System/Library/Extensions/AMD5000Controller.kext
		rm -R "$volume_path"/System/Library/Extensions/AMD6000Controller.kext
		rm -R "$volume_path"/System/Library/Extensions/AMDFramebuffer.kext
		rm -R "$volume_path"/System/Library/Extensions/AMDLegacyFramebuffer.kext
		rm -R "$volume_path"/System/Library/Extensions/AMDLegacySupport.kext
		rm -R "$volume_path"/System/Library/Extensions/AMDRadeonVADriver.bundle
		rm -R "$volume_path"/System/Library/Extensions/AMDRadeonVADriver2.bundle
		rm -R "$volume_path"/System/Library/Extensions/AMDRadeonX4000HWServices.kext
		rm -R "$volume_path"/System/Library/Extensions/AMDShared.bundle
		rm -R "$volume_path"/System/Library/Extensions/AMDSupport.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelFramebufferAzul.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelFramebufferCapri.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelHD3000Graphics.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelHD3000GraphicsGA.plugin
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelHD3000GraphicsGLDriver.bundle
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelHD3000GraphicsVADriver.bundle
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelHDGraphics.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelHDGraphicsFB.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelHDGraphicsGA.plugin
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelHDGraphicsGLDriver.bundle
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelHDGraphicsVADriver.bundle
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelSNBGraphicsFB.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelSNBVA.bundle
		rm -R "$volume_path"/System/Library/Extensions/ATIRadeonX2000.kext
		rm -R "$volume_path"/System/Library/Extensions/ATIRadeonX2000GA.plugin
		rm -R "$volume_path"/System/Library/Extensions/ATIRadeonX2000GLDriver.bundle
		rm -R "$volume_path"/System/Library/Extensions/ATIRadeonX2000VADriver.bundle
		rm -R "$volume_path"/System/Library/Extensions/GeForceTesla.kext
		rm -R "$volume_path"/System/Library/Extensions/GeForceTeslaGLDriver.bundle
		rm -R "$volume_path"/System/Library/Extensions/GeForceTeslaVADriver.bundle
		rm -R "$volume_path"/System/Library/Extensions/IOGraphicsFamily.kext
		rm -R "$volume_path"/System/Library/Extensions/IONDRVSupport.kext
		rm -R "$volume_path"/System/Library/Extensions/NVDANV50HalTesla.kext
		rm -R "$volume_path"/System/Library/Extensions/NVDAResmanTesla.kext
	fi

	if [[ $volume_version == "10.14.4" || $volume_version == "10.14.5" ]]; then
		rm -R "$volume_path"/System/Library/Frameworks/CoreDisplay.framework
		rm -R "$volume_path"/System/Library/PrivateFrameworks/GPUSupport.framework
		rm -R "$volume_path"/System/Library/Frameworks/OpenGL.framework
	fi

	if [[ $model == "MacBook4,1" ]]; then
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelGMAX3100.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelGMAX3100FB.kext
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelGMAX3100GA.plugin
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelGMAX3100GLDriver.bundle
		rm -R "$volume_path"/System/Library/Extensions/AppleIntelGMAX3100VADriver.bundle
	fi
	echo ${move_up}${erase_line}${text_success}"+ Removed graphics drivers patch."${erase_style}

	echo ${text_progress}"> Removing audio drivers patch."${erase_style}
	rm -R "$volume_path"/System/Library/Extensions/AppleHDA.kext
	rm -R "$volume_path"/System/Library/Extensions/IOAudioFamily.kext
	echo ${move_up}${erase_line}${text_success}"+ Removed audio drivers patch."${erase_style}

	echo ${text_progress}"> Removing backlight drivers patch."${erase_style}
	rm -R "$volume_path"/System/Library/Extensions/AppleBacklight.kext
	rm -R "$volume_path"/System/Library/Extensions/AppleBacklightExpert.kext
	rm -R "$volume_path"/System/Library/PrivateFrameworks/DisplayServices.framework
	echo ${move_up}${erase_line}${text_success}"+ Removed backlight drivers patch."${erase_style}

	echo ${text_progress}"> Removing ambient light sensor drivers patch."${erase_style}
	rm -R "$volume_path"/System/Library/Extensions/AppleSMCLMU.kext/Contents/PlugIns/AmbientLightSensorHID.plugin
	echo ${move_up}${erase_line}${text_success}"+ Removed ambient light sensor drivers patch."${erase_style}

	if [[ $model_airport == "1" || $volume_version_short == "10.14" ]]; then
		echo ${text_progress}"> Removing AirPort drivers patch."${erase_style}
	fi

	if [[ $volume_version_short == "10.14" ]]; then
		rm -R "$volume_path"/System/Library/Extensions/IO80211Family.kext/Contents/PlugIns/AirPortAtheros40.kext
	fi

	if [[ $model_airport == "1" ]]; then
		rm -R "$volume_path"/System/Library/Extensions/IO80211Family.kext/Contents/PlugIns/AppleAirPortBrcm43224.kext
		rm -R "$volume_path"/System/Library/Extensions/corecapture.kext
		rm -R "$volume_path"/System/Library/Extensions/CoreCaptureResponder.kext
	fi

	if [[ $model_airport == "1" || $volume_version_short == "10.14" ]]; then
		echo ${move_up}${erase_line}${text_success}"+ Removed AirPort drivers patch."${erase_style}
	fi

	if [[ $model == "MacBook4,1" ]]; then
		echo ${text_progress}"> Removing Bluetooth drivers patch."${erase_style}
		rm -R "$volume_path"/System/Library/Extensions/IOBluetoothFamily.kext
		rm -R "$volume_path"/System/Library/Extensions/IOBluetoothHIDDriver.kext
		echo ${move_up}${erase_line}${text_success}"+ Removed Bluetooth drivers patch."${erase_style}
	fi

	if [[ $volume_version == "10.14.4" || $volume_version == "10.14.5" ]]; then
		echo ${text_progress}"> Removing Siri application patch."${erase_style}
		rm -R "$volume_path"/System/Library/PrivateFrameworks/SiriUI.framework
		echo ${move_up}${erase_line}${text_success}"+ Removed Siri application patch."${erase_style}
	fi

	echo ${text_progress}"> Removing software update check patch."${erase_style}
	rm "$volume_path"/usr/lib/SUVMMFaker.dylib
	rm "$volume_path"/System/Library/LaunchDaemons/com.apple.softwareupdated.plist
	echo ${move_up}${erase_line}${text_success}"+ Removed software update check patch."${erase_style}

	echo ${text_progress}"> Removing System Integrity Protection patch."${erase_style}
	rm -R "$volume_path"/System/Library/Extensions/SIPManager.kext
	echo ${move_up}${erase_line}${text_success}"+ Removed System Integrity Protection patch."${erase_style}

	echo ${text_progress}"> Removing patcher utilities."${erase_style}
	rm "$volume_path/$system_version_pip_path"
	rm "$volume_path"/Library/LaunchAgents/com.rmc.pipagent.plist
	rm -R "$volume_path"/Library/Application\ Support/com.rmc.pipagent
	rm "$volume_path"/usr/bin/piputil

	if [[ $volume_version_short == "10.14" ]]; then
		rm "$volume_path"/usr/bin/transutil
	fi

	if [[ -e "$volume_path"/System/Library/CoreServices/SystemVersion-sud.plist ]]; then
		rm "$volume_path"/System/Library/CoreServices/SystemVersion-sud.plist
	fi
	if [[ -e "$volume_path"/Library/LaunchAgents/com.startup.sudcheck.plist ]]; then
		rm "$volume_path"/Library/LaunchAgents/com.startup.sudcheck.plist
	fi
	if [[ -d "$volume_path"/usr/sudagent ]]; then
		rm -R "$volume_path"/usr/sudagent
	fi
	if [[ -e "$volume_path"/usr/bin/sudcheck ]]; then
		rm "$volume_path"/usr/bin/sudcheck
	fi
	if [[ -e "$volume_path"/usr/bin/sudutil ]]; then
		rm "$volume_path"/usr/bin/sudutil
	fi
	echo ${move_up}${erase_line}${text_success}"+ Removed patcher utilities."${erase_style}
}

Restore_Volume_dosdude()
{
	echo ${text_progress}"> Removing input drivers patch."${erase_style}
	Output_Off rm -R "$volume_path"/Library/Extensions/LegacyUSBInjector.kext
	Output_Off rm -R "$volume_path"/Library/Extensions/LegacyUSBEthernet.kext

	Output_Off rm -R "$volume_path"/System/Library/Extensions/IOUSBFamily.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/IOUSBHostFamily.kext

	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleUSBTopCase.kext
	echo ${move_up}${erase_line}${text_success}"+ Removed input drivers patch."${erase_style}

	echo ${text_progress}"> Removing graphics drivers patch."${erase_style}
	Output_Off rm -R "$volume_path"/System/Library/Extensions/IOAccelerator2D.plugin
	Output_Off rm -R "$volume_path"/System/Library/Extensions/IOAcceleratorFamily2.kext

	Output_Off rm -R "$volume_path"/System/Library/Extensions/GeForceTesla.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/GeForceTeslaGLDriver.bundle
	Output_Off rm -R "$volume_path"/System/Library/Extensions/GeForceTeslaVADriver.bundle
	Output_Off rm -R "$volume_path"/System/Library/Extensions/NDRVShim.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/NVDANV50HalTesla.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/NVDAResmanTesla.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/NVDAStartup.kext

	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelHD3000Graphics.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelHD3000GraphicsGA.plugin
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelHD3000GraphicsGLDriver.bundle
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelHD3000GraphicsVADriver.bundle
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelSNBGraphicsFB.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelSNBVA.bundle

	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelFramebufferAzul.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelFramebufferCapri.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelHDGraphics.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelHDGraphicsFB.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelHDGraphicsGA.plugin
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelHDGraphicsGLDriver.bundle
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleIntelHDGraphicsVADriver.bundle

	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMD2400Controller.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMD2600Controller.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMD3800Controller.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMD4600Controller.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMD4800Controller.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMD5000Controller.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMD6000Controller.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMDRadeonX3000.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMDRadeonX3000GLDriver.bundle
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMDRadeonX4000.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMDRadeonX4000GLDriver.bundle
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMDFramebuffer.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMDLegacySupport.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMDLegacyFramebuffer.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMDRadeonVADriver.bundle
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMDRadeonVADriver2.bundle
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMDShared.bundle
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AMDSupport.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/ATIRadeonX2000.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/ATIRadeonX2000GA.plugin
	Output_Off rm -R "$volume_path"/System/Library/Extensions/ATIRadeonX2000GLDriver.bundle
	Output_Off rm -R "$volume_path"/System/Library/Extensions/ATIRadeonX2000VADriver.bundle
	echo ${move_up}${erase_line}${text_success}"+ Removed graphics drivers patch."${erase_style}

	echo ${text_progress}"> Removing audio drivers patch."${erase_style}
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleHDA.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/IOAudioFamily.kext
	echo ${move_up}${erase_line}${text_success}"+ Removed audio drivers patch."${erase_style}

	echo ${text_progress}"> Removing backlight drivers patch."${erase_style}
	Output_Off rm -R "$volume_path"/System/Library/PrivateFrameworks/DisplayServices.framework
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleBacklight.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleBacklightExpert.kext
	echo ${move_up}${erase_line}${text_success}"+ Removed backlight drivers patch."${erase_style}

	echo ${text_progress}"> Removing ambient light sensor drivers patch."${erase_style}
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleSMCLMU.kext/Contents/PlugIns/AmbientLightSensorHID.plugin
	echo ${move_up}${erase_line}${text_success}"+ Removed ambient light sensor drivers patch."${erase_style}

	echo ${text_progress}"> Removing battery status patch."${erase_style}
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleSmartBatteryManager.kext
	echo ${move_up}${erase_line}${text_success}"+ Removed battery status patch."${erase_style}

	echo ${text_progress}"> Removing AirPort drivers patch."${erase_style}
	Output_Off rm -R "$volume_path"/System/Library/Extensions/IO80211Family.kext/Contents/PlugIns/AirPortAtheros40.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/IO80211Family.kext/Contents/PlugIns/AppleAirPortBrcm43224.kext

	Output_Off rm -R "$volume_path"/System/Library/Extensions/corecapture.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/CoreCaptureResponder.kext
	echo ${move_up}${erase_line}${text_success}"+ Removed AirPort drivers patch."${erase_style}

	echo ${text_progress}"> Removing Bluetooth drivers patch."${erase_style}
	Output_Off rm -R "$volume_path"/System/Library/Extensions/IOBluetoothFamily.kext
	Output_Off rm -R "$volume_path"/System/Library/Extensions/IOBluetoothHIDDriver.kext
	echo ${move_up}${erase_line}${text_success}"+ Removed Bluetooth drivers patch."${erase_style}

	echo ${text_progress}"> Removing Siri application patch."${erase_style}
	Output_Off rm -R "$volume_path"/System/Library/PrivateFrameworks/SiriUI.framework
	echo ${move_up}${erase_line}${text_success}"+ Removed Siri application patch."${erase_style}

	echo ${text_progress}"> Removing software update check patch."${erase_style}
	Output_Off rm "$volume_path"/usr/local/lib/SUVMMFaker.dylib
	Output_Off rm "$volume_path"/System/Library/LaunchDaemons/com.apple.softwareupdated.plist
	echo ${move_up}${erase_line}${text_success}"+ Removed software update check patch."${erase_style}

	echo ${text_progress}"> Removing System Integrity Protection patch."${erase_style}
	Output_Off rm "$volume_path"/usr/local/sbin/SIPLD
	Output_Off rm -R "$volume_path"/Library/Extensions/SIPManager.kext
	echo ${move_up}${erase_line}${text_success}"+ Removed System Integrity Protection patch."${erase_style}

	echo ${text_progress}"> Removing Patch Updater."${erase_style}
	Output_Off rm "$volume_path"/usr/local/sbin/patchupdaterd
	Output_Off rm -R "$volume_path"/Applications/Utilities/Patch\ Updater.app
	Output_Off rm -R "$volume_path"/Library/PreferencePanes/Patch Updater Prefpane.prefPane
	echo ${move_up}${erase_line}${text_success}"+ Removed Patch Updater."${erase_style}

	Output_Off rm "$volume_path"/Library/LaunchAgents/com.dd1*
	Output_Off rm "$volume_path"/Library/LaunchAgents/com.dosdude1*
}

Restore_APFS()
{
	echo ${text_progress}"> Removing APFS system patch."${erase_style}
	rm /Volumes/EFI/EFI/BOOT/BOOTX64.efi
	rm /Volumes/EFI/EFI/apfs.efi

	if [[ $volume_patch_variant == "2" ]]; then
		rm -R "$volume_path"/Library/PreferencePanes/APFS\ Boot\ Selector.prefPane
	fi
	echo ${move_up}${erase_line}${text_success}"+ Removed APFS system patch."${erase_style}
}

Restore_Hybrid_Mode()
{
	echo ${text_progress}"> Removing Hybrid Mode patch."${erase_style}
	rm "$volume_path"/System/Library/PrivateFrameworks/CoreUI.framework/Versions/Current/CoreUI
	mv "$volume_path"/System/Library/PrivateFrameworks/CoreUI.framework/Versions/Current/CoreUI-bak "$volume_path"/System/Library/PrivateFrameworks/CoreUI.framework/Versions/Current/CoreUI

	if [[ $volume_patch_menubar == "1" ]]; then
		rm "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox
		mv "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox-bak "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox
	fi
	echo ${move_up}${erase_line}${text_success}"+ Removed Hybrid Mode."${erase_style}
}

Restore_Flat_Mode()
{
	echo ${text_progress}"> Removing Flat Mode patch."${erase_style}
	rm "$volume_path"/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit
	mv "$volume_path"/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit-bak "$volume_path"/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit

	if [[ $volume_patch_menubar == "1" ]]; then
		rm "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox
		mv "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox-bak "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox
	fi
	echo ${move_up}${erase_line}${text_success}"+ Removed Flat Mode patch."${erase_style}
}

Repair()
{
	chown -R 0:0 "$@"
	chmod -R 755 "$@"
}

Repair_Permissions_Volume()
{
	echo ${text_progress}"> Repairing permissions."${erase_style}
	Repair "$volume_path"/System/Library/PrivateFrameworks/CoreUI.framework
	Repair "$volume_path"/System/Library/Frameworks/AppKit.framework
	Repair "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework
	echo ${move_up}${erase_line}${text_success}"+ Repaired permissions."${erase_style}
}

End()
{
	Output_Off diskutil unmount /Volumes/EFI

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
Check_SIP
Input_Model
Input_Volume
Check_Volume_Version
Mount_EFI
Input_Operation
Run_Operation
End