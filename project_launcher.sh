#!/usr/bin/env bash
# ID: 977915
##
## FILE: project_launcher.sh
##
## DESCRIPTION: A manager script to quickly setup the VMs and monitor their network.
##
## AUTHOR: Hussam Alkhafaji (Github: Sam97ish)
##
## DATE: [03/01/2022]
## 
## VERSION: 0.9
##
## USAGE: project_launcher.sh [-a|b|c|d|s|m|h]
##
## EXIT CODES:
##      1 ==> vagrant up error, check vagrant_up_error.logs in logs folder.
##      2 ==> vagrant destroy error, check vagrant_destory_error.logs in logs folder.
##
##

########## Global variables ##########
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

logs_folder="project_launcher_logs"

ls_site_A="gateway-a client-a1" # Missing client-a2 because of my machine's memory limitations.
ls_site_B="gateway-b client-b1" # Missing client-b2
ls_cloud="gateway-s server-s1" # Missing server-s2
ls_router="router" 
 
########## Utility Functions ##########

# Prints help messsage.
Help(){

   echo "A manager script to quickly setup the VMs and monitor their network."
   echo
   echo "Syntax: project_launcher.sh [-a|b|c|d|s|m|h]"
   echo "options:"
   echo
   echo "-a     Runs vagrant up on site A VMs destroying them if they're already up. The Router and Cloud VMs will not be destroyed if already up by a previous call."
   echo
   echo "-b     Runs vagrant up on site B VMs destroying them if they're already up. The Router and Cloud VMs will not be destroyed if already up by a previous call."
   echo
   echo "-d     Destroys all current VMs."
   echo
   echo "-c     Destroys all Cloud site VMs."
   echo
   echo "-s     Start multiple ssh sessions to all Cloud servers and clients who are up at the moment."
   echo
   echo "-m     Start monitoring the network through the Router VM."
   echo   
   echo "-h     Print this Help."
   echo

}

# Prints Errors caused from commands.
# Input:
#   $1 Last command return status code.
#   $2 Command that caused the error.
#   $3 exit code number.
echo_error(){

    if [[ $1 -ne 0 ]]; then
        echo "${red}[ERROR] while running command '$2', exiting with code $3. Check the corresponding log file.${reset}" >&2
        exit $3
    fi
    
}

# Creates log folder in PWD.
create_logs(){

    if [[ ! -d "$PWD/${logs_folder}" ]]; then
        echo "[INFO] Creating logs folder in $PWD..."
        mkdir "project_launcher_logs"
    fi
    
}

# Destroy VMs given.
# Input:
#   $1 List of VMs.
#   $2 Name of group of VMs.
destroy_VMs(){

    echo "[INFO] Destroying any previously created VMs for $2..."
    for vm in $1; do
        vagrant destroy -f $vm >> "$PWD/${logs_folder}/vagrant_destory_debug.logs" 2>> "$PWD/${logs_folder}/vagrant_destory_error.logs"
        echo_error $? "vagrant vagrant destroy -f $vm" "2"
        echo "${green}[OK] The vm '$vm' has been destroyed!${reset}"
    done
    vagrant status
    echo "[INFO] $2 VMS destroyed!"
    
}

# Launches one VM instance.
# Input:
#   $1 VM name or ID to run using vagrant up.
launch_VM(){

    echo "[INFO] Running 'vagrant up $1'..."
    vagrant up $1 >> "$PWD/${logs_folder}/vagrant_up_debug.logs" 2>> "$PWD/${logs_folder}/vagrant_up_error.logs"
    echo_error $? "vagrant up $1" "1"
    echo "${green}[OK] The vm '$1' is up and running!${reset}"

}

# Launches the specified set of VMs.
# Input:
#   $1 List of VMs.
#   $2 Name of group of VMs.
launch_VMs(){ 

    echo "[INFO] Starting $2 VMs..."
    echo "[INFO] The following commands will take some time... Please be patient!"
    for vm in $1; do
        launch_VM "$vm"
    done
    echo "${green}[OK] $0 Script has finished successfully!${reset}"
    vagrant status
    
}

# Launches the Cloud VMs and the Router VM.
# Note: If they're already running, it does not tear them down.
# Input:
#   $1 Name of group of VMs.
launch_router_cloud(){

    echo "[INFO] Starting $1 VMs..."
    for vm in $ls_router $ls_cloud; do
        status=`vagrant status $vm --machine-readable | grep state, | cut -d, -f4`
        if [[ $status != "running" ]]; then
            launch_VM "$vm"
        else
            echo "[INFO] '$vm' is already running, no need to reload it."
        fi    
    done
    echo "${green}[OK] The Router and Cloud VMs are up and running!${reset}"
    
}

# Sets up the Cloud and Router VMs and creates the logs folder.
setup_cloud_and_logs(){
    
    create_logs
    launch_router_cloud "Router and Cloud Site"

}

# Sets up the specified site VMs.
# Note: it destroys them first if they're already up.
# Input:
#   $1 List of VMs to launch.
#   $2 Name of group of VMs.
#   $3 List of VMs to make sure are destroyed so that we don't crash my machine :(.
setup_VMs(){

    destroy_VMs "$1 $3" "Site A & B"
    launch_VMs "$1" "$2"

}

start_client_server(){
    
    servers=${ls_cloud[@]:10:${#ls_cloud}}
    clients="${ls_site_A[@]:10:${#ls_site_A}} ${ls_site_B[@]:10:${#ls_site_B}}"
    
    for vm in $servers $clients; do
        status=`vagrant status $vm --machine-readable | grep state, | cut -d, -f4`
        if [[ $status == "running" ]]; then
            # launch server.
            
            # the following works but doesnt produce output to terminal...
            #xterm -hold -e vagrant ssh server-s1 -t -c 'cd server_app && eval $(npm start)'&
            echo "[INFO] Starting '$vm' ssh session in a new terminal..."
            xterm -hold -e "vagrant ssh $vm"&
        fi  
    done    
    
}

start_router_monitoring(){

    echo "[INFO] Starting a new ssh session in Router to monitor network..."
    xterm -hold -e "vagrant ssh router -t -c 'sudo tcpdump -i enp0s8'"&

}

########## Main ##########

# Parse options
while getopts ":habcdsm " option; do

   case $option in

        h) # display Help
            Help
         exit;;
        
        a) # Site A - Router - Cloud Site.
            setup_cloud_and_logs
            setup_VMs "$ls_site_A" "Site A" "$ls_site_B"
         exit;;
        
        b) # Site B - Router - Cloud Site.
            setup_cloud_and_logs
            setup_VMs "$ls_site_B" "Site B" "$ls_site_A"
         exit;;

        c) # Destroy all Cloud Site VMs
            destroy_VMs "$ls_cloud" "Cloud Site"
         exit;;
         
        d) # Destroy all VMs
            destroy_VMs "$ls_site_A $ls_site_B $ls_cloud $ls_router" "All Sites"
         exit;;                  

        s) # Start client app and server app
            start_client_server
         exit;; 

        m) # Start Router monitoring
            start_router_monitoring
         exit;;
                 
        \?) # Incorrect option
            echo "${red}[ERROR] Invalid option${reset}"
            Help
         exit;;

   esac

done

# Print help if no options provided.
Help

########## End of file ##########
