*+SYS_DOCOMMAND	Execute system command (DCL C-SHELL etc.)
	SUBROUTINE SYS_DOCOMMAND(COMMAND,ISTAT)
	CHARACTER*(*) COMMAND
	INTEGER ISTAT
*COMMAND	input	command text
*ISTAT		in/out	returns status, 0 is OK
* SUNOS version
*-Author Dick Willingale 1991-Aug-8
	INTEGER SYSTEM
C
	IF(ISTAT.NE.0) RETURN
C
	ISTAT=SYSTEM(COMMAND)
	END
