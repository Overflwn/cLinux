# cLinux - An OS for ComputerCraft (Rewrite #2)

This is just a project I make for fun and when I feel like it, don't even expect it to work properly.

If you want to know what's already implemented, what's being worked on and what's still left to do, look at the TODO.md file.

Cheers,
Piorjade

## How to test this shit

First, make sure that there are these folders (maybe with files already included) in the cLinux folder:
```
bin
boot
home
etc
	etc/perm.conf.d
sys
	sys/log
lib
	lib/core
usr
	usr/lib
	usr/bin
```
This is just to make sure that the program does _not_ crash at some point just because it couldn't find a folder which it expected to be already there.


Copy all of it to the root of your (CC) computer and execute mkclinux.lua, that should be it.

## How to contribute, if you care about it that much

Well, the main OS is located in the cLinux folder, which gets "converted" into a CMX hard disk everytime you execute mkclinux.lua, soooo you just have to mind everything in there.

If you want to fix some stuff in the CMX filesystem, the driver is located in "fs_drivers/cmx" (with the wrapperbeing customfs_manager.lua).

## Some unrelated stuff, you probably don't want to see this

My Twitter: [Click Here](https://www.twitter.com/piorjadelp)

My Discord: Piorjade#6412

My Steam: [Click Here](https://www.steamcommunity.com/id/piorjade)

My Steemit (It's a cool new social media platform based on a blockchain, check it out if you don't hate blockchains by now): [Click Here](https://www.steemit.com/@piorjade)
