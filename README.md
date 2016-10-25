## cLinux, a more secure, feature rich and linux-like OS than CraftOS.

# Rewrite (once again)

1. Fix critical bug, where the user was able to simply access the old FS API
  * don't put the table 'old' to _G, find another way to let the new FS API access it
  * save perm.l and fs.l somewhere else, so that the user cannot delete it without rootaccess
  * let the system crash without perm.l and fs.l
2. Fix bugs with windows
  * Current bug: (example: fsExpose file manager) The cursor doesn't position correctly when using a program, which creates mutliple windows (--> fsExpose's address bar reads at 1,1, (not the address bar) drawing on the whole screen
3. Fix bugs with the thread.l
  * Current bug: thread manager resumes tasks successfully, but os.pullEvent somehow returns every event (with filter on), leading to programs crashing on false input
  * Need to completely rewrite the thread manager
4. Fix the commandline / shell.lua:
  * Commandline's cursor doesn't really position correctly after input or running a program, has to do with thread.l
  * Current solution was resetting the cursor manually all the time, which leads to lag when changing current directory
5. Estimated needed time for release:
  * Unknown, development speed will probably be incredibly slow and sometimes I may upload big chunks of code in just a day and then pause again....
