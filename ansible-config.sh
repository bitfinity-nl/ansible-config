#!/bin/bash

#
# - run this script as an ansible user.
clear

echo "---------------------------------"
echo "- Ansible Configuration Manager -"
echo "---------------------------------"
echo
echo "example:"
echo "  - install ansible server: sudo ./ansible-conf.sh install-ansible-server"
echo "  - remove  ansible server: sudo ./ansible-conf.sh remove-ansible-server"
echo
echo "  - add node for ansible (runas ansible user): ./ansible-config.sh add-ansible-node <node> <account> <password>"
echo


ARGUMENT1=$1  # ARGUMENT1: Module to load
ARGUMENT2=$2  # ARGUMENT2: IP Address or Hostname of the node
ARGUMENT3=$3  # ARGUMENT3: Local Admin Account
ARGUMENT4=$4  # ARGUMENT4: Local Admin Password


function install-ansible-server() {

  # Clear screen
  clear

  echo "---------------------------"
  echo "- Install Ansible server  -"
  echo "---------------------------"

  # ---
  echo "[INFO] Ansible | 1.1.0 Title: Continue script if logged in as root."
  strUSR_ANS=root
  if [ $strUSR_ANS = $(whoami) ]
  then
    echo "[INFO] Ansible | 1.1.1 Awnser: Current user is $strUSR_ANS."
  else
    echo "[INFO] Ansible | 1.1.2 Awnser: Current user is not $strUSR_ANS. please login as $strUSR_ANS."
    exit
  fi
  # ---

  # ---
  echo "[INFO] Ansible | 1.2.0 Title: Generate privatekey for user ansible server."
  strFILE_RSA=~/.ssh/id_rsa
  if [ ! -f $strFILE_RSA ]
  then
    echo "[INFO] Ansible | 1.2.1 Awnser: File $strFILE_RSA does not exist."
    sudo ssh-keygen -t rsa -f $strFILE_RSA -b 4096 -q -P ""
  else
    echo "[INFO] Ansible | 1.2.1 Awnser: File $strFILE_RSA exist."
    #exit
  fi
  # ---

  # ---
  echo "[INFO] Ansible | 1.3.0 Title: Add repository and install Ansible"
  # update database
  sudo updatedb

  # locate ansible ppa
  strFILE_PPA=$(locate *-ansible-*.list)
  if [ -z $strFILE_PPA ]
  then
    echo "[INFO] Ansible | 1.3.1 Awnser: Repository ppa:ansible:/ansible does not exist."
    echo "[INFO] Ansible | 1.3.2 Awnser: Adding repository ppa:ansible:/ansible."
    sudo apt-add-repository ppa:ansible/ansible
    sudo apt-get update
    sudo apt-get install -y ansible
  else
    echo "[INFO] Ansible | 1.3.1 Awnser: Repository $strFILE_PPA exist."
    #exit
  fi
  # ---

  # ---
  echo "[INFO] Ansible | 1.4.0 Title: Create Ansible production environment"
  str_ANS_PROD=/opt/ansible-prod
  if [ ! -d "$str_ANS_PROD" ]
  then
    echo "[INFO] Ansible | 1.4.1 Awnser: Directory $str_ANS_PROD does not exist."
    echo "[INFO] Ansible | 1.4.2 Awnser: Copy /etc/ansible to $str_ANS_PROD"
    sudo cp -r /etc/ansible $str_ANS_PROD
    sudo mkdir -p $str_ANS_PROD/group_vars
  else
    echo "[INFO] Ansible | 1.4.1 Awnser: Directory $str_ANS_PROD exist."
  fi

  # ---
  echo "[INFO] Ansible | 1.5.0 Title: Create Ansible test environment"
  str_ANS_TEST=/opt/ansible-test
  if [ ! -d "$str_ANS_TEST" ]
  then
    echo "[INFO] Ansible | 1.5.1 Awnser: Directory $str_ANS_TEST does not exist."
    echo "[INFO] Ansible | 1.5.2 Awnser: Copy /etc/ansible to $str_ANS_TEST"
    sudo cp -r /etc/ansible $str_ANS_TEST
    sudo mkdir -p $str_ANS_TEST/group_vars
  else
    echo "[INFO] Ansible | 1.5.1 Awnser: Directory $str_ANS_TEST exist."
  fi
  # ---
}

