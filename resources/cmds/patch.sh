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

	resources_path="${directory_path%/*}/patch"
}

Input_Off()
{
	stty -echo
}

Input_On()
{
	stty echo
}

Output_Off()
{
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

model_apfs="iMac7,1
iMac8,1
iMac9,1
MacBook4,1
MacBook5,1
MacBook5,2
MacBookAir2,1
MacBookPro4,1
MacBookPro5,1
MacBookPro5,2
MacBookPro5,3
MacBookPro5,4
MacBookPro5,5
Macmini3,1
MacPro3,1
MacPro4,1
Xserve2,1
Xserve3,1"

model_airport="iMac7,1
iMac8,1
MacBookAir2,1
MacBookPro4,1
Macmini3,1
MacPro3,1"
	
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

	if [[ "$model_airport" == *"$model"* ]]; then
		model_airport="1"
	fi
	if [[ "$model_apfs" == *"$model"* ]]; then
		model_apfs="1"
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

Check_Volume_Version()
{
	echo ${text_progress}"> Checking system version."${erase_style}	
	volume_version="$(defaults read "$volume_path"/System/Library/CoreServices/SystemVersion.plist ProductVersion)"
	volume_version_short="$(defaults read "$volume_path"/System/Library/CoreServices/SystemVersion.plist ProductVersion | cut -c-5)"

	volume_build="$(defaults read "$volume_path"/System/Library/CoreServices/SystemVersion.plist ProductBuildVersion)"

	if [[ -e "$volume_path"/System/Library/CoreServices/SystemVersion-pip.plist ]]; then
		volume_version_pip="$(defaults read "$volume_path"/System/Library/CoreServices/SystemVersion-pip.plist ProductVersion)"
		volume_version_pip_short="$(defaults read "$volume_path"/System/Library/CoreServices/SystemVersion-pip.plist ProductVersion | cut -c-5)"

		volume_build_pip="$(defaults read "$volume_path"/System/Library/CoreServices/SystemVersion-pip.plist ProductBuildVersion)"
	fi

	if [[ ! $volume_version == $volume_version_pip ]]; then
		volume_versions_differ="1"
	fi
	if [[ ! $volume_build == $volume_build_pip ]]; then
		volume_builds_differ="1"
	fi
	echo ${move_up}${erase_line}${text_success}"+ Checked system version."${erase_style}
}

Check_Volume_Support()
{
	echo ${text_progress}"> Checking system support."${erase_style}
	if [[ $volume_version_short == "10.1"[2-4] ]]; then
		echo ${move_up}${erase_line}${text_success}"+ System support check passed."${erase_style}
	else
		echo ${text_error}"- System support check failed."${erase_style}
		echo ${text_message}"/ Run this tool on a supported system."${erase_style}
		Input_On
		exit
	fi
}

Check_Volume_dosdude()
{
	if [ -e $volume_path/Library/LaunchAgents/com.dd1* ] || [ -e $volume_path/Library/LaunchAgents/com.dosdude1* ]; then
		echo ${text_warning}"! A system patch by another patcher already exists."${erase_style}
		echo ${text_message}"/ What operation would you like to run?"${erase_style}
		echo ${text_message}"/ Input an operation number."${erase_style}
		echo ${text_message}"/     1 - Abort and keep system patch"${erase_style}
		echo ${text_message}"/     2 - Proceed and restore system"${erase_style}
		Input_On
		read -e -p "/ " operation_overwrite
		Input_Off

		if [[ $operation_overwrite == "1" ]]; then
			echo "\033[7A"
			echo ${erase_line}${text_warning}"! A system patch by another patcher already exists."${erase_style}
			echo ${erase_line}${text_message}"/ Run this tool with another operation."${erase_style}
			Input_On
			exit
		fi

		if [[ $operation_overwrite == "2" ]]; then
			echo "\033[7A"
			echo ${erase_line}${text_warning}"! A system restore requires a reinstall after completion."
			echo ${erase_line}${text_message}"/ Are you sure you want to continue?."${erase_style}
			echo ${erase_line}${text_message}"/ Input an operation number."${erase_style}
			echo ${erase_line}${text_message}"/     1 - No"${erase_style}
			echo ${erase_line}${text_message}"/     2 - Yes"${erase_style}
			Input_On
			read -e -p "/ " operation_confirmation
			Input_Off

			if [[ $operation_confirmation == "1" ]]; then
				echo "\033[7A"
				echo ${erase_line}${text_warning}"! A system patch by another patcher already exists."${erase_style}
				echo ${erase_line}${text_message}"/ Run this tool with another operation."${erase_style}
				Input_On
				exit
			fi

			if [[ $operation_confirmation == "2" ]]; then
				echo "\033[7A"
				source "$directory_path"/restore
				Restore_Volume_dosdude
			fi
		fi
	fi
}

Volume_Variables()
{
	if [[ -e /Volumes/EFI/EFI/BOOT/BOOTX64.efi && -e /Volumes/EFI/EFI/apfs.efi ]]; then
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

Clean_Volume()
{
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

	if [[ -d "$volume_path"/Library/Application\ Support/com.rmc.pipagent/pipagent.app ]]; then
		rm -R "$volume_path"/Library/Application\ Support/com.rmc.pipagent/pipagent.app
	fi
}

Patch_Volume()
{
	echo ${text_progress}"> Patching input drivers."${erase_style}
	cp -R "$resources_path"/LegacyUSBEthernet.kext "$volume_path"/System/Library/Extensions
	cp -R "$resources_path"/LegacyUSBInjector.kext "$volume_path"/System/Library/Extensions

	if [[ $volume_version_short == "10.14" ]]; then
		cp -R "$resources_path"/AppleUSBACM.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/IOUSBFamily.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/IOUSBHostFamily.kext "$volume_path"/System/Library/Extensions
	fi

	if [[ $model == "MacBook4,1" ]]; then
		cp -R "$resources_path"/MacBook4,1/AppleHIDMouse.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/AppleHSSPIHIDDriver.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/AppleIRController.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/AppleMultitouchDriver.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/AppleTopCase.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/AppleUSBMultitouch.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/AppleUSBTopCase.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/IOBDStorageFamily.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/IOSerialFamily.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/IOUSBFamily.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/IOUSBHostFamily.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/IOUSBMassStorageClass.kext "$volume_path"/System/Library/Extensions
	fi

	if [[ $model == "MacBook5,2" ]]; then
		cp -R "$resources_path"/AppleTopCase.kext "$volume_path"/System/Library/Extensions
	fi
	echo ${move_up}${erase_line}${text_success}"+ Patched input drivers."${erase_style}

	echo ${text_progress}"> Patching graphics drivers."${erase_style}
	if [[ $volume_version_short == "10.1"[3-4] ]]; then
		cp -R "$resources_path"/AMDRadeonX3000.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMDRadeonX3000GLDriver.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMDRadeonX4000.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMDRadeonX4000GLDriver.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/IOAccelerator2D.plugin "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/IOAcceleratorFamily2.kext "$volume_path"/System/Library/Extensions
	fi

	if [[ $volume_version_short == "10.14" ]]; then
		cp -R "$resources_path"/AMD2400Controller.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMD2600Controller.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMD3800Controller.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMD4600Controller.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMD4800Controller.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMD5000Controller.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMD6000Controller.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMDFramebuffer.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMDLegacyFramebuffer.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMDLegacySupport.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMDRadeonVADriver.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMDRadeonVADriver2.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMDRadeonX4000HWServices.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMDShared.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AMDSupport.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelFramebufferAzul.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelFramebufferCapri.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelHD3000Graphics.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelHD3000GraphicsGA.plugin "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelHD3000GraphicsGLDriver.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelHD3000GraphicsVADriver.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelHDGraphics.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelHDGraphicsFB.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelHDGraphicsGA.plugin "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelHDGraphicsGLDriver.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelHDGraphicsVADriver.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelSNBGraphicsFB.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleIntelSNBVA.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/ATIRadeonX2000.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/ATIRadeonX2000GA.plugin "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/ATIRadeonX2000GLDriver.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/ATIRadeonX2000VADriver.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/GeForceTesla.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/GeForceTeslaGLDriver.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/GeForceTeslaVADriver.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/IOGraphicsFamily.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/IONDRVSupport.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/NVDANV50HalTesla.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/NVDAResmanTesla.kext "$volume_path"/System/Library/Extensions
	fi

	if [[ $volume_version == "10.14."[4-6] ]]; then
		Output_Off rm -R "$volume_path"/System/Library/PrivateFrameworks/GPUSupport.framework
		Output_Off rm -R "$volume_path"/System/Library/Frameworks/OpenGL.framework
		cp -R "$resources_path"/GPUSupport.framework "$volume_path"/System/Library/PrivateFrameworks
		cp -R "$resources_path"/OpenGL.framework "$volume_path"/System/Library/Frameworks
	fi

	if [[ $volume_version == "10.14."[5-6] ]]; then
		Output_Off rm -R "$volume_path"/System/Library/Frameworks/CoreDisplay.framework
		cp -R "$resources_path"/CoreDisplay.framework "$volume_path"/System/Library/Frameworks
	fi

	if [[ $model == "MacBook4,1" ]]; then
		cp -R "$resources_path"/MacBook4,1/AppleIntelGMAX3100.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/AppleIntelGMAX3100FB.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/AppleIntelGMAX3100GA.plugin "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/AppleIntelGMAX3100GLDriver.bundle "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/AppleIntelGMAX3100VADriver.bundle "$volume_path"/System/Library/Extensions
	fi

	if [[ $model == "MacBookPro6,2" && $volume_version == "10.14."[5-6] ]]; then
		cp -R "$resources_path"/AppleGraphicsControl.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleGraphicsPowerManagement.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/AppleMCCSControl.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/GPUWrangler.framework "$volume_path"/System/Library/PrivateFrameworks
	fi
	echo ${move_up}${erase_line}${text_success}"+ Patched graphics drivers."${erase_style}

	echo ${text_progress}"> Patching audio drivers."${erase_style}
	if [[ $model == "MacBook4,1" ]]; then
		cp -R "$resources_path"/MacBook4,1/AppleHDA.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/IOAudioFamily.kext "$volume_path"/System/Library/Extensions
	else
		cp -R "$resources_path"/AppleHDA.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/IOAudioFamily.kext "$volume_path"/System/Library/Extensions
	fi
	echo ${move_up}${erase_line}${text_success}"+ Patched audio drivers."${erase_style}

	echo ${text_progress}"> Patching backlight drivers."${erase_style}
	cp -R "$resources_path"/AppleBacklight.kext "$volume_path"/System/Library/Extensions
	cp -R "$resources_path"/AppleBacklightExpert.kext "$volume_path"/System/Library/Extensions
	Output_Off rm -R "$volume_path"/System/Library/PrivateFrameworks/DisplayServices.framework
	cp -R "$resources_path"/DisplayServices.framework "$volume_path"/System/Library/PrivateFrameworks
	Output_Off rm -R "$volume_path"/System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AGDCBacklightControl.kext
	echo ${move_up}${erase_line}${text_success}"+ Patched backlight drivers."${erase_style}

	echo ${text_progress}"> Patching ambient light sensor drivers."${erase_style}
	cp -R "$resources_path"/AmbientLightSensorHID.plugin "$volume_path"/System/Library/Extensions/AppleSMCLMU.kext/Contents/PlugIns/
	echo ${move_up}${erase_line}${text_success}"+ Patched ambient light sensor drivers."${erase_style}

	if [[ $model_airport == "1" || $model == "MacBook4,1" || $volume_version_short == "10.14" ]]; then
		echo ${text_progress}"> Patching AirPort drivers."${erase_style}
	fi

	if [[ $volume_version_short == "10.14" ]]; then
		cp -R "$resources_path"/AirPortAtheros40.kext "$volume_path"/System/Library/Extensions/IO80211Family.kext/Contents/PlugIns
	fi

	if [[ $model_airport == "1" ]]; then
		cp -R "$resources_path"/AppleAirPortBrcm43224.kext "$volume_path"/System/Library/Extensions/IO80211Family.kext/Contents/PlugIns
		cp -R "$resources_path"/corecapture.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/CoreCaptureResponder.kext "$volume_path"/System/Library/Extensions
		Output_Off rm -R "$volume_path"/System/Library/Extensions/IO80211FamilyV2.kext
	fi

	if [[ $model == "MacBook4,1" ]]; then
		cp -R "$resources_path"/MacBook4,1/IO80211Family.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/AppleAirPortBrcm43.kext "$volume_path"/System/Library/Extensions/IO80211Family.kext/Contents/PlugIns
	fi

	if [[ $model_airport == "1" || $model == "MacBook4,1" || $volume_version_short == "10.14" ]]; then
		echo ${move_up}${erase_line}${text_success}"+ Patched AirPort drivers."${erase_style}
	fi

	if [[ $model == "MacBook4,1" ]]; then
		echo ${text_progress}"> Patching Bluetooth drivers."${erase_style}
		cp -R "$resources_path"/MacBook4,1/IOBluetoothFamily.kext "$volume_path"/System/Library/Extensions
		cp -R "$resources_path"/MacBook4,1/IOBluetoothHIDDriver.kext "$volume_path"/System/Library/Extensions
		echo ${move_up}${erase_line}${text_success}"+ Patched Bluetooth drivers."${erase_style}
	fi

	if [[ $volume_version == "10.14."[4-6] ]]; then
		echo ${text_progress}"> Patching Siri application."${erase_style}
		Output_Off rm -R "$volume_path"/System/Library/PrivateFrameworks/SiriUI.framework
		cp -R "$resources_path"/SiriUI.framework "$volume_path"/System/Library/PrivateFrameworks
		echo ${move_up}${erase_line}${text_success}"+ Patched Siri application."${erase_style}
	fi

	echo ${text_progress}"> Patching software update check."${erase_style}
	if [[ $volume_version_short == "10.12" ]]; then
		cp "$resources_path"/SUVMMFaker-v1.dylib "$volume_path"/usr/lib/SUVMMFaker.dylib
	else
		cp "$resources_path"/SUVMMFaker-v2.dylib "$volume_path"/usr/lib/SUVMMFaker.dylib
	fi
	cp "$resources_path"/com.apple.softwareupdated.plist "$volume_path"/System/Library/LaunchDaemons
	echo ${move_up}${erase_line}${text_success}"+ Patched software update check."${erase_style}

	echo ${text_progress}"> Patching platform support check."${erase_style}
	Output_Off rm "$volume_path"/System/Library/CoreServices/PlatformSupport.plist
	echo ${move_up}${erase_line}${text_success}"+ Patched platform support check."${erase_style}

	if [[ $volume_version_short == "10.14" ]]; then
		echo ${text_progress}"> Patching kernel panic issue."${erase_style}
		Output_Off rm -R "$volume_path"/System/Library/UserEventPlugins/com.apple.telemetry.plugin
		echo ${move_up}${erase_line}${text_success}"+ Patched kernel panic issue."${erase_style}
	fi

	echo ${text_progress}"> Patching kernel cache."${erase_style}
	Output_Off rm "$volume_path"/System/Library/PrelinkedKernels/prelinkedkernel
	Output_Off kextcache -update-volume "$volume_path"
	echo ${move_up}${erase_line}${text_success}"+ Patched kernel cache."${erase_style}

	echo ${text_progress}"> Patching System Integrity Protection."${erase_style}
	cp -R "$resources_path"/SIPManager.kext "$volume_path"/System/Library/Extensions
	echo ${move_up}${erase_line}${text_success}"+ Patched System Integrity Protection."${erase_style}

	echo ${text_progress}"> Copying patcher utilities."${erase_style}
	if [[ ! -d "$volume_path"/Library/Application\ Support/com.rmc.pipagent ]]; then
		mkdir "$volume_path"/Library/Application\ Support/com.rmc.pipagent
	fi

	cp "$volume_path/$system_version_path" "$volume_path/$system_version_pip_path"
	cp "$resources_path"/com.rmc.pipagent.plist "$volume_path"/Library/LaunchAgents
	cp -R "$resources_path"/Patch\ Integrity\ Protection.app "$volume_path"/Library/Application\ Support/com.rmc.pipagent/
	cp "$resources_path"/cmds/pipagent.sh "$volume_path"/Library/Application\ Support/com.rmc.pipagent/pipagent
	cp "$resources_path"/cmds/piputil.sh "$volume_path"/usr/bin/piputil
	chmod +x "$volume_path"/Library/Application\ Support/com.rmc.pipagent/pipagent
	chmod +x "$volume_path"/usr/bin/piputil

	if [[ $volume_version_short == "10.14" ]]; then
		cp "$resources_path"/cmds/transutil.sh "$volume_path"/usr/bin/transutil
		chmod +x "$volume_path"/usr/bin/transutil

		if [[ $volume_versions_differ == "1" || $volume_builds_differ == "1" ]]; then
			if [[ $volume_patch_hybrid_mode == "1" ]]; then
				rm "$volume_path"/System/Library/PrivateFrameworks/CoreUI.framework/Versions/Current/CoreUI-bak
			fi
			if [[ $volume_patch_flat_mode == "1" ]]; then
				rm "$volume_path"/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit-bak
			fi
			if [[ $volume_patch_menubar == "1" ]]; then
				rm "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/Current/HIToolbox-bak
			fi
		fi
	fi
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
	Repair "$volume_path"/System/Library/Extensions/LegacyUSBEthernet.kext
	Repair "$volume_path"/System/Library/Extensions/LegacyUSBInjector.kext

	if [[ $volume_version_short == "10.14" ]]; then
		Repair "$volume_path"/System/Library/Extensions/AppleUSBACM.kext
		Repair "$volume_path"/System/Library/Extensions/IOUSBFamily.kext
		Repair "$volume_path"/System/Library/Extensions/IOUSBHostFamily.kext
	fi

	if [[ $model == "MacBook4,1" ]]; then
		Repair "$volume_path"/System/Library/Extensions/AppleHIDMouse.kext
		Repair "$volume_path"/System/Library/Extensions/AppleHSSPIHIDDriver.kext
		Repair "$volume_path"/System/Library/Extensions/AppleIRController.kext
		Repair "$volume_path"/System/Library/Extensions/AppleTopCase.kext
		Repair "$volume_path"/System/Library/Extensions/AppleUSBMultitouch.kext
		Repair "$volume_path"/System/Library/Extensions/AppleUSBTopCase.kext
		Repair "$volume_path"/System/Library/Extensions/IOBDStorageFamily.kext
		Repair "$volume_path"/System/Library/Extensions/IOSerialFamily.kext
		Repair "$volume_path"/System/Library/Extensions/IOUSBFamily.kext
		Repair "$volume_path"/System/Library/Extensions/IOUSBHostFamily.kext
		Repair "$volume_path"/System/Library/Extensions/IOUSBMassStorageClass.kext
	fi

	Repair "$volume_path"/System/Library/Extensions/AppleTopCase.kext

	Repair "$volume_path"/System/Library/Extensions/AMDRadeonX3000.kext
	Repair "$volume_path"/System/Library/Extensions/AMDRadeonX3000GLDriver.bundle
	Repair "$volume_path"/System/Library/Extensions/AMDRadeonX4000.kext
	Repair "$volume_path"/System/Library/Extensions/AMDRadeonX4000GLDriver.bundle
	Repair "$volume_path"/System/Library/Extensions/IOAccelerator2D.plugin
	Repair "$volume_path"/System/Library/Extensions/IOAcceleratorFamily2.kext

	Repair "$volume_path"/System/Library/Extensions/AMD2400Controller.kext
	Repair "$volume_path"/System/Library/Extensions/AMD2600Controller.kext
	Repair "$volume_path"/System/Library/Extensions/AMD3800Controller.kext
	Repair "$volume_path"/System/Library/Extensions/AMD4600Controller.kext
	Repair "$volume_path"/System/Library/Extensions/AMD4800Controller.kext
	Repair "$volume_path"/System/Library/Extensions/AMD5000Controller.kext
	Repair "$volume_path"/System/Library/Extensions/AMD6000Controller.kext
	Repair "$volume_path"/System/Library/Extensions/AMDFramebuffer.kext
	Repair "$volume_path"/System/Library/Extensions/AMDLegacyFramebuffer.kext
	Repair "$volume_path"/System/Library/Extensions/AMDLegacySupport.kext
	Repair "$volume_path"/System/Library/Extensions/AMDRadeonVADriver.bundle
	Repair "$volume_path"/System/Library/Extensions/AMDRadeonVADriver2.bundle
	Repair "$volume_path"/System/Library/Extensions/AMDRadeonX4000HWServices.kext
	Repair "$volume_path"/System/Library/Extensions/AMDShared.bundle
	Repair "$volume_path"/System/Library/Extensions/AMDSupport.kext
	Repair "$volume_path"/System/Library/Extensions/AppleIntelFramebufferAzul.kext
	Repair "$volume_path"/System/Library/Extensions/AppleIntelFramebufferCapri.kext
	Repair "$volume_path"/System/Library/Extensions/AppleIntelHD3000Graphics.kext
	Repair "$volume_path"/System/Library/Extensions/AppleIntelHD3000GraphicsGA.plugin
	Repair "$volume_path"/System/Library/Extensions/AppleIntelHD3000GraphicsGLDriver.bundle
	Repair "$volume_path"/System/Library/Extensions/AppleIntelHD3000GraphicsVADriver.bundle
	Repair "$volume_path"/System/Library/Extensions/AppleIntelHDGraphics.kext
	Repair "$volume_path"/System/Library/Extensions/AppleIntelHDGraphicsFB.kext
	Repair "$volume_path"/System/Library/Extensions/AppleIntelHDGraphicsGA.plugin
	Repair "$volume_path"/System/Library/Extensions/AppleIntelHDGraphicsGLDriver.bundle
	Repair "$volume_path"/System/Library/Extensions/AppleIntelHDGraphicsVADriver.bundle
	Repair "$volume_path"/System/Library/Extensions/AppleIntelSNBGraphicsFB.kext
	Repair "$volume_path"/System/Library/Extensions/AppleIntelSNBVA.bundle
	Repair "$volume_path"/System/Library/Extensions/ATIRadeonX2000.kext
	Repair "$volume_path"/System/Library/Extensions/ATIRadeonX2000GA.plugin
	Repair "$volume_path"/System/Library/Extensions/ATIRadeonX2000GLDriver.bundle
	Repair "$volume_path"/System/Library/Extensions/ATIRadeonX2000VADriver.bundle
	Repair "$volume_path"/System/Library/Extensions/GeForceTesla.kext
	Repair "$volume_path"/System/Library/Extensions/GeForceTeslaGLDriver.bundle
	Repair "$volume_path"/System/Library/Extensions/GeForceTeslaVADriver.bundle
	Repair "$volume_path"/System/Library/Extensions/IOGraphicsFamily.kext
	Repair "$volume_path"/System/Library/Extensions/IONDRVSupport.kext
	Repair "$volume_path"/System/Library/Extensions/NVDANV50HalTesla.kext
	Repair "$volume_path"/System/Library/Extensions/NVDAResmanTesla.kext

	if [[ $volume_version == "10.14."[4-6] ]]; then
		Repair "$volume_path"/System/Library/Frameworks/CoreDisplay.framework
		Repair "$volume_path"/System/Library/PrivateFrameworks/GPUSupport.framework
		Repair "$volume_path"/System/Library/Frameworks/OpenGL.framework
	fi

	if [[ $model == "MacBook4,1" ]]; then
		Repair "$volume_path"/System/Library/Extensions/AppleIntelGMAX3100.kext
		Repair "$volume_path"/System/Library/Extensions/AppleIntelGMAX3100FB.kext
		Repair "$volume_path"/System/Library/Extensions/AppleIntelGMAX3100GA.plugin
		Repair "$volume_path"/System/Library/Extensions/AppleIntelGMAX3100GLDriver.bundle
		Repair "$volume_path"/System/Library/Extensions/AppleIntelGMAX3100VADriver.bundle
	fi

	if [[ $model == "MacBookPro6,2" && $volume_version == "10.14."[5-6] ]]; then
		Repair "$volume_path"/System/Library/Extensions/AppleGraphicsControl.kext
		Repair "$volume_path"/System/Library/Extensions/AppleGraphicsPowerManagement.kext
		Repair "$volume_path"/System/Library/Extensions/AppleMCCSControl.kext
		Repair "$volume_path"/System/Library/PrivateFrameworks/GPUWrangler.framework
	fi

	Repair "$volume_path"/System/Library/Extensions/AppleHDA.kext
	Repair "$volume_path"/System/Library/Extensions/IOAudioFamily.kext

	Repair "$volume_path"/System/Library/Extensions/AppleBacklight.kext
	Repair "$volume_path"/System/Library/Extensions/AppleBacklightExpert.kext
	Repair "$volume_path"/System/Library/PrivateFrameworks/DisplayServices.framework

	Repair "$volume_path"/System/Library/Extensions/AppleSMCLMU.kext

	if [[ $model_airport == "1" ]]; then
		Repair "$volume_path"/System/Library/Extensions/IO80211Family.kext
		Repair "$volume_path"/System/Library/Extensions/corecapture.kext
		Repair "$volume_path"/System/Library/Extensions/CoreCaptureResponder.kext
	fi

	if [[ $model == "MacBook4,1" ]]; then
		Repair "$volume_path"/System/Library/Extensions/IO80211Family.kext

		Repair "$volume_path"/System/Library/Extensions/IOBluetoothFamily.kext
		Repair "$volume_path"/System/Library/Extensions/IOBluetoothHIDDriver.kext
	fi

	Repair "$volume_path"/System/Library/PrivateFrameworks/SiriUI.framework

	Repair "$volume_path"/usr/lib/SUVMMFaker.dylib
	Repair "$volume_path"/System/Library/LaunchDaemons/com.apple.softwareupdated.plist 

	Repair "$volume_path"/System/Library/Extensions/SIPManager.kext

	Repair "$volume_path/$system_version_pip_path"
	Repair "$volume_path"/Library/LaunchAgents/com.rmc.pipagent.plist
	Repair "$volume_path"/Library/Application\ Support/com.rmc.pipagent
	Repair "$volume_path"/usr/bin/piputil

	if [[ $volume_version_short == "10.14" ]]; then
		Repair "$volume_path"/usr/bin/transutil
	fi
	echo ${move_up}${erase_line}${text_success}"+ Repaired permissions."${erase_style}
}

Input_Operation_APFS()
{
	if [[ "$(diskutil info "$volume_name"|grep "APFS")" == *"APFS"* ]]; then
		if [[ $model_apfs == "1" ]]; then
			echo ${text_warning}"! Your system doesn't support APFS."${erase_style}
			echo ${text_message}"/ What operation would you like to run?"${erase_style}
			echo ${text_message}"/ Input an operation number."${erase_style}
			echo ${text_message}"/     1 - Install the APFS patch"${erase_style}
			echo ${text_message}"/     2 - Continue without the APFS patch"${erase_style}
			Input_On
			read -e -p "/ " operation_apfs
			Input_Off

			if [[ $operation_apfs == "1" ]]; then
				Patch_APFS
			fi
		fi
	fi
}

Patch_APFS()
{
	echo ${text_progress}"> Installing APFS system patch."${erase_style}
	volume_uuid="$(diskutil info "$volume_name"|grep "Volume UUID")"
	volume_uuid="${volume_uuid:30:38}"

	if [[ ! -d /Volumes/EFI/EFI/BOOT ]]; then
		mkdir /Volumes/EFI/EFI/BOOT
	fi

	cp "$resources_path"/startup.nsh /Volumes/EFI/EFI/BOOT
	cp "$resources_path"/BOOTX64.efi /Volumes/EFI/EFI/BOOT
	cp "$volume_path"/usr/standalone/i386/apfs.efi /Volumes/EFI/EFI

	if [[ -d "$volume_path"/Library/PreferencePanes/APFS\ Boot\ Selector.prefPane ]]; then
		rm -R "$volume_path"/Library/PreferencePanes/APFS\ Boot\ Selector.prefPane
	fi

	sed -i '' "s/volume_uuid/$volume_uuid/g" /Volumes/EFI/EFI/BOOT/startup.nsh

	if [[ $(diskutil info "$volume_name"|grep "Device Location") == *"Internal" ]]; then
		bless --mount /Volumes/EFI --setBoot --file /Volumes/EFI/EFI/BOOT/BOOTX64.efi --shortform
	fi
	echo ${move_up}${erase_line}${text_success}"+ Installed APFS system patch."${erase_style}
}

Patch_Volume_Helpers()
{
	disk_identifier="$(diskutil info "$volume_name"|grep "Device Identifier")"
	disk_identifier="disk${disk_identifier#*disk}"
	disk_identifier_whole="$(diskutil info "$volume_name"|grep "Part of Whole")"
	disk_identifier_whole="disk${disk_identifier_whole#*disk}"
	disk_identifier_number="$((${disk_identifier: -1} + 1))"

	if [[ "$(diskutil info "$volume_name"|grep "APFS")" == *"APFS"* ]]; then
		echo ${text_progress}"> Patching Preboot partition."${erase_style}
		if [[ "$(diskutil info "${disk_identifier_whole}s2"|grep "Volume Name")" == *"Preboot" ]]; then
			preboot_identifier="${disk_identifier_whole}s2"
		fi
		if [[ "$(diskutil info "${disk_identifier_whole}s3"|grep "Volume Name")" == *"Preboot" ]]; then
			preboot_identifier="${disk_identifier_whole}s3"
		fi
		if [[ "$(diskutil info "${disk_identifier_whole}s4"|grep "Volume Name")" == *"Preboot" ]]; then
			preboot_identifier="${disk_identifier_whole}s4"
		fi

		if [[ ! "$(diskutil info "${preboot_identifier}"|grep "Volume Name")" == *"Preboot" ]]; then
			echo ${text_error}"- Fatal error patching Preboot partition."${erase_style}
			exit
		else

			Output_Off diskutil mount "$preboot_identifier"

			for numeric_folder in /Volumes/Preboot/*; do
				if [[ -e "$numeric_folder/$system_version_path" ]]; then
					preboot_version="$(defaults read "$numeric_folder"/System/Library/CoreServices/SystemVersion.plist ProductVersion)"
					preboot_version_short="$(defaults read "$numeric_folder"/System/Library/CoreServices/SystemVersion.plist ProductVersion | cut -c-5)"
				fi
				
				if [[ "$(diskutil info "$volume_name"|grep "Volume UUID")" == *"${numeric_folder#/Volumes/Preboot/}"* ]]; then
					if [[ $volume_version_short == $preboot_version_short ]]; then
						preboot_folder="$numeric_folder"
					fi
				fi
			done

			if [[ ! $preboot_folder == "/Volumes/Preboot/"* ]]; then
				echo ${text_error}"- Fatal error patching Preboot partition."${erase_style}
				exit
			else
				Output_Off rm "$preboot_folder"/System/Library/CoreServices/PlatformSupport.plist

				Output_Off diskutil unmount /Volumes/Preboot
				echo ${move_up}${erase_line}${text_success}"+ Patched Preboot partition."${erase_style}
			fi
		fi

		echo ${text_progress}"> Patching Recovery partition."${erase_style}

		if [[ "$(diskutil info "${disk_identifier_whole}s2"|grep "Volume Name")" == *"Recovery" ]]; then
			recovery_identifier="${disk_identifier_whole}s2"
		fi
		if [[ "$(diskutil info "${disk_identifier_whole}s3"|grep "Volume Name")" == *"Recovery" ]]; then
			recovery_identifier="${disk_identifier_whole}s3"
		fi
		if [[ "$(diskutil info "${disk_identifier_whole}s4"|grep "Volume Name")" == *"Recovery" ]]; then
			recovery_identifier="${disk_identifier_whole}s4"
		fi

		if [[ ! "$(diskutil info "${recovery_identifier}"|grep "Volume Name")" == *"Recovery" ]]; then
			echo ${text_warning}"! Error patching Recovery partition."${erase_style}
		else

			Output_Off diskutil mount "$recovery_identifier"

			for numeric_folder in /Volumes/Recovery/*; do
				if [[ -e "$numeric_folder"/SystemVersion.plist ]]; then
					recovery_version="$(defaults read "$numeric_folder"/SystemVersion.plist ProductVersion)"
					recovery_version_short="$(defaults read "$numeric_folder"/SystemVersion.plist ProductVersion | cut -c-5)"
				fi

				if [[ "$(diskutil info "$volume_name"|grep "Volume UUID")" == *"${numeric_folder#/Volumes/Recovery/}"* ]]; then
					if [[ $volume_version_short == $recovery_version_short ]]; then
						recovery_folder="$numeric_folder"
					fi
				fi
			done

			if [[ ! "$recovery_folder" == "/Volumes/Recovery/"* ]]; then
				echo ${text_warning}"! Error patching Recovery partition."${erase_style}
			else
				Output_Off rm "$recovery_folder"/prelinkedkernel
				Output_Off rm "$recovery_folder"/immutablekernel
				cp /System/Library/PrelinkedKernels/prelinkedkernel "$numeric_folder"/immutablekernel

				Output_Off rm "$recovery_folder"/PlatformSupport.plist
				Output_Off sed -i '' 's|dmg</string>|dmg -no_compat_check</string>|' "$recovery_folder"/com.apple.boot.plist

				Output_Off diskutil apfs changeVolumeRole "$recovery_identifier" R
				Output_Off diskutil apfs updatePreboot "$recovery_identifier"

				Output_Off diskutil unmount /Volumes/Recovery
				echo ${move_up}${erase_line}${text_success}"+ Patched Recovery partition."${erase_style}
			fi
		fi
	fi

	if [[ "$(diskutil info "$volume_name"|grep "HFS")" == *"HFS"* ]]; then
		echo ${text_progress}"> Patching Recovery partition."${erase_style}
		recovery_identifier="${disk_identifier:0:6}${disk_identifier_number}"

		if [[ ! "$(diskutil info "${recovery_identifier}"|grep "Volume Name")" == *"Recovery HD" ]]; then
			echo ${text_warning}"! Error patching Recovery partition."${erase_style}
		else
			Output_Off diskutil mount "$recovery_identifier"

			Output_Off rm /Volumes/Recovery\ HD/com.apple.recovery.boot/prelinkedkernel
			cp /System/Library/PrelinkedKernels/prelinkedkernel /Volumes/Recovery\ HD/com.apple.recovery.boot

			Output_Off rm /Volumes/Recovery\ HD/com.apple.recovery.boot/PlatformSupport.plist

			Output_Off diskutil unmount /Volumes/Recovery\ HD
			echo ${move_up}${erase_line}${text_success}"+ Patched Recovery partition."${erase_style}
		fi
	fi
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
Check_Resources
Input_Model
Input_Volume
Mount_EFI
Check_Volume_Version
Check_Volume_Support
Check_Volume_dosdude
Volume_Variables
Clean_Volume
Patch_Volume
Repair_Permissions
Input_Operation_APFS
Patch_Volume_Helpers
End