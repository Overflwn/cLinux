cLinux:
- **NEW**: Re-Implement the IO Library in mkclinux instead of removing it
- ~~Finish filesystem wrapper~~ (?)
- ~~Finish perm lib~~ (?)
- ~~Bootchain Setup~~
- ~~Package library~~
- ~~Log library~~
- Process Management / Library
- Sandboxing for Processes
- ~~getops Library~~
- Don't run bash instantly, run /sbin/init first (-> seperates the "kernel" from being an actual OS and makes it more modular that way)
- _Create bash_
- Bash:
	- ~~Argument Parsing~~
	- Customization
	- Piping
	  (Override output and input from programs and redirect to target?)
- Create basic programs
- Create Installer
- _Create bootloader (loads CMX driver and boots up the hard drive)_

CMX:
- Optimize, clean documentation
- Hard Disk mounting (This is extremely hard for me to do, if it ever gets implemented, it'll be probably be *way* later on)
- File linking (Folder linking is already there)
- Optimized Space-Management
