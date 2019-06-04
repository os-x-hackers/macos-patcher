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

Input_Operation()
{
	pip_config="$(nvram -p|grep pipconfig)"

	echo ${text_message}"/ What operation would you like to run?"${erase_style}
	echo ${text_message}"/ Input an operation number."${erase_style}
	echo ${text_message}"/     1 - Show Patch Integrity Protection status"${erase_style}
	echo ${text_message}"/     2 - Enable Patch Integrity Protection"${erase_style}
	echo ${text_message}"/     3 - Disable Patch Integrity Protection"${erase_style}
	Input_On
	read -e -p "/ " operation
	Input_Off

	if [[ $operation == "1" ]]; then
		if [[ $pip_config == *"1"* ]]; then
			echo ${text_message}"+ System Update Detection is enabled."${erase_style}
			Input_On
			exit
		fi

		if [[ $pip_config == *"0"* ]]; then
			echo ${text_message}"+ System Update Detection is disabled."${erase_style}
			Input_On
			exit
		fi

		if [[ ! $pip_config == *"1"* && ! $pip_config == *"0"* ]]; then
			echo ${text_message}"+ System Update Detection is enabled."${erase_style}
			Input_On
			exit
		fi
	fi

	if [[ $operation == "2" ]]; then
		nvram pipconfig="1"
		echo ${move_up}${erase_line}${text_success}"+ Enabled Patch Integrity Protection."${erase_style}
		Input_On
		exit
	fi

	if [[ $operation == "3" ]]; then
		nvram pipconfig="0"
		echo ${move_up}${erase_line}${text_success}"+ Disabled Patch Integrity Protection."${erase_style}
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
Input_Operation