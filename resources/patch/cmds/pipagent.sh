#!/bin/sh

pip_config="$(nvram -p|grep pipconfig)"

Check_Version()
{
	volume_version="$(defaults read /System/Library/CoreServices/SystemVersion.plist ProductVersion)"
	volume_version_short="$(defaults read /System/Library/CoreServices/SystemVersion.plist ProductVersion | cut -c-5)"

	volume_build="$(defaults read /System/Library/CoreServices/SystemVersion.plist ProductBuildVersion)"

	if [[ -e "$volume_path"/System/Library/CoreServices/SystemVersion-pip.plist ]]; then
		volume_version_pip="$(defaults read /System/Library/CoreServices/SystemVersion-pip.plist ProductVersion)"
		volume_version_pip_short="$(defaults read /System/Library/CoreServices/SystemVersion-pip.plist ProductVersion | cut -c-5)"

		volume_build_pip="$(defaults read /System/Library/CoreServices/SystemVersion-pip.plist ProductBuildVersion)"
	fi

	if [[ ! $volume_version == $volume_version_pip ]]; then
		volume_versions_differ="1"
	fi
	if [[ ! $volume_build == $volume_build_pip ]]; then
		volume_builds_differ="1"
	fi
}

Display_Alert()
{
	if [[ $volume_versions_differ == "1" || $volume_builds_differ == "1" ]]; then
		if [[ $pip_config == *"1"* ]]; then
			open -a /Library/Application\ Support/com.rmc.pipagent/Patch\ Integrity\ Protection.app
		fi
		if [[ ! $pip_config == *"1"* ]]&&[[ ! $pip_config == *"0"* ]]; then
			open -a /Library/Application\ Support/com.rmc.pipagent/Patch\ Integrity\ Protection.app
		fi
	fi
}

Check_Version
Display_Alert