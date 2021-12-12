#!/bin/bash
echo "Started processing" 
if [  "$#" -ne 2 ]
then
echo "Username@domain Password"
exit 1
echo "Input good"
exit
fi

#Camera name, username, target ip address, password
processcamera() {
echo "Camera name:"$1
echo "User@domain:"$2
echo "Password":$3
username=$(echo $2  | cut -d@ -f1)
echo $username


#clear out diretory
sshpass -p $3 ssh $2 'rm /home/'$username'/alignments/'$1'/*'


sshpass -p $3 scp /home/$1/source/RMS/.config $2:/home/$username/alignments/$1/
sudo sshpass -p $3 scp -r /home/$1/.ssh $2:/home/$username/alignments/$1/
sshpass -p $3 scp /home/$1/source/RMS/platepar_cmn2010.cal $2:/home/$username/alignments/$1/
latestdirectory=$(ls /home/$1/RMS_data/CapturedFiles | tail  -n1)
echo "Latest directory is:"$latestdirectory
cd /home/$1/RMS_data/CapturedFiles/$latestdirectory


latestfile=$(ls *.fits | tail -n1)
echo "The latest file is: "$latestfile
sshpass -p $3 scp $latestfile $2:/home/$username/alignments/$1/

onehouragofile=$(ls *.fits | tail -n360 | head -n1)
echo "The onehouarago file is: "$onehouragofile
sshpass -p $3 scp $onehouragofile $2:/home/$username/alignments/$1/

twohouragofile=$(ls *.fits | tail -n720 | head -n1)
echo "The twohouarago file is: "$twohouragofile
sshpass -p $3 scp $twohouragofile $2:/home/$username/alignments/$1/



penultimatedirectory=$(ls /home/$1/RMS_data/CapturedFiles | tail -n2 | head -n1)
echo "Penultimate working directory is:"$penultimatedirectory
cd /home/$1/RMS_data/CapturedFiles/$penultimatedirectory
sshpass -p $3 scp *.jpg $2:/home/$username/alignments/$1/
sshpass -p $3 scp *.bmp $2:/home/$username/alignments/$1/
}

processcamera au000a $1 $2 
#processcamera au000c $1 $2
#processcamera au000d $1 $2
processcamera au000e $1 $2 
#processcamera au000f $1 $2 
processcamera au000g $1 $2 
processcamera au000h $1 $2 
