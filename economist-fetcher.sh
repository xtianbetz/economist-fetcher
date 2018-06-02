#!/bin/bash
#
# Economist Audio Edition Downloader
#
# Copyright (c) 2018 Christian Betz (christian.betz@gmail.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

if [ -z "$ECONOMIST_FETCHER_CONFIG_FILE" ] ; then
	ECONOMIST_FETCHER_CONFIG_FILE="$HOME/.economist-fetcher-config"
fi

if [ ! -e "$ECONOMIST_FETCHER_CONFIG_FILE" ] ; then
	echo "ERROR: you must set the username and password variables in $ECONOMIST_FETCHER_CONFIG_FILE"
	exit
fi

echo "Loading $ECONOMIST_FETCHER_CONFIG_FILE"
. $ECONOMIST_FETCHER_CONFIG_FILE

if [ -z "$username" -o -z "$password" ] ; then
		echo "ERROR: you must set the username and password variables in $ECONOMIST_FETCHER_CONFIG_FILE"
		exit
fi

rm -rf /tmp/economist.cookie

echo "Fetching inititial login form..."
form_build_id=`curl http://www.economist.com/user/login?destination=audio-edition | grep form_build_id | head -1 | awk -F\" '{print $6}'`

echo "Form build id is $form_build_id"

echo "Logging into economist.com..."
curl -L -d "name=$username&pass=$password&form_build_id=$form_build_id&persistent_login=1&form_id=user_login&securelogin_original_baseurl=http://www.economist.com&op=Log in" \
-A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31" \
-H "Origin: http://www.economist.com" \
-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
-H "Accept-Charset:ISO-8859-1,utf-8;q=0.7,*;q=0.3" \
-H "Accept-Encoding:gzip,deflate,sdch" \
-H "Accept-Language:en-US,en;q=0.8" \
--referer "http://www.economist.com/user/login?destination=audio-edition" \
-c /tmp/economist.cookie -D /tmp/economist.login.headers \
"http://www.economist.com/user/login?destination=audio-edition"

echo
echo "Fetching location of latest issue..."

curl -L \
--referer "http://www.economist.com/audio-edition" \
-A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31" \
-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
-H "Accept-Charset:ISO-8859-1,utf-8;q=0.7,*;q=0.3" \
-H "Accept-Encoding:gzip,deflate,sdch" \
-H "Accept-Language:en-US,en;q=0.8" \
-b /tmp/economist.cookie -D /tmp/economist.latest.headers \
http://www.economist.com/audio-edition/latest

LATEST=`grep "Location: " /tmp/economist.latest.headers | sed -e 's/\r//g' | awk '{print $2}'`
echo "Downloading latest table of contents @ [$LATEST]"

curl -L \
--referer "http://www.economist.com/audio-edition" \
-A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31" \
-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
-H "Accept-Charset:ISO-8859-1,utf-8;q=0.7,*;q=0.3" \
-H "Accept-Encoding:gzip,deflate,sdch" \
-H "Accept-Language:en-US,en;q=0.8" \
-H "If-Modified-Since:Sun, 07 Apr 2013 22:01:21 +0000" \
-b /tmp/economist.cookie -D /tmp/economist.latestpage.headers \
$LATEST > /tmp/economist.latestpage.html.gz

echo "Extracting gzipped page table of contents..."
gunzip -f /tmp/economist.latestpage.html.gz

# In case they the stopped gzipping it again
# mv /tmp/economist.latestpage.html.gz /tmp/economist.latestpage.html

if [ $? -ne 0 ] ; then
	echo "Failed to gunzip file: /tmp/economist.latestpage.html.gz"
	exit 1
fi

echo "Extracting zip file url from page html..."
ZIPURL=`grep The_Economist_Full_edition /tmp/economist.latestpage.html | awk -F\" '{print $4}' | sed -e 's/amp;//g'`

if [ -z "$ZIPURL" ] ; then
	echo "ERROR: empty ZIPURL. Check /tmp/economist.latestpage.html"
	exit
fi

echo "Downloading final zip @ $ZIPURL..."

curl -L \
--referer "$LATEST" \
-A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31" \
-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
-H "Accept-Charset:ISO-8859-1,utf-8;q=0.7,*;q=0.3" \
-H "Accept-Encoding:gzip,deflate,sdch" \
-H "Accept-Language:en-US,en;q=0.8" \
-b /tmp/economist.cookie -D /tmp/economist.zipdownload.headers \
"$ZIPURL" > /tmp/economist.latest.zip

if [ "$?" -ne 0 ] ; then
	echo "Download failed!\n";
	exit 1
fi

echo

cd /tmp
DIR=economist-$(date -I)

if [ -d $DIR ] ; then
	rm -rf $DIR
fi

mkdir $DIR
cd $DIR

echo "Extracting in /tmp/$DIR..."
unzip /tmp/economist.latest.zip

if [ ! -z "$destination" ] ; then
	echo "Rsyncing to $destination..."
	cd /tmp
	rsync -vr $DIR $destination
fi
