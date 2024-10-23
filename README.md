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

## csdir
If you work on independent projects that require organizing your files into folders that are grouped by parent links, "csdir" can help quickly manage and access your folders.

While the naming of the options used in this script is suited to ticket creation model, the example below shows a more popular scenario - organzing files into folders representing study courses

```console
mhega@ubuntu2404:~$ 
mhega@ubuntu2404:~$ head -3 .sh/csdir.gnu.sh 
#! /bin/bash
dir="ALL"
base=/home/mhega/etc/Courses
mhega@ubuntu2404:~$ 
mhega@ubuntu2404:~$ 
mhega@ubuntu2404:~$ 
mhega@ubuntu2404:~$ sudo ln -s ~/.sh/csdir.gnu.sh /usr/local/bin/csdir
mhega@ubuntu2404:~$ 
mhega@ubuntu2404:~$ 
mhega@ubuntu2404:~$ 
mhega@ubuntu2404:~$ csdir 

List Of Recent 10 Cases
-----------------------

  Case ID  Site ID  Date Last Visited  Description  
  -------  -------  -----------------  -----------  

mhega@ubuntu2404:~$ csdir calculas -s Math
Creating /home/mhega/etc/Courses/ALL/CALCULAS
/home/mhega/etc/Courses/sites/MATH/ linked to case
Changing to /home/mhega/etc/Courses/ALL/CALCULAS in a subshell.

Hit [Ctrl]+[D] or type exit to exit this child shell.

A function named "home" with the following definition will be sourced so it can be used to quickly change to the current directory (CALCULAS).
To get back here, just type home.

A function named "descr" with the following definition will be sourced so it can be used to specify description of the curent case.

   home()
   {
	  echo "Going to $(basename $SCRWKDIR).."
	  cd $SCRWKDIR
   }
   descr()
   {
     	if [[ -z $SCRWKDIR ]]; then echo No case directory detected; return; fi
     	read -p "Input a single-line case description and/or hit NewLine to skip: " descr
     	if [ -n "$descr" ]; then
       		caseid=$(md5sum <(basename $SCRWKDIR) | cut -c 1-32)
       		descrvarname=DESCR_$caseid
       		declare $descrvarname="$descr"
       		echo $descrvarname:${!descrvarname} | sed 's/^\(\([^:]*\):\(.*\)\)$/\2:\3/g' >> $(dirname "$SCRWKDIR")/../case_meta.dat
     	fi
   }

(calculas) mhega@ubuntu2404:~/etc/Courses/ALL/CALCULAS$ 
(calculas) mhega@ubuntu2404:~/etc/Courses/ALL/CALCULAS$ 
(calculas) mhega@ubuntu2404:~/etc/Courses/ALL/CALCULAS$ descr
Input a single-line case description and/or hit NewLine to skip: Differentials and Integrals
(calculas) mhega@ubuntu2404:~/etc/Courses/ALL/CALCULAS$ 
(calculas) mhega@ubuntu2404:~/etc/Courses/ALL/CALCULAS$ 
(calculas) mhega@ubuntu2404:~/etc/Courses/ALL/CALCULAS$ csdir .

  Case ID   Site ID  Date Last Visited    Description                  
  -------   -------  -----------------    -----------                  
  CALCULAS  MATH     2024-10-23 00:33:56  Differentials and Integrals  

(calculas) mhega@ubuntu2404:~/etc/Courses/ALL/CALCULAS$ exit
exit
mhega@ubuntu2404:~$ 
mhega@ubuntu2404:~$ 
mhega@ubuntu2404:~$ 
mhega@ubuntu2404:~$ csdir -s math

List Of All Cases For Site MATH
-------------------------------

  Case ID   Date Linked          Description                  
  -------   -----------          -----------                  
  CALCULAS  2024-10-23 00:33:56  Differentials and Integrals  

mhega@ubuntu2404:~$
mhega@ubuntu2404:~$ csdir algebra -s Math
Creating /home/mhega/etc/Courses/ALL/ALGEBRA
/home/mhega/etc/Courses/sites/MATH/ linked to case
Changing to /home/mhega/etc/Courses/ALL/ALGEBRA in a subshell.

Hit [Ctrl]+[D] or type exit to exit this child shell.

A function named "home" with the following definition will be sourced so it can be used to quickly change to the current directory (ALGEBRA).
To get back here, just type home.

A function named "descr" with the following definition will be sourced so it can be used to specify description of the curent case.

   home()
   {
	  echo "Going to $(basename $SCRWKDIR).."
	  cd $SCRWKDIR
   }
   descr()
   {
     	if [[ -z $SCRWKDIR ]]; then echo No case directory detected; return; fi
     	read -p "Input a single-line case description and/or hit NewLine to skip: " descr
     	if [ -n "$descr" ]; then
       		caseid=$(md5sum <(basename $SCRWKDIR) | cut -c 1-32)
       		descrvarname=DESCR_$caseid
       		declare $descrvarname="$descr"
       		echo $descrvarname:${!descrvarname} | sed 's/^\(\([^:]*\):\(.*\)\)$/\2:\3/g' >> $(dirname "$SCRWKDIR")/../case_meta.dat
     	fi
   }

(algebra) mhega@ubuntu2404:~/etc/Courses/ALL/ALGEBRA$ 
(algebra) mhega@ubuntu2404:~/etc/Courses/ALL/ALGEBRA$ 
(algebra) mhega@ubuntu2404:~/etc/Courses/ALL/ALGEBRA$ 
(algebra) mhega@ubuntu2404:~/etc/Courses/ALL/ALGEBRA$ exit
exit
mhega@ubuntu2404:~$
mhega@ubuntu2404:~$ csdir -s math -i
Input a single-line site description and/or hit NewLine to skip: Mathematics for 9th Grade
mhega@ubuntu2404:~$ 
mhega@ubuntu2404:~$ 
mhega@ubuntu2404:~$ csdir -s math

Site Description: Mathematics for 9th Grade

List Of All Cases For Site MATH
-------------------------------

  Case ID   Date Linked          Description                  
  -------   -----------          -----------                  
  ALGEBRA   2024-10-23 00:38:43                               
  CALCULAS  2024-10-23 00:33:56  Differentials and Integrals  

mhega@ubuntu2404:~$
mhega@ubuntu2404:~$ csdir algebra
Changing to /home/mhega/etc/Courses/ALL/ALGEBRA in a subshell.

Hit [Ctrl]+[D] or type exit to exit this child shell.

A function named "home" with the following definition will be sourced so it can be used to quickly change to the current directory (ALGEBRA).
To get back here, just type home.

A function named "descr" with the following definition will be sourced so it can be used to specify description of the curent case.

   home()
   {
	  echo "Going to $(basename $SCRWKDIR).."
	  cd $SCRWKDIR
   }
   descr()
   {
     	if [[ -z $SCRWKDIR ]]; then echo No case directory detected; return; fi
     	read -p "Input a single-line case description and/or hit NewLine to skip: " descr
     	if [ -n "$descr" ]; then
       		caseid=$(md5sum <(basename $SCRWKDIR) | cut -c 1-32)
       		descrvarname=DESCR_$caseid
       		declare $descrvarname="$descr"
       		echo $descrvarname:${!descrvarname} | sed 's/^\(\([^:]*\):\(.*\)\)$/\2:\3/g' >> $(dirname "$SCRWKDIR")/../case_meta.dat
     	fi
   }

(algebra) mhega@ubuntu2404:~/etc/Courses/ALL/ALGEBRA$ 
(algebra) mhega@ubuntu2404:~/etc/Courses/ALL/ALGEBRA$ 
(algebra) mhega@ubuntu2404:~/etc/Courses/ALL/ALGEBRA$
```

