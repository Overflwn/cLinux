## cLinux, a more secure, feature rich and linux-like OS than CraftOS.

# Small Information

1. Replaces CraftOS, using rednet TLCO
2. Uses a multi-user system
3. Modified FS API (Forbid normal users from editing in critical folders)
4. Load (in a kinda custom format) libraries and put them in _G
5. 2 hardcoded levels of threadmanagers
  * first: TLCO level, reloads rednet (but doesn't start it) and start /vit/alive and /boot/load --> isolated, user has no control over it
  * second: shell.lua / Service level, reads /etc/services.conf and starts every enabled service listed in there (and of course the core service, which is basically the parent window (it is more complicated than that))
  * (third): The user-available threadmanager (/sys/thread.l)
6. CommandLine
  * background processes: run at the same time as the commandline, meaning that sleep() doesn't affect it
  * foreground processes: commandline is paused until the foreground process finishes
  * view and kill processes: 
    * "ps" to view a list with UIDs and names
	* "kill <uid>" to kill a process (you can't kill nmbr 1, which is the commandline itself
  * easy service managing:
    * enable <path or name of service inside /etc/services.d>: enables a file or service at boot
    * disable <path or name of service inside /etc/services.d>: self explaining
    * start <path>: starts a file in service level
    * stop <path>: stops a running service
    * core <path or name of service>: start a service as core at boot (sets the old core to disabled)
7. edited version of packman:
  * default installation path is /bin/ (--> every file in /bin/ may be started without entering the full path)
  * no extern API (to prevent bugs I had)
  * removed the original repository (to prevent updating packman to the original version)
  * custom repolist (located in my pastebin account)
  * custom repos (for example cLinux has edit, luaide and doorX in it's repo)
8. Doesn't have to use the commandline:
  * You can write your own DE and let it start as core service
  * I made my own DE (ported from doorOS3.0), but you need to expand the standard available space for computers (more in the forum post)
  * You can even start a program as core service (for example useful for servers)
9. To enable rednet:
```
service enable rednet
```
10. (To temporarely start rednet)
```
service start /etc/pacman.d/rednet
```

#More Information in the [forum post](http://www.computercraft.info/forums2/index.php?/topic/27573-clinux-optional-desktop-enviroment-bye-craftos-kappa/).