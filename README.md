# bash-tools

A collection of bash scripts for simplifying day-to-day OS management tasks including:
* File backup
  - bkp
* Organizing file management and directory navigation
  - csdir
  - goto
  - pslink
  - grab
  - place
  - day
  - big
* Capturing console session activity
  - tlog


  ## bkp
  For performing daily file and drectory backup and restore tasks

  ** *NOTE*: Please make sure to run the compatible version of bkp (BSD or GNU) according to the running platform.

  > ### Example
```console
mhega@ubuntu2404:~/tmp$ bkp -h

Manage backup/restore of current directory.

Usage: bkp [-l | -c | -r | -m] [--FORCE] [-R]

Options:
l               List all backup files of the current directory including their timestamps and checksums.
c               Compare contents of select backup with the current directory.
r               Restore contents of select backup into a subdirectory within the current directory.
m               Move old backup files (5 day-old or older) to a sub-directory (old_files).
--FORCE         Force backing up of the current directory irrespective of the disk usage.
R               Recursively archive all subdirectories.

                Run bkp command with only one of -l, -c, -r, -m options at a time.
                Running bkp command without any option, or with options -R and/or --FORCE will take a new backup.

Backup Target Directory: 
/home/mhega/bkp.d/home/mhega/tmp

mhega@ubuntu2404:~/tmp$
mhega@ubuntu2404:~/tmp$
mhega@ubuntu2404:~/tmp$
mhega@ubuntu2404:~/tmp$ ls -l
total 4
-rw-rw-r-- 1 mhega mhega 28 Oct 16 22:48 file_1
mhega@ubuntu2404:~/tmp$ 
mhega@ubuntu2404:~/tmp$ 
mhega@ubuntu2404:~/tmp$ 
mhega@ubuntu2404:~/tmp$ bkp

** TOTAL SIZE: 8 BYTES **

Current Directory: /home/mhega/tmp
Input a single-line backup description and/or hit NewLine to continue (CTRL-C to abort and exit): First Backup 
+ '[' 0 = 2 ']'
+ tee /home/mhega/bkp.d/home/mhega/tmp/tmp_2024-10-16_23.09.50.log
+ zip /home/mhega/bkp.d/home/mhega/tmp/tmp_2024-10-16_23.09.50.zip ./file_1
  adding: file_1 (deflated 18%)
Command output directed to:
/home/mhega/bkp.d/home/mhega/tmp/tmp_2024-10-16_23.09.50.log
mhega@ubuntu2404:~/tmp$ 
mhega@ubuntu2404:~/tmp$ 
mhega@ubuntu2404:~/tmp$ 
mhega@ubuntu2404:~/tmp$ bkp -c

Backup List Display
-------------------

  Backup ID   Timestamp            Checksum    Description
  ---------   ---------            --------    -----------
  1729120190  2024-10-16 23:10:03  1923602612  First Backup

Type the ID of the desired backup to compare or Q to quit: 1729120190

tmp_2024-10-16_23.09.50.zip will be compared with the current path..
Unless Backup is Recursive, Sub-directories may not undergo deep comparison.

  File Name  Timestamp (Current)  Timestamp (Archive)  
  ---------  -------------------  -------------------  
  file_1     2024-10-16 22:48     2024-10-16 22:48     

mhega@ubuntu2404:~/tmp$ 
mhega@ubuntu2404:~/tmp$ 
mhega@ubuntu2404:~/tmp$ 
mhega@ubuntu2404:~/tmp$ echo Update >> file_1 
mhega@ubuntu2404:~/tmp$ 
mhega@ubuntu2404:~/tmp$ 
mhega@ubuntu2404:~/tmp$ bkp -c

Backup List Display
-------------------

  Backup ID   Timestamp            Checksum    Description
  ---------   ---------            --------    -----------
  1729120190  2024-10-16 23:10:03  1923602612  First Backup

Type the ID of the desired backup to compare or Q to quit: 1729120190

tmp_2024-10-16_23.09.50.zip will be compared with the current path..
Unless Backup is Recursive, Sub-directories may not undergo deep comparison.

  File Name  Timestamp (Current)  Timestamp (Archive)  
  ---------  -------------------  -------------------  
  file_1     2024-10-16 23:10     2024-10-16 22:48     *

mhega@ubuntu2404:~/tmp$
mhega@ubuntu2404:~/tmp$
mhega@ubuntu2404:~/tmp$ 
mhega@ubuntu2404:~/tmp$ bkp -c

Backup List Display
-------------------

  Backup ID   Timestamp            Checksum    Description
  ---------   ---------            --------    -----------
  1729120190  2024-10-16 23:10:03  1923602612  First Backup

Type the ID of the desired backup to compare or Q to quit: 1729120190

tmp_2024-10-16_23.09.50.zip will be compared with the current path..
Unless Backup is Recursive, Sub-directories may not undergo deep comparison.

  File Name  Timestamp (Current)  Timestamp (Archive)  
  ---------  -------------------  -------------------  
  file_1     2024-10-16 23:10     2024-10-16 22:48     *
  file_2     2024-10-16 23:11                          *

mhega@ubuntu2404:~/tmp$
```