function remove-ansible-server () {

    echo "---------------------------"
    echo "- Remove Ansible server   -"
    echo "---------------------------"

    echo "[INFO] Ansible | 1.4.0 Title: Remove Ansible test environment"
    str_ANS_TEST=/opt/ansible-test
    rm -R $str_ANS_TEST

    echo "[INFO] Ansible | 1.5.0 Title: Remove Ansible production environment"
    str_ANS_PROD=/opt/ansible-prod
    rm -R $str_ANS_PROD

    echo "[INFO] Ansible | 1.3.0 Title: Remove Ansible and repository"
    apt-get autoremove -y ansible

    strFILE_PPA=$(locate *-ansible-*.list)
    add-apt-repository ppa:ansible/ansible --remove
    rm -R $strFILE_PPA

}

function add-ansible-node () {

  # Variable(s)
  # Ansible Node settings
  ANS_NOD=$ARGUMENT2
  ANS_USR=ansible
  ANS_PWD=TempPassw0rd1

  # Local Administrative Account
  LOC_ADM=$ARGUMENT3
  LOC_PWD=$ARGUMENT4

  # Clear screen
  clear

  echo "--------------------"
  echo "- Add Ansible node -"
  echo "--------------------"

  # ---
  echo "[INFO] Ansible | 1.0.0 Title: Display given arguments."
  echo "[INFO] Ansible | 1.0.1 Awnser: Ansible node is $ANS_NOD"
  echo "[INFO] Ansible | 1.0.2 Awnser: Local Admin Account is $LOC_ADM"
  echo "[INFO] Ansible | 1.0.3 Awnser: Local Admin Password is ......."
  # ---

  # ---
  echo "[INFO] Ansible | 1.1.0 Title: Continue script if logged in as ansible."
  strUSR_ANS=ansible
  if [ $strUSR_ANS = $(whoami) ]
  then
    echo "[INFO] Ansible | 1.1.1 Awnser: Current user is $strUSR_ANS."
  else
    echo "[INFO] Ansible | 1.1.2 Awnser: Current user is not $strUSR_ANS. please login as $strUSR_ANS."
    exit
  fi
  # ---


  echo "[INFO] Ansible | 1.1.0 Title: Generate ans-user.sh to $ANS_NOD:/home/$LOC_ADM"
  sshpass -p "$LOC_PWD" ssh $LOC_ADM@$ANS_NOD '
  echo "#!/bin/bash
  adduser --home /home/'$ANS_USR' --shell /bin/bash --ingroup \
  sudo --disabled-password --gecos '"''"' '$ANS_USR'

  echo '$ANS_USR:$ANS_PWD' | chpasswd

  echo "ansible ALL=NOPASSWD: ALL" > /etc/sudoers.d/'$ANS_USR'
  " > ans-user.sh'

  echo "[INFO] Ansible | 1.2.0 Title: Make ans-user.sh executable"
  sshpass -p "$LOC_PWD" ssh $LOC_ADM@$ANS_NOD 'chmod +x ans-user.sh'

  echo "[INFO] Ansible | 1.3.0 Title: Execute ans-user.sh"
  sshpass -p "$LOC_PWD" ssh $LOC_ADM@$ANS_NOD 'echo '$LOC_PWD'| \
  sudo -S ./ans-user.sh'

  echo "[INFO] Ansible | 1.4.0 Title: chmod 0440 /etc/sudoers.d/'$ANS_USR'"
  sshpass -p "$LOC_PWD" ssh $LOC_ADM@$ANS_NOD 'echo '$LOC_PWD'| \
  sudo -S chmod 0440 /etc/sudoers.d/'$ANS_USR''

  echo "[INFO] Ansible | 1.5.0 Title: Remove ans-user.sh"
  sshpass -p "$LOC_PWD" ssh $LOC_ADM@$ANS_NOD 'rm -rf ans-user.sh'

  echo "[INFO] Ansible | 1.6.0 Title: Transfer public key"
  sshpass -p "$ANS_PWD" ssh-copy-id $ANS_USR@$ANS_NOD

  echo "[INFO] Ansible | 1.7.0 Title: Remove and disble password login"
  sshpass -p "$LOC_PWD" ssh $LOC_ADM@$ANS_NOD 'echo '$LOC_PWD'| \
  sudo -S passwd -dl '$ANS_USR''

  echo "[INFO] Ansible | 1.8.1 Title: Configure UFW for Ansible"
  sudo ufw allow ssh
  sudo ufw enable

}


# Call Function
$ARGUMENT1 $ARGUMENT2 $ARGUMENT3 $ARGUMENT4
