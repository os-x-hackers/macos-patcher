#!/bin/sh

pip_config="$(nvram -p|grep pipconfig)"

volume_version="$(grep -A1 "ProductVersion" /System/Library/CoreServices/SystemVersion.plist)"
volume_build="$(grep -A1 "ProductBuildVersion" /System/Library/CoreServices/SystemVersion.plist)"

volume_version="${volume_version#*<string>}"
volume_version="${volume_version%</string>*}"
volume_build="${volume_build#*<string>}"
volume_build="${volume_build%</string>*}"

volume_version_short="${volume_version:0:5}"

volume_version_pip="$(grep -A1 "ProductVersion" /System/Library/CoreServices/SystemVersion-pip.plist)"
volume_build_pip="$(grep -A1 "ProductBuildVersion" /System/Library/CoreServices/SystemVersion-pip.plist)"

volume_version_pip="${volume_version_pip#*<string>}"
volume_version_pip="${volume_version_pip%</string>*}"
volume_build_pip="${volume_build_pip#*<string>}"
volume_build_pip="${volume_build_pip%</string>*}"

volume_version_pip_short="${volume_version:0:5}"

if [[ ! $volume_version == $volume_version_pip ]]; then
	volume_versions_differ="1"
fi
if [[ ! $volume_build == $volume_build_pip ]]; then
	volume_builds_differ="1"
fi

if [[ $volume_versions_differ == "1" || $volume_builds_differ == "1" ]]; then
	if [[ $pip_config == *"1"* ]]; then
		open -a /Library/Application\ Support/com.rmc.pipagent/pipagent.app
	fi
	if [[ ! $pip_config == *"1"* ]]&&[[ ! $pip_config == *"0"* ]]; then
		open -a /Library/Application\ Support/com.rmc.pipagent/pipagent.app
	fi
fi