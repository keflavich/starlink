      SUBROUTINE KPG1_PGCLS( PNAME, SAVCUR, STATUS )
*+
*  Name:
*     KPG1_PGCLS

*  Purpose:
*     Close down the AGI database and PGPLOT workstation.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_PGCLS( PNAME, SAVCUR, STATUS )

*  Description:
*     This routine closes the graphics data base and PGPLOT workstation
*     previously opened by KPG1_PGOPN.

*  Arguments:
*     PNAME = CHARACTER * ( * ) (Given)
*        The name of the parameter to use.
*     SAVCUR = LOGICAL (Given)
*        If .TRUE., then the current AGI picture is retained as the
*        current picture. If .FALSE., the picture which was current when
*        the database was opened is re-instated.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - This routine attempts to execute even if an error has already
*     occurred (but the pallette will not be saved if an error has
*     already occurred).

*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils.
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
*     02111-1307, USA.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1-OCT-1999 (DSB):
*        Original version.
*     9-FEB-2006 (DSB):
*        Restructure using a second AGI context in order to ensure the
*        identifier returned by the call to AGI_ASSOC in the matching call
*        to KPG1_PGOPN is annulled, thus allowing the database to be closed.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      CHARACTER PNAME*(*)
      LOGICAL SAVCUR

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER IPIC               ! AGI picture identifier
      INTEGER ISTAT              ! Inherited status

*.

*  Now save the initial status value and set a new value for this routine.
      ISTAT = STATUS
      STATUS = SAI__OK

      IPIC = 0

*  Create a new error context.
      CALL ERR_MARK

*  Deactivate PGPLOT and close the workstation.
      CALL AGP_DEACT( STATUS )

*  Close the current AGI context. If required, reinstate the input current
*  picture.  Otherwise, retain the current picture.
      IF( .NOT. SAVCUR ) THEN
         CALL AGI_END( -1, STATUS )
      ELSE
         CALL AGI_ICURP( IPIC, STATUS )
         CALL AGI_END( IPIC, STATUS )
      END IF

*  Check the status is good so that we can be sure that any bad status
*  after the following call to AGI_ICURP was generated by AGI_ICURP.
      IF( STATUS .EQ. SAI__OK ) THEN

*  The previous AGI_END call will not have annulled the identifier
*  returned by the call to AGI_ASSOC in the corresponding call to
*  KPG1_PGOPN, since that call to AGI_ASSOC is outside the scope of
*  AGI context which has just been ended. We now close the outer-most AGI
*  context in order to annul this final identifier. This time, we rettain
*  the current picture. First get an identifier for the current picture.
         CALL AGI_ICURP( IPIC, STATUS )

*  If there is no current picture left (i.e. if the database is empty), we
*  annull the error reported by AGI_ICURP above, and set IPIC to -1 (this
*  will stop AGI_END from reporting an error.
         IF( STATUS .NE. SAI__OK ) THEN
            CALL ERR_ANNUL( STATUS )
            IPIC = -1
         END IF
      END IF

*  End the final AGI context. This will annul both the identifier
*  returned by the corresponding call to AGI_ASSOC (in KPG1_PGOPN)
*  and the IPIC identifier returned by the above call to AGI_ICURP.
      CALL AGI_END( IPIC, STATUS )

*  Cancel the parameter association if there has been an error.
      IF ( STATUS .NE. SAI__OK .OR. ISTAT .NE. SAI__OK ) THEN
         CALL AGI_CANCL( PNAME, STATUS )
      END IF

*  If the initial status was bad, then ignore all internal errors.
      IF ( ISTAT .NE. SAI__OK ) THEN
         CALL ERR_ANNUL( STATUS )
         STATUS = ISTAT
      END IF

*  Release the current error context.
      CALL ERR_RLSE

      END
