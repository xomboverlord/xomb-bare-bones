#!/bin/sh


render_usage()
{
	echo "USAGE: ./configure --target=[TARGET]"
	echo ""
	echo "TARGET - one of the following values: "
	for item in confs/*.conf;
	do
		echo "$item" | sed -e 's/confs\/\(.*\)\.conf/\1/';
	done
}

if [ $# -ne 1 ]
then
	render_usage
else
	FILE=confs/$1.conf
	echo "Targetting $1"
	cp $FILE dsss.conf
fi
