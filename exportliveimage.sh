#!/bin/bash
echo "Started processing" $1
if [  "$#" -ne 0 ]
then
echo "Dodgy input detected"
exit 1
echo "Dodgy input not detected"
exit
fi

the_time=$(date +"%Y%m%d%H%M%S")
FILE=/home/david/live/.daytime
if test -f "$FILE"; then
#Day
#pick a file at random from a directory and copy it to the live folder

ls /home/david/live/au000a |sort -R |tail -n1 |while read file; do
echo $file
/usr/local/bin/aws s3 cp --region ap-southeast-2 /home/david/live/au000a/$file  s3://povg-web-prod-livefiles/au000a.jpg &
done

ls /home/david/live/au000e |sort -R |tail -n1 |while read file; do
echo $file
/usr/local/bin/aws s3 cp --region ap-southeast-2 /home/david/live/au000e/$file  s3://povg-web-prod-livefiles/au000e.jpg &
done

ls /home/david/live/au000g |sort -R |tail -n1 |while read file; do
echo $file
/usr/local/bin/aws s3 cp --region ap-southeast-2 /home/david/live/au000g/$file  s3://povg-web-prod-livefiles/au000g.jpg &
done


ls /home/david/live/au000h |sort -R |tail -n1 |while read file; do
echo $file
/usr/local/bin/aws s3 cp --region ap-southeast-2 /home/david/live/au000h/$file  s3://povg-web-prod-livefiles/au000h.jpg &

rm /home/david/live/au000h/tmp/* 
cp /home/david/live/au000h/$file /home/david/live/au000h/tmp/

#astrometry code goes in here
cd /home/david/live/au000h/tmp
solve-field /home/david/live/au000h/tmp/*.jpg --scale-units arcsecperpix  --scale-low 50 --scale-high 100 --overwrite
ls *ngc.png
mv *ngc.png output
echo "Removing from tmp"
rm *
cd output
echo "Before Mogrify"
ls
mogrify -format jpg *.png
echo "After mogrify"
ls
rm *.png
echo "Remove all pngs"
ls
mv *.jpg au000h_annotated.jpg
echo "After rename"
ls
/usr/local/bin/aws s3 cp --region ap-southeast-2   --cache-control no-cache /home/david/live/au000h/tmp/output/au000h_annotated.jpg  s3://povg-web-prod-livefiles/au000h_annotated.jpg
echo "Removing from output"
rm *
done


else
#Night

echo "Night"
cp /home/au000a/RMS_data/live.jpg /home/david/live/au000a/"au000a_"$the_time"_live.jpg"
cp /home/au000e/RMS_data/live.jpg /home/david/live/au000e/"au000e_"$the_time"_live.jpg"
cp /home/au000g/RMS_data/live.jpg /home/david/live/au000g/"au000g_"$the_time"_live.jpg"
cp /home/au000h/RMS_data/live.jpg /home/david/live/au000h/"au000h_"$the_time"_live.jpg"


#/usr/local/bin/aws s3 rm  s3://povg-web-prod-livefiles/au000a2.jpg
/usr/local/bin/aws s3 cp  --cache-control no-cache /home/au000a/RMS_data/live.jpg  s3://povg-web-prod-livefiles/au000a.jpg

#/usr/local/bin/aws s3 rm  s3://povg-web-prod-livefiles/au000e2.jpg
/usr/local/bin/aws s3 cp  --cache-control no-cache /home/au000e/RMS_data/live.jpg  s3://povg-web-prod-livefiles/au000e.jpg

#/usr/local/bin/aws s3 rm  s3://povg-web-prod-livefiles/au000g2.jpg
/usr/local/bin/aws s3 cp  --cache-control no-cache /home/au000g/RMS_data/live.jpg  s3://povg-web-prod-livefiles/au000g.jpg

#/usr/local/bin/aws s3 rm  s3://povg-web-prod-livefiles/au000h2.jpg
/usr/local/bin/aws s3 cp  --cache-control no-cache /home/au000h/RMS_data/live.jpg  s3://povg-web-prod-livefiles/au000h.jpg

rm /home/david/live/au000h/tmp/*
cp /home/au000h/RMS_data/live.jpg /home/david/live/au000h/tmp/


cd /home/david/live/au000h/tmp
solve-field /home/david/live/au000h/tmp/*.jpg --scale-units arcsecperpix  --scale-low 50 --scale-high 100 --overwrite
ls *ngc.png
mv *ngc.png output
echo "Removing from tmp"
rm *
cd output
echo "Before Mogrify"
ls
mogrify -format jpg *.png
echo "After mogrify"
ls
rm *.png
echo "Remove all pngs"
ls
mv *.jpg au000h_annotated.jpg
echo "After rename"
ls
echo "Doing upload to S3"
/usr/local/bin/aws s3 cp --region ap-southeast-2  --cache-control no-cache /home/david/live/au000h/tmp/output/au000h_annotated.jpg  s3://povg-web-prod-livefiles/au000h_annotated.jpg
echo "Removing from output"
rm *


fi





