#!/bin/bash

existingRole=$1
newRole=$2

if [[ $# -lt 2 ]]; then
  echo "The script assigns a new role to all users/groups currently having"
  echo "a certain existing-role."
  echo 
  echo "Usage: $0 <existing-role> <new-role>"
  exit 1
fi

for a in $(openstack role assignment list --role $existingRole -f json | jq -c '.[]'); do
  PROJECT=$(echo $a | jq -r '.["Project"]')
  INHERIT=$(echo $a | jq -r '.["Inherited"]')

  if [[ -z $PROJECT ]]; then
    echo "Skipping this one as Project is missing..."
    echo $a
    continue
  fi

  command="--project $PROJECT"

  USER=$(echo $a | jq -r '.["User"]')
  if [[ ! -z $USER ]]; then
    command+=" --user $USER"
  fi
  
  GROUP=$(echo $a | jq -r '.["Group"]')
  if [[ ! -z $GROUP ]]; then
    command+=" --group $GROUP"
  fi

  if [[ $INHERIT == 'true' ]]; then
    command+=" --inherited"
  fi

  # If the user/group currentlu are missing the role; add it..
  if [[ -z $(openstack role assignment list --role $newRole $command) ]] ; then
    echo "Missing $newRole in $command"
    openstack role add $command $newRole
  fi
done
