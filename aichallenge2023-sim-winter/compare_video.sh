#!/bin/bash
if [ $# -ne 2 ]; then
    echo "Usage: $0 left.mp4 right.mp4"
    exit 1
fi

LEFT_VIDEO=$1
RIGHT_VIDEO=$2

LEFT_START=`ffmpeg  -i $LEFT_VIDEO  -filter:v "select='gt(scene,0.5)',showinfo" -f null - |& perl -ne 'print /showinfo.*\sn:\s*0\s.*pts_time:\s*([\d\.]+)\s/'`
RIGHT_START=`ffmpeg -i $RIGHT_VIDEO -filter:v "select='gt(scene,0.5)',showinfo" -f null - |& perl -ne 'print /showinfo.*\sn:\s*0\s.*pts_time:\s*([\d\.]+)\s/'`

LEFT_VIDEO_TMP=`mktemp  -p . --suffix=.mp4`
RIGHT_VIDEO_TMP=`mktemp -p . --suffix=.mp4`

ffmpeg -y -i $LEFT_VIDEO  -ss $LEFT_START                        $LEFT_VIDEO_TMP
ffmpeg -y -i $RIGHT_VIDEO -ss $RIGHT_START -vf crop=960:1042:0:0 $RIGHT_VIDEO_TMP

ffmpeg -i $LEFT_VIDEO_TMP -i $RIGHT_VIDEO_TMP -filter_complex "overlay=x=960:y=0" -preset ultrafast merge.mp4

rm $LEFT_VIDEO_TMP
rm $RIGHT_VIDEO_TMP
