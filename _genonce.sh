#!/bin/bash
function isOnline ()
{
   curl -sSf tx.fhir.org > /dev/null
   if [ $? -ne 0 ]; then
      curl -sSf tx.fhir.org/r4 > /dev/null
   fi
   return $?
}
publisher_jar=publisher.jar
input_cache_path=./input-cache/
echo Checking internet connection...
#curl -sSf tx.fhir.org > /dev/null
isOnline

if [ $? -eq 0 ]; then
	echo "Online"
	txoption=""
else
	echo "Offline"
	txoption="-tx n/a"
fi

echo "$txoption"

publisher=$input_cache_path/$publisher_jar
if test -f "$publisher"; then
	java -jar $publisher -ig . $txoption $*

else
	publisher=../$publisher_jar
	if test -f "$publisher"; then
		java -jar $publisher -ig . $txoption $*
	else
		echo IG Publisher NOT FOUND in input-cache or parent folder.  Please run _updatePublisher.  Aborting...
	fi
fi
