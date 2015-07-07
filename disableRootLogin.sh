#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Name:	disableRoot.sh
# Script Desc:	Add public key to authorized_keys file, disable root 
#				login, and add users to the sudoers file
# Script Date:	7-6-15
# Created By:	Christopher Stanley
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
startTime=$(date +%s)
date=$(date +"%m-%d-%Y")
timeNow=$(date +"%T")

user="cstanley@"
sshKey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBkd6l1oWStVyWjeoep2qhgBDGqpUZYYSmFn53LykPHiYpWPH9O1gLtCpsPtaBfU2u5TJgveGoTbQyqSvNrxhtjt3Qa5KR8NuVgKoegiZEuCAOlGKKokRwOciO0KYID+iOMi10eF7rwp43Rs5I0x6QcJmCGbbCIfRllYHK7CpYx9oqLc5isPMeQ/22UnlcXSNaHuOjhgIUtjVnoYW7HqjKl8d2rD4SUo52yt34jgMwvJJkmlOn0KWZN20MSXp8TZJlz//BkdCme5RI5/nKjr7oDn6xTt292gx5Kf5YSEbKcKjUIPtVitN3UX3mrwQbhcrJ9Fp5YVmaCvlbGLx3VWqT cstanley@eNkrypt"
hosts=`cat server.list`
users="cstanley cnbowman jhchand bmcdonal heileman sherrywh barrett"

for i in $hosts
do
        echo "---------- Connecting to $i ----------" >> disableRoot.log

        echo "[$(date +%D_%T)] Checking if SSH Key exists" >> disableRoot.log
        tmp=$(ssh -tt -q -o StrictHostKeyChecking=no -o ConnectTimeout=1 "$user""$i" "mkdir -p ~/.ssh; grep -r \"$sshKey\" ~/.ssh/authorized_keys")

        if [[ $tmp == *"No such file or directory"* || $tmp != *$sshKey* ]]; then 
        	 tmp=$(ssh -tt -q -o StrictHostKeyChecking=no -o ConnectTimeout=1 "$user""$i" "echo \"$sshKey\" >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh/; chmod 644 ~/.ssh/authorized_keys")
        	 echo "[$(date +%D_%T)] SSH Key added to authorized_keys" >> disableRoot.log
        else 
        	 echo "[$(date +%D_%T)] SSH Key already exists" >> disableRoot.log        	 
        fi

        echo "[$(date +%D_%T)] Adding users to the sudoers file" >> disableRoot.log
        tmp=$(ssh -tt -q -o StrictHostKeyChecking=no -o ConnectTimeout=1 "root@""$i" 'echo "dXNlcnM9ImNzdGFubGV5IGNuYm93bWFuIGpoY2hhbmQgYm1jZG9uYWwgaGVpbGVtYW4gc2hlcnJ5d2ggYmFycmV0dCIKZm9yIHUgaW4gJHVzZXJzOyBkbyBlY2hvICIkdSAgICBBTEw9Tk9QQVNTV0Q6ICAgICAgIEFMTCIgfCBzdWRvIHRlZSAtLWFwcGVuZCAgL2V0Yy9zdWRvZXJzID4gL2Rldi9udWxsOyBkb25lCg==" | base64 --decode | bash')
        echo "[$(date +%D_%T)] Finished adding users to the sudoers file" >> disableRoot.log

        echo "[$(date +%D_%T)] Changing PermitRootLogin to off" >> disableRoot.log
        tmp=$(ssh -tt -q -o StrictHostKeyChecking=no -o ConnectTimeout=1 "$user""$i" "sudo sed -i 's/^#PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config; sudo grep -r \"PermitRootLogin no\" /etc/ssh/sshd_config")

        echo "[$(date +%D_%T)] Verifying that PermitRootLogin is off" >> disableRoot.log
        if [[ $tmp = *"PermitRootLogin no"* ]]; then
                echo "[$(date +%D_%T)] PermitRootLogin is set to off" >> disableRoot.log
        else
                echo "[$(date +%D_%T)] Could not verify that PermitRootLogin is set to off" >> disableRoot.log
        fi

        echo "[$(date +%D_%T)] Restarting sshd" >> disableRoot.log
        tmp=$(ssh -tt -q -o StrictHostKeyChecking=no -o ConnectTimeout=1 "$user""$i" 'sudo service sshd restart')
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
