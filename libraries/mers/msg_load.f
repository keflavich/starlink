      SUBROUTINE MSG_LOAD( PARAM, TEXT, OPSTR, OPLEN, STATUS )
*+
*  Name:
*     MSG_LOAD

*  Purpose:
*     Expand and return a message.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL MSG_LOAD( PARAM, TEXT, OPSTR, OPLEN, STATUS )

*  Description:
*     Any tokens in the supplied message are expanded and the result is
*     returned in the character variable supplied. If the status
*     argument is not set to SAI__OK on entry, no action is taken
*     except that the values of any existing message tokens are always
*     left undefined after a call to MSG_LOAD. If the expanded message 
*     is longer than the length of the supplied character variable, 
*     the message is terminated with an ellipsis.

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The message name.
*     TEXT = CHARACTER * ( * ) (Given)
*        The raw message text.
*     OPSTR = CHARACTER * ( * ) (Returned)
*        The expanded message text.
*     OPLEN = INTEGER (Returned)
*        The length of the expanded message.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Algorithm:
*     -  Use MSG1_FORM to construct the output message text.

*  Authors:
*     JRG: Jack Giddings (UCL)
*     BDK: Dennis Kelly (ROE)
*     AJC: Alan Chipperfield (STARLINK)
*     PCTR: P.C.T. Rees (STARLINK)
*     {enter_new_authors_here}

*  History:
*     3-JAN-1983 (JRG):
*        Original version.
*     12-NOV-1984 (BDK):
*        Remove call to error system and change name of output routine.
*     2-NOV-1988 (AJC):
*        Remove INCLUDE 'MSG_ERR'.
*     28-NOV-1989 (PCTR):
*        MSG_MLOAD adapted from MSG_OUT.
*     15-DEC-1989 (PCTR):
*        Changed name to MSG_LOAD, and converted to use EMS_ calls.
*     3-JUN-1991 (PCTR):
*        Changed to annul the token table regardless of given
*        status value.
*     9-NOV-1995 (AJC):
*        Remove use of local buffer and hence length restiction.
*        Rely on lower levels for ellipsis.
*     12-NOV-1998 (AJC):
*        Remove unused variables
*     15-SEP-1999 (AJC):
*        Add CLEAN argument to call MSG1_FORM
*     22-FEB-2001 (AJC):
*        Use MSG1_KTOK not EMS1_KTOK
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE                     ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'                 ! Standard SAE constants
      INCLUDE 'MSG_PAR'                 ! MSG_ public constants

*  Global Variables:
      INCLUDE 'MSG_CMN'                 ! MSG_ global constants
 
*  Arguments Given:
      CHARACTER * ( * ) PARAM
      CHARACTER * ( * ) TEXT

*  Arguments Returned:
      CHARACTER * ( * ) OPSTR
      INTEGER OPLEN
 
*  Status:
      INTEGER STATUS

*  External Variables:
      EXTERNAL MSG1_BLK          ! Force inclusion of block data

*  Local Variables: 
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) THEN

*     Status is not SAI__OK, so just annul the token table.
         CALL MSG1_KTOK

      ELSE
*     Status is SAI__OK, so form the returned message string.
*     This will also annul the token table.
         CALL MSG1_FORM(
     :      PARAM, TEXT, .NOT.MSGSTM, OPSTR, OPLEN, STATUS )

      END IF

      END
