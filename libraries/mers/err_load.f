      SUBROUTINE ERR_LOAD( PARAM, PARLEN, OPSTR, OPLEN, STATUS )
*+
*  Name:
*     ERR_LOAD

*  Purpose:
*     Return error messages from the current error context.

*  Language:
*    Starlink Fortran 77

*  Invocation:
*     ERR_LOAD( PARAM, PARLEN, OPSTR, OPLEN, STATUS )

*  Description:
*     On the first call of this routine, the error table for the current 
*     context is copied into a holding area, the current error context
*     is annulled and the first message in the holding area is returned.
*     Thereafter, each time the routine is called, the next message from 
*     the holding area is returned.
*
*     The status associated with the returned message is returned in STATUS
*     until there are no more messages to return -- then STATUS is set to
*     SAI__OK, PARAM and OPSTR are set to blanks and PARLEN and OPLEN to 1
*     If there are no messages pending on the first call, a warning message 
*     is returned with STATUS set to EMS__NOMSG.
*
*     After STATUS has been returned SAI__OK, the whole process is repeated
*     for subsequent calls.

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Returned)
*        The error message name.
*     PARLEN = INTEGER (Returned)
*        The length of the error message name.
*     OPSTR = CHARACTER * ( * ) (Returned)
*        The error message.
*     OPLEN = INTEGER (Returned)
*        The length of the error message.
*     STATUS = INTEGER (Given and Returned)
*        The status associated with the returned error message: 
*        it is set to SAI__OK when there are no more messages

*  Authors:
*     PCTR: P.C.T. Rees (STARLINK)
*     AJC: A.J. Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     28-NOV-1989 (PCTR):
*        Original version adapted from ERR_FLUSH and MSG_MLOAD.
*     15-DEC-1989 (PCTR):
*        Changed name to ERR_LOAD, and converted to call EMS_ELOAD.
*     26-SEP-1990 (PCTR):
*        Changed argument list to include the message name.
*     16-APR-1994 (AJC):
*        Revised comments for revised behaviouur
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE                     ! No implicit typing
 
*  Arguments Returned:
      CHARACTER * ( * ) PARAM

      INTEGER PARLEN

      CHARACTER * ( * ) OPSTR

      INTEGER OPLEN

*  Status:
      INTEGER STATUS

*.

*  Load the pending error messages at the current context.
      CALL EMS_ELOAD( PARAM, PARLEN, OPSTR, OPLEN, STATUS )

      END
