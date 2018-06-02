Economist Fetcher
=================

The Economist's Android Mobile App shows ads, crashes a lot, and often forgets
what story I'm listening too. It's better to just use a regular music player
along with their ZIP file MP3 download. But logging in, downloading files,
unzipping by hand is tedious and time-consuming. This script makes it easier.

Use this tool to download the Economist Audio Edition and optionally sync to a
remote destination (i.e. your phone). Then you can use your favorite MP3 player
to listen to the Economist!

Configuration
-------------

You will need to create a dotfile called ~/.economist-fetcher-config. It should
look like this:

```
username=your.economist.login@your.email.provider.com
password=your.economist.online.password
destination=droid:/data/data/com.arachnoid.sshelper/home/SDCard/Music/
```

In the example above I am syncing to Android my phone which happens to be
running the SSHelper application. (NOTE: I only run SSHelper in order to use
this script, then I turn it off)

I also use an ~/.ssh/config file to setup a 'shortcut' to my phone as follows:

```
Host droid
	Hostname 192.168.1.16
	Port 2222
```
