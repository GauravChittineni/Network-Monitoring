#!/usr/bin/env bash

set -e

font="$HOME/Library/Fonts/digital-7 (mono).ttf"
output="$HOME/Downloads/caps"

sz="403,94,1061,1026"

timeout=2
fontFill="black"

# create a directory for the output images

mkdir -p ${output}

# loop
while [[ 1 ]];do
  date=$(date +%d\-%m\-%Y\_%H.%M.%S)
	file="/tmp/${date}.png"
	screencapture -t png -R${sz} -x ${file}
	
	# ou

	output="${output}/${date}.png"

	# Dimensions of the image
	measure=$(identify -format "%w %h" "$file")
	width=${measure%% *}
	height=${measure#* }

	# date stamp
	timestamp=$(stat -f "%Sm" ${file})

	# Decide the font size automatically
	if [[ ${width} -ge ${height} ]]
		then
		p_size=$(($width/30))
	else
		p_size=$(($height/30))
	fi

	# write the output to a file
	echo "Writing file: $output"
	convert "$file" -gravity SouthEast -font "$font" -pointsize ${p_size} -fill ${fontFill} -annotate +${p_size}+${p_size} "${timestamp}" "$output"

	rm ${file}

    # use intervals
	sleep ${timeout}
done

exit 0 
