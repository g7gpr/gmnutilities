#!/bin/bash
echo "Started processing" $1 $2
latestdirectory=$(ls /home/pi/RMS_data/CapturedFiles/ | tail -n$1 | head -n1)
the_date=$(ls /home/pi/RMS_data/CapturedFiles/ | tail -n$1 | head -n1 | cut -d "_" -f 2)
touch "/home/pi/scripts/"$the_date"_exportrunning"
rm "/home/pi/scripts/"$the_date"_exportcompleted"
echo "AU000A has started preparing the compilation video for " $the_date "." | mail -s "AU000A - Started compilation" g7gpr@outlook.com
echo "Observation date was :" $the_date
echo "Latest directory for working is  :"  $latestdirectory
cd /home/pi/RMS_data/CapturedFiles/$latestdirectory
echo "Working in:" /home/pi/RMS_data/CapturedFiles/$latestdirectory
echo "Generating Timelapse"
python3 /home/pi/source/RMS/Utils/GenerateTimelapse.py /home/pi/RMS_data/CapturedFiles/$latestdirectory
sshpass -p $2 scp $latestdirectory.mp4 gmn@192.168.1.230:/home/gmn/Dropbox/AU000A/archives
echo "Handle light pollution"
ffmpeg -i $latestdirectory.mp4 -vf "curves=all='0/0 0.5/0.1 0.7/0.9 1/1'" -codec:a copy -codec:v libx264 -y AU000A_latest.mp4
sshpass -p $2 scp AU000A_latest.mp4 gmn@192.168.1.230:/home/gmn/Dropbox/AU000A
echo "Make compilation of activity"
rm /home/pi/RMS_data/CapturedFiles/$latestdirectory/detections.mp4
python -m Utils.GenerateMP4s /home/pi/RMS_data/CapturedFiles/$latestdirectory
ls FF*.mp4 > input.txt
sed -i -e 's/^/file /' input.txt
sshpass -p $2 scp input.txt gmn@192.168.1.230:/home/gmn/Dropbox/AU000A/archives
ffmpeg -f concat -safe 0 -i /home/pi/RMS_data/CapturedFiles/$latestdirectory/input.txt -c copy /home/pi/RMS_data/CapturedFiles/$latestdirectory/detections.mp4
cp detections.mp4 "AU000A_"$the_date"_detections.mp4"
sshpass -p $2 scp "AU000A_"$the_date"_detections.mp4" gmn@192.168.1.230:/home/gmn/Dropbox/AU000A/archives
echo "Assemble"
ffmpeg -i /home/pi/RMS_data/CapturedFiles/$latestdirectory/AU000A_latest.mp4 -i  /home/pi/RMS_data/CapturedFiles/$latestdirectory/detections.mp4 -filter_complex "[0:v:0][1:v:0] concat=n=2:v=1[outv]" -map "[outv]" /home/pi/RMS_data/CapturedFiles/$latestdirectory/AU000A_combined.mp4
rm /home/pi/RMS_data/CapturedFiles/$latestdirectory/AU000A_latest.mp4
rm /home/pi/RMS_data/CapturedFiles/$latestdirectory/detections.mp4
rm /home/pi/RMS_data/CapturedFiles/$latestdirectory/FF*.mp4
rm "/home/pi/RMS_data/CapturedFiles/$latestdirectory/AU000A_"$the_date"_detections.mp4"
echo "Make upload"
cp "/home/pi/RMS_data/CapturedFiles/"$latestdirectory"/AU000A_combined.mp4" "/home/pi/RMS_data/CapturedFiles/"$latestdirectory"/AU000A_"$the_date"_combined.mp4"
sshpass -p $2 scp /home/pi/RMS_data/CapturedFiles/$latestdirectory/AU000A_combined.mp4 gmn@192.168.1.230:/home/gmn/Dropbox/AU000A
rm /home/pi/RMS_data/CapturedFiles/$latestdirectory/AU000A_combined.mp4
sshpass -p $2 scp "/home/pi/RMS_data/CapturedFiles/"$latestdirectory"/AU000A_"$the_date"_combined.mp4" gmn@192.168.1.230:/home/gmn/Dropbox/AU000A/archives
echo "The latest observation from AU000A has been uploaded to the server." | mail -s "AU000A - latest observation uploaded" g7gpr@outlook.com 
rm "/home/pi/RMS_data/CapturedFiles/$latestdirectory/AU000A_"$the_date"_combined.mp4"
touch "/home/pi/scripts/"$the_date"_exportcompleted"
rm "/home/pi/scripts/"$the_date"_exportrunning"
