      SUBROUTINE CVG_HDATE( DATE, STATUS )
*+
*  Name:
*     CVG_HDATE

*  Purpose:
*     Converts the NDF history date into a more-pleasing format

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CVG_HDATE( DATE, STATUS )

*  Description:
*     This makes a few minor modifications to the date string obtained
*     from NDF history records to make it more like UNIX and
*     astronomical style.  Specifically two hyphens around the month are
*     replaced by spaces, and the second and third letters of the month
*     are made lowercase.

*  Arguments:
*     DATE = CHARACTER * ( * ) (Given and Returned)
*        On input the NDF format for a date and time, namely
*        YYYY-MMM-DD HH:MM:SS.SSS.  On exit, the ISO-order format for a
*        date and time, namely YYYY Mmm DD HH:MM:SS.SSS
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1997 Central Laboratory of the Research Councils.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
*     02110-1301, USA.

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David S Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     1997 January 13 (MJC):
*        Original version rebadged from KPG1_FHDAT.
*     19-NOV-2013 (DSB):
*        Moved from CONVERT to CVG.
*     {enter_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF_ constants

*  Arguments Given and Returned:
      CHARACTER * ( * ) DATE

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER * ( NDF__SZHDT ) DUMMY ! Work variable for building the
                                 ! output string
      CHARACTER * ( 2 ) ONTH     ! Work variable for converting the
                                 ! month's second and third characters
                                 ! to lowercase

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Converted the month to mixed case.
      ONTH = DATE( 7:8 )
      CALL CHR_LCASE( ONTH )

*  Form the output string and copy back into the supplied argument.
      DUMMY = DATE( 1:4 )//' '//DATE( 6:6 )//ONTH//' '//DATE( 10: )
      DATE = DUMMY

      END
