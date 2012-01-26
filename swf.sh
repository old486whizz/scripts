#! /bin/bash

find . -name "*flv" | while read file
do
	avidemux2_cli --load "$file" --save-raw-audio ${file}.mp3
done
