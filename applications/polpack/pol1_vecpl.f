      SUBROUTINE POL1_VECPL( NVEC, X, Y, VECMAG, VECORN, ANGFAC,
     :                       ANGROT, DSCALE, AHSIZE, JUST, STATUS )
*+
*  Name:
*     POL1_VECPL

*  Purpose:
*     Plots a vector map.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL POL1_VECPL( NVEC, X, Y, VECMAG, VECORN, ANGFAC,
*                      ANGROT, DSCALE, AHSIZE, JUST, STATUS )

*  Description:
*     The supplied vectors are plotted.

*  Arguments:
*     NVEC = INTEGER (Given)
*        Number of vectors to be plotted.
*     X( NVEC ) = DOUBLE PRECISION (Given)
*        The X coordinate at each vector, in the current PGPLOT window.
*     Y( NVEC ) = DOUBLE PRECISION (Given)
*        The Y coordinate at each vector, in the current PGPLOT window.
*     VECMAG( NVEC ) = REAL (Given)
*        The data values defining the vector magnitudes.
*     VECORN( NVEC ) = REAL (Given)
*        The data values defining the vector orientations.  Positive
*        values correspond to rotation in the same sense as from the x
*        axis to the y axis.  Zero corresponds to the x axis.  The
*        units are defined by argument ANGFAC.
*     ANGFAC = REAL (Given)
*        The factor which converts values from VECORN into units of
*        radians.
*     ANGROT = REAL (Given)
*        A value (in radians) to be added on to the vector orientation
*        angles given by VECORN.
*     DSCALE = REAL (Given)
*        A factor which converts data values in VECMAG into
*        corresponding vector lengths in centimetres.
*     AHSIZE = REAL (Given)
*        The length of each stroke of the arrowhead placed at the end
*        of the vector, in pixels.  A value of zero causes no arrowhead
*        to be drawn and the vectors to be centred on the corresponding
*        pixel centres.  Otherwise, the vectors start at the centre of
*        the corresponding pixel.
*     JUST = CHARACTER * ( * ) (Given)
*        This can be 'CENTRE', 'START' or 'END'.  'CENTRE' causes
*        vectors to be drawn centred on the corresponding pixel.
*        'START' causes vectors to be drawn starting at the
*        corresponding pixel.  'END' causes vectors to be drawn ending
*        at the corresponding pixel.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     24-FEB-1998 (DSB):
*        Original version.

*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! VAL_ constants
      INCLUDE 'MSG_PAR'          ! MSG_ constants

*  Arguments Given:
      INTEGER NVEC
      DOUBLE PRECISION X( NVEC )
      DOUBLE PRECISION Y( NVEC )
      REAL VECMAG( NVEC )
      REAL VECORN( NVEC )
      REAL ANGFAC
      REAL ANGROT
      REAL DSCALE
      REAL AHSIZE
      CHARACTER * ( * ) JUST

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      REAL PIBY2                 ! 90 degrees in radians
      PARAMETER ( PIBY2 = 1.5707963268 )

*  Local Variables:
      INTEGER I                  ! Vector index
      INTEGER NPLOT              ! No. of vectors plotted
      REAL VECANG                ! Vector position angle in radians
      REAL VECLEN                ! Vector length in pixels
      
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the count of plotted vectors.
      NPLOT = 0

*  Loop round each vector.
      DO I = 1, NVEC

*  Skip over bad data values.
         IF ( VECMAG( I ) .NE. VAL__BADR .AND. 
     :        VECORN( I ) .NE. VAL__BADR .AND.
     :        X( I ) .NE. VAL__BADD .AND.
     :        Y( I ) .NE. VAL__BADD ) THEN

*  Calculate the length of the vector in units of pixels.
            VECLEN = VECMAG( I ) / DSCALE

*  Calculate the vector orientation, in radians. Within KPG1_VECT, the
*  vector orientations are measured from the Y axis, but the supplied
*  VECORN values are measured from the X axis. So subtract 90 degrees
*  from the supplied value to make zero equivalent to the Y axis.
            VECANG = ANGFAC * VECORN( I ) + ANGROT - PIBY2

*  Plot the vector.      
            CALL KPG1_VECT( REAL( X( I ) ), REAL( Y( I ) ), JUST, 
     :                      VECLEN, VECANG, AHSIZE, STATUS )

*  Abort if an error has occurred.
            IF ( STATUS .NE. SAI__OK ) GO TO 999

*  Increment the count of plotted vectors.
            NPLOT = NPLOT + 1

         END IF

      END DO

*  If no vectors have been plotted, warn the user.
      CALL MSG_BLANK( STATUS )

      IF ( NPLOT .EQ. 0 ) THEN
         CALL MSG_OUT( 'POL1_VECPL_NOPLT', '  No vectors plotted '//
     :                 'due to lack of good data in input.', STATUS )
         CALL MSG_BLANK( STATUS )

*  Otherwise, tell the user how many vectors were plotted unless at
*  silent reporting.
      ELSE
         CALL MSG_SETI( 'NP', NPLOT )
         CALL MSG_OUTIF( MSG__NORM, 'POL1_VECPL_NPLT',
     :                   '  ^NP vectors plotted.', STATUS )
         CALL MSG_OUTIF( MSG__NORM, 'BLANK', ' ', STATUS )

      END IF      


*  Arrive here if an error occurs.
 999  CONTINUE

      END
