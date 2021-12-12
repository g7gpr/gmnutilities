#!/bin/bash
#$1 How many folders back to go
#$2 Obsolete 
#$3 account name
#$4 camera name
#$5 windows share username
#$6 windows share password

echo "Started processing" $1 $2 $3 $4 $5 $6
if [  "$#" -ne 6 ]
then
echo "Dodgy input detected"
exit 1
echo "Dodgy input not detected"
exit
fi
rm /home/$3/RMS_data/CapturedFiles/*

source /home/$3/vRMS/bin/activate

#-f webm -vcodec libvpx-vp9 -vb 1024k


latestdirectory=$(ls /home/$3/RMS_data/CapturedFiles/ | tail -n$1 | head -n1)
the_date=$(ls /home/$3/RMS_data/CapturedFiles/ | tail -n$1 | head -n1 | cut -d "_" -f 2)

smbclient --socket-options='TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE SO_RCVBUF=131072 SO_SNDBUF=131072' "//192.168.0.210/GMNData$" $6 -U $5 << SMBCLIENTCOMMANDS
 mkdir $3_exportrunning_$the_date
SMBCLIENTCOMMANDS

echo "Create export running marker file"
touch "/home/"$3"/scripts/"$the_date"_exportrunning"
echo "Remove export completed marker file"
rm "/home/"$3"/scripts/"$the_date"_exportcompleted"
echo $3 "has started preparing the compilation video for " $the_date "." | mail -s $4" - Started compilation" g7gpr@outlook.com
echo "Observation date was :" $the_date
echo "Latest directory for working is  :"  $latestdirectory
cd /home/$3/RMS_data/CapturedFiles/$latestdirectory
rm -rf temp_img_dir
echo "Working in:" /home/$3/RMS_data/CapturedFiles/$latestdirectory
echo "Generating Timelapse"
python3 /home/$3/source/RMS/Utils/GenerateTimelapse.py /home/$3/RMS_data/CapturedFiles/$latestdirectory > /dev/null

echo "SMB client uploading :" $latestdirectory.mp4
smbclient --socket-options='TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE SO_RCVBUF=131072 SO_SNDBUF=131072' "//192.168.0.210/GMNData$" $6 -U $5 << SMBCLIENTCOMMANDS
 cd $4
 put flat.bmp
 mput *.jpg
 cd archives
 put $latestdirectory.mp4
SMBCLIENTCOMMANDS

echo "Handle light pollution"
#ffmpeg -i $latestdirectory.mp4 -vf "curves=all='0/0 0.5/0.1 0.7/0.9 1/1'" -codec:a copy -codec:v libx264 -y $4_latest.mp4 > /dev/null
#ffmpeg -i $latestdirectory.mp4 -vf "curves=all='0/0 0.5/0.1 0.7/0.9 1/1'" -f webm -vcodec libvpx-vp9 -vb 1024k -y $4_latest.mp4 > /dev/null
ffmpeg -i $latestdirectory.mp4  -vcodec h264 -acodec aac -strict -2 $4_latest.mp4 > /dev/null
sshpass -p $2 scp $4_latest.mp4 gmn@192.168.1.230:/home/gmn/Dropbox/$4

echo "SMB client uploading : "$4"_latest.mp4"
smbclient --socket-options='TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE SO_RCVBUF=131072 SO_SNDBUF=131072' "//192.168.0.210/GMNData$" $6 -U $5 << SMBCLIENTCOMMANDS
 cd $4
 put $4_latest.mp4
SMBCLIENTCOMMANDS

#aws update
/usr/local/bin/aws s3 cp $4_latest.mp4  s3://povg-web-prod-livefiles/$4_latest.mp4

echo "Make compilation of activity"

rm /home/$3/RMS_data/CapturedFiles/$latestdirectory/detections.mp4
python -m Utils.GenerateMP4s /home/$3/RMS_data/CapturedFiles/$latestdirectory > /dev/null

ffcount=$(ls FF*.mp4 | wc -l)
echo "Detection count is " $ffcount

mkdir $the_date
sshpass -p $2 scp -r $the_date gmn@192.168.1.230:/home/gmn/Dropbox/$4/archives/
rmdir $the_date

if [[ $ffcount -ne 0 ]]; then
echo "Compiling all the individual detections"
ls FF*.mp4 > /home/$3/RMS_data/CapturedFiles/$latestdirectory/input.txt
sed -i -e 's/^/file /' /home/$3/RMS_data/CapturedFiles/$latestdirectory/input.txt
echo "Concatenating all the detections"
ffmpeg -f concat -safe 0 -i /home/$3/RMS_data/CapturedFiles/$latestdirectory/input.txt -c copy /home/$3/RMS_data/CapturedFiles/$latestdirectory/detections.mp4 > /dev/null
cp detections.mp4 $4"_"$the_date"_detections.mp4"
sshpass -p $2 scp $4"_"$the_date"_detections.mp4" gmn@192.168.1.230:/home/gmn/Dropbox/$4/archives/$the_date/
echo "Uploading "$4"_"$the_date"_detections.mp4 and the mp4 files of all the individual detections"
smbclient --socket-options='TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE SO_RCVBUF=131072 SO_SNDBUF=131072' "//192.168.0.210/GMNData$" $6 -U $5 << SMBCLIENTCOMMANDS
cd $4
cd archives
mkdir $the_date
cd $the_date
put $4"_"$the_date"_detections.mp4"
prompt
mput FF*.mp4
SMBCLIENTCOMMANDS

sshpass -p $2 scp $4"_"$the_date"_detections.mp4" gmn@192.168.1.230:/home/gmn/Dropbox/$4/archives/$the_date
sshpass -p $2 scp input.txt gmn@192.168.1.230:/home/gmn/Dropbox/$4/archives/$the_date/
sshpass -p $2 scp FF*.mp4 gmn@192.168.1.230:/home/gmn/Dropbox/$4/archives/$the_date/
sshpass -p $2 scp $latestdirectory.mp4 gmn@192.168.1.230:/home/gmn/Dropbox/$4/archives/$the_date/
sshpass -p $2 scp flat.bmp             gmn@192.168.1.230:/home/gmn/Dropbox/$4/archives/$the_date/
sshpass -p $2 scp *.jpg                gmn@192.168.1.230:/home/gmn/Dropbox/$4/archives/$the_date/


rm "/home/"$3"/RMS_data/CapturedFiles/$latestdirectory/"$4"_"$the_date"_detections.mp4"
rm /home/$3/RMS_data/CapturedFiles/$latestdirectory/FF*.mp4
echo "Make "$4"_combined out of "$4"_latest.mp4 and detections.mp4 "
ffmpeg -i /home/$3/RMS_data/CapturedFiles/$latestdirectory/$4_latest.mp4 -i  /home/$3/RMS_data/CapturedFiles/$latestdirectory/detections.mp4 -filter_complex "[0:v:0][1:v:0] concat=n=2:v=1[outv]" -map "[outv]"  -vcodec h264 -acodec aac -strict -2  /home/$3/RMS_data/CapturedFiles/$latestdirectory/$4_combined.mp4
rm /home/$3/RMS_data/CapturedFiles/$latestdirectory/detections.mp4
else
echo "Handling no detections condition"
cp $4_latest.mp4 $4_combined.mp4
fi


rm /home/$3/RMS_data/CapturedFiles/$latestdirectory/$4_latest.mp4


echo "Make upload"
cp "/home/"$3"/RMS_data/CapturedFiles/"$latestdirectory"/"$4"_combined.mp4" "/home/"$3"/RMS_data/CapturedFiles/"$latestdirectory"/"$4"_"$the_date"_combined.mp4"
sshpass -p $2 scp /home/$3/RMS_data/CapturedFiles/$latestdirectory/$4_combined.mp4 gmn@192.168.1.230:/home/gmn/Dropbox/$4


echo "SMB Client uploading "$4"_combined.mp4"
smbclient --socket-options='TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE SO_RCVBUF=131072 SO_SNDBUF=131072' "//192.168.0.210/GMNData$" $6 -U $5 << SMBCLIENTCOMMANDS
cd $4
put $4_combined.mp4 
SMBCLIENTCOMMANDS

/usr/local/bin/aws s3 cp $4_combined.mp4  s3://povg-web-prod-livefiles/$4_combined.mp4

rm /home/$3/RMS_data/CapturedFiles/$latestdirectory/$4_combined.mp4
sshpass -p $2 scp "/home/"$3"/RMS_data/CapturedFiles/"$latestdirectory"/"$4"_"$the_date"_combined.mp4" gmn@192.168.1.230:/home/gmn/Dropbox/$4/archives/$the_date/

echo "SMB Client uploading "$4"_"$the_date"_combined.mp4"
smbclient --socket-options='TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE SO_RCVBUF=131072 SO_SNDBUF=131072' "//192.168.0.210/GMNData$" $6 -U $5 << SMBCLIENTCOMMANDS
cd $4
cd archives
cd $the_date
put $4"_"$the_date"_combined.mp4"
SMBCLIENTCOMMANDS



echo "SMB Client removing export runing flag"
smbclient --socket-options='TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE SO_RCVBUF=131072 SO_SNDBUF=131072' "//192.168.0.210/GMNData$" $6 -U $5 << SMBCLIENTCOMMANDS
rmdir $3_exportrunning_$the_date
SMBCLIENTCOMMANDS

echo "The latest observation from "$3" has been uploaded to the server." | mail -s $4" - latest observation uploaded" g7gpr@outlook.com 
rm "/home/$3/scripts/"$the_date"_exportrunning"
echo "Complete"
