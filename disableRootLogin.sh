#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Name:	disableRoot.sh
# Script Desc:	Add public key to authorized_keys file, disable root 
#	              login, and add users to the sudoers file
# Script Date:	7-6-15
# Created By:	Christopher Stanley
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
startTime=$(date +%s)
date=$(date +"%m-%d-%Y")
timeNow=$(date +"%T")

sshKey="YOUR_SSH_PUBLIC_KEY"
hosts=`cat server.list`
users="user1 user2 user3"

for i in $hosts
do
  echo "---------- Connecting to $i ----------" >> disableRoot.log

  echo "[$(date +%D_%T)] Checking if SSH Key exists" >> disableRoot.log
  tmp=$(ssh -tt -q -o StrictHostKeyChecking=no -o ConnectTimeout=1 $i "mkdir -p ~/.ssh; grep -r \"$sshKey\" ~/.ssh/authorized_keys")

  if [[ $tmp == *"No such file or directory"* || $tmp != *$sshKey* ]]; then 
   tmp=$(ssh -tt -q -o StrictHostKeyChecking=no -o ConnectTimeout=1 $i "echo \"$sshKey\" >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh/; chmod 644 ~/.ssh/authorized_keys")
   echo "[$(date +%D_%T)] SSH Key added to authorized_keys" >> disableRoot.log
  else 
   echo "[$(date +%D_%T)] SSH Key already exists" >> disableRoot.log        	 
  fi

  echo "[$(date +%D_%T)] Changing PermitRootLogin to off" >> disableRoot.log
  tmp=$(ssh -tt -q -o StrictHostKeyChecking=no -o ConnectTimeout=1 $i "sudo sed -i 's/^#PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config; sudo grep -r \"PermitRootLogin no\" /etc/ssh/sshd_config")

  echo "[$(date +%D_%T)] Verifying that PermitRootLogin is off" >> disableRoot.log
  if [[ $tmp = "PermitRootLogin no" ]]; then
    echo "[$(date +%D_%T)] PermitRootLogin is set to off" >> disableRoot.log
  else
    echo "[$(date +%D_%T)] Could not verify that PermitRootLogin is set to off" >> disableRoot.log
  fi

  echo "[$(date +%D_%T)] Restarting sshd" >> disableRoot.log
  tmp=$(ssh -tt -q -o StrictHostKeyChecking=no -o ConnectTimeout=1 $i 'sudo service sshd restart')

  echo "[$(date +%D_%T)] Adding users to the sudoers file" >> disableRoot.log
  tmp=$(ssh -tt -q -o StrictHostKeyChecking=no -o ConnectTimeout=1 $i 'echo "dXNlcnM9ImNzdGFubGV5IGNuYm93bWFuIGpoY2hhbmQgYm1jZG9uYWwgaGVpbGVtYW4gc2hlcnJ5d2ggYmFycmV0dCIKZm9yIHUgaW4gJHVzZXJzOyBkbyBlY2hvICIkdSAgICBBTEw9Tk9QQVNTV0Q6ICAgICAgIEFMTCIgfCBzdWRvIHRlZSAtLWFwcGVuZCAgL2V0Yy9zdWRvZXJzID4gL2Rldi9udWxsOyBkb25lCg==" | base64 --decode | bash')
  echo "[$(date +%D_%T)] Finished adding users to the sudoers file" >> disableRoot.log
done

endTime=$(date +%s)
seconds=$(echo "$endTime - $startTime" | bc)
minutes=$(echo "($endTime - $startTime) / 60" | bc)

if [ "$minutes" -le "0" ]; then
  echo "Time Taken: $seconds seconds"
else
  echo "Time Taken: $minutes minute(s)"
fi

echo "[$(date +%D_%T)] Job Finished." >> disableRoot.log
