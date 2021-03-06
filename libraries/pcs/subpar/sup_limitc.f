      SUBROUTINE SUBPAR_LIMITC ( NAMECODE, VALUE, ACCEPTED, STATUS )
*+
*  Name:
*     SUBPAR_LIMITC

*  Purpose:
*     Checks a value against a parameter's constraints.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SUBPAR_LIMITC ( NAMECODE, VALUE, ACCEPTED, STATUS )

*  Description:
*     The given value is checked against the declared constraints on the
*     indicated parameter, and the logical variable ACCEPTED set to
*     indicate whether the constraints are violated.

*  Arguments:
*     NAMECODE=INTEGER (given)
*        pointer to parameter
*     VALUE=CHARACTER*(*) (given)
*        value to be tested against the range or set constraints
*     ACCEPTED=LOGICAL (returned)
*        returned as .TRUE. unless the value violates any given
*        constraints
*     STATUS=INTEGER
*        Returned as SUBPAR__OUTRANGE if any constraint is violated.

*  Algorithm:
*     If there are no constraints on the parameter, ACCEPTED = .TRUE.
*     otherwise, if a range is specified check against the range, or
*     if a set is specified, compare with each value.

*  Copyright:
*     Copyright (C) 1984, 1988, 1991, 1993, 1994 Science & Engineering Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     BDK: B D Kelly (ROE)
*     AJC: A J Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     01-OCT-1984 (BDK):
*        Original
*     16-FEB-1988 (BDK):
*        make check case-insensitive
*     16-JUL-1991 (AJC):
*        Use CHR not STR$ for portability
*     26-JUL-1991 (AJC):
*        Report failures
*     24-SEP-1991 (AJC):
*        Prefix messages with 'SUBPAR:'
*     09-OCT-1991 (AJC):
*        Correctly use CHR_UCASE not CHR_UPPER
*        Use correct type/list in error message
*      1-MAR-1993 (AJC):
*        Add INCLUDE DAT_PAR
*     10-MAR-1993 (AJC):
*        Revise for MIN/MAX
*     31-OCT-1994 (AJC):
*        Set STATUS on 'one of a set' failure.
*        Improve error report
*      1-FEB-1994 (AJC):
*        Use SUBPAR_STRLEN
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global Constants:
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'SUBPAR_PAR'
      INCLUDE 'SUBPAR_ERR'

*  Arguments Given:
      INTEGER NAMECODE                   ! pointer to parameter
      CHARACTER*(*) VALUE                ! value to be tested against
                                         ! the range or set constraints

*  Arguments Returned:
      LOGICAL ACCEPTED                   ! .TRUE. unless the value
                                         ! violates any given
                                         ! constraints

*  Status:
      INTEGER STATUS

*  Global Variables:
      INCLUDE 'SUBPAR_CMN'

*  External References:
      INTEGER CHR_LEN                     ! used length of string

*  Local Variables:
      INTEGER J                           ! loop counter
      CHARACTER*(SUBPAR__STRLEN) UPVAL    ! uppercase copy of VALUE
      INTEGER LENVAL                      ! length of VALUE
*.
      IF ( STATUS .NE. SAI__OK ) RETURN

*   Find length of VALUE and take uppercase copy
      LENVAL = CHR_LEN ( VALUE )
      UPVAL = VALUE(1:LENVAL)
      CALL CHR_UCASE ( UPVAL(1:LENVAL) )

*   Initialise ACCEPTED flag
       ACCEPTED = .FALSE.

*   Check if there is a 'one of a set' constraint.
      IF (( PARLIMS(3,NAMECODE) .EQ. SUBPAR__CHAR ) .AND.
     :      .NOT. PARCONT(NAMECODE) ) THEN

*      There is - apply it
         DO J = PARLIMS(1,NAMECODE), PARLIMS(2,NAMECODE)
            IF ( UPVAL(1:LENVAL) .EQ. CHARLIST(J) ) THEN
               ACCEPTED = .TRUE.
            ENDIF
         ENDDO

*      If value was not in set, report problem
         IF ( .NOT. ACCEPTED ) THEN
            STATUS = SUBPAR__OUTRANGE
            CALL EMS_SETC ( 'NAME', PARKEY(NAMECODE) )
            CALL EMS_SETC ( 'VAL', UPVAL(1:LENVAL) )
            CALL EMS_REP ( 'SUP_LIMIT1', 'SUBPAR: '//
     :      'Value ''^VAL'' is not in the allowed set for ' //
     :      'parameter ^NAME.', STATUS )
            CALL EMS_SETC( 'VALS', '''' )
            CALL EMS_SETC( 'VALS', CHARLIST(PARLIMS(1,NAMECODE)) )
            CALL EMS_SETC( 'VALS', '''' )
            IF ( PARLIMS(2,NAMECODE) .GT. PARLIMS(1,NAMECODE) ) THEN
               DO J = PARLIMS(1,NAMECODE)+1, PARLIMS(2,NAMECODE)
                  CALL EMS_SETC( 'VALS', ', ''' )
                  CALL EMS_SETC( 'VALS', CHARLIST(J) )
               ENDDO
               CALL EMS_SETC( 'VALS', '''' )
            END IF
            CALL EMS_REP( 'SUP_LIMIT2', '  Allowed set is: ^VALS',
     :       STATUS )
         ENDIF

      ELSE
*      If there is a constraint, it is a range or MIN/MAX
         CALL SUBPAR_RANGEC( NAMECODE, UPVAL, .TRUE.,
     :                       ACCEPTED, STATUS )


      ENDIF

      IF ( STATUS .NE. SAI__OK ) THEN
         CALL EMS_SETC ( 'NAME', PARKEY(NAMECODE) )
         CALL EMS_REP( 'SUP_LIMIT3',
     :   'SUBPAR: Failed constraints check for parameter ^NAME',
     :    STATUS )
      END IF

      END
