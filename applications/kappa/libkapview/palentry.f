      SUBROUTINE PALENTRY( STATUS )
*+
*  Name:
*     PALENTRY

*  Purpose:
*     Enters a colour into an image display's palette.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL PALENTRY( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application obtains a colour and enters it into the palette
*     portion of the current image display's colour table.  The palette
*     comprises up to 16 colours and is intended to provide coloured
*     annotations, borders, axes, graphs etc. that are unaffected by
*     changes to the lookup table used for images.

*     A colour is specified either by the giving the red, green, blue
*     intensities; or named colours.

*  Usage:
*     palentry palnum colour [device]

*  ADAM Parameters:
*     COLOUR() = LITERAL (Read)
*        A colour to be added to the palette at the entry given by
*        parameter PALNUM.  It is either:

*          o  A named colour from the standard colour set, which may
*          be abbreviated.  If the abbreviated name is ambiguous the
*          first match (in alphabetical order) is selected.  The case
*          of the name is ignored.  Some examples are "Pink", "Yellow",
*          "Aquamarine", and "Orchid".
*
*          o  Normalised red, green, and blue intensities separated by
*          commas or spaces.  Each value must lie in the range 0.0--1.0.
*          For example, "0.7,0.7,1.0" would give a pale blue.
*     DEVICE = DEVICE (Read)
*        Name of the image display to be used.  The device must be in
*        one of the following GNS categories: IMAGE_DISPLAY,
*        IMAGE_OVERLAY, WINDOW, WINDOW_OVERLAY, or MATRIX_PRINTER and
*        have at least 2 colour indices.  [Current image-display device]
*     PALNUM = _INTEGER (Read)
*        The number of the palette entry whose colour is to be
*        modified.  PALNUM must lie in the range zero to the minimum
*        of 15 or the number of colour indices minus one.  The
*        suggested default is 1.

*  Examples:
*     palentry 5 gold
*        This makes palette entry number 5 have the colour gold in the
*        reserved portion of the colour table of the current image
*        display.
*     palentry 12 [1.0,1.0,0.3] xwindows
*        This makes the xwindows device's palette entry number 12 have
*        a pale-yellow colour.

*  Related Applications:
*     KAPPA: PALDEF, PALREAD, PALSAVE.

*  [optional_A_task_items]...
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1991 July 19 (MJC):
*        Original version.
*     1992 March 3 (MJC):
*        Replaced AIF parameter-system calls by the extended PAR
*        library.
*     1992 December 1 (MJC):
*        Made to work with WINDOW_OVERLAY devices.
*     30-OCT-1998 (DSB):
*        Modified to save current palette in the adam directory so that
*        subsequent PGPLOT applications can read it back in again.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'CTM_PAR'          ! Colour-table management constants

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER NPRICL             ! Number of primary colours
      PARAMETER ( NPRICL = 3 )

*  Local Variables:
      INTEGER
     :  IPIXX,                   ! Dummy
     :  IPIXY,                   ! Dummy
     :  NINTS,                   ! Total number of colour indices
                                 ! on the chosen device
     :  PALNUM,                  ! Palette entry number to have its
                                 ! colour changed
     :  WKID,                    ! Work station identification
     :  ZONE                     ! Input zone identification

      REAL
     :  RGBINT( NPRICL )         ! RGB intensities of the chosen colour

      LOGICAL                    ! True if :
     :  DEVCAN                   ! Image-display parameter is to be
                                 ! cancelled

*.

*    Check the inherited global status.

      IF ( STATUS .NE. SAI__OK ) RETURN

      DEVCAN = .FALSE.

*    Start the graphics system.
*    ==========================

*    Open up SGS in update mode as only some colours are to be changed.

      CALL SGS_ASSOC( 'DEVICE', 'UPDATE', ZONE, STATUS )

*    Check whether chosen device is an 'image display'.  It must have
*    a suitable minimum number of colour indices, and will not reset
*    when opened.

      CALL KPG1_QVID( 'DEVICE', 'SGS', 'IMAGE_DISPLAY,IMAGE_OVERLAY,'/
     :                /'WINDOW,WINDOW_OVERLAY,MATRIX_PRINTER',
     :                'COLOUR', 2, STATUS )

*    Obtain the number of colour indices and the maximum display
*    surface.

      CALL KPG1_QIDAT( 'DEVICE', 'SGS', NINTS, IPIXX, IPIXY, STATUS )

      IF ( STATUS .NE. SAI__OK ) THEN

*       The device name is to be cancelled to prevent an invalid device
*       being stored as the current value.

         DEVCAN = .TRUE.
         GOTO 999
      END IF

*    Find the workstation identifier.

      CALL SGS_ICURW( WKID )
      
*    Obtain the new palette colour.
*    ==============================

*    The suggested default will usually have a grey colour.

      CALL PAR_GDR0I( 'PALNUM', 1, 0, MIN( CTM__RSVPN, NINTS ) - 1,
     :                .FALSE., PALNUM, STATUS )

*    Get one colour for the palette number.

      CALL KPG1_GPCOL( 'COLOUR', RGBINT, STATUS )

*    Install the palette into image-display colour table.
*    ====================================================

      IF ( STATUS .EQ. SAI__OK ) THEN
         CALL GSCR( WKID, PALNUM, RGBINT( 1 ), RGBINT( 2 ),
     :              RGBINT( 3 ) )

*    See whether GKS had an internal error.

         CALL GKS_GSTAT( STATUS )

*    Save the modified palette entry in the adam directory so that it can be 
*    read back again by subsequent applications (PGPLOT resets the colour 
*    palette when it opens a device, so the palette then needs to be 
*    re-instated). Other elements in the saved palette are left unchanged.
         CALL KPG1_PLSAV( PALNUM, PALNUM, .FALSE., STATUS )

      END IF

*    If an error occurred, then report a contextual message.

  999 CONTINUE
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'PALENTRY_ERR',
     :   'PALENTRY: Unable to enter a colour into the palette.',
     :   STATUS )
      END IF

*    Tidy the graphics system.

      IF ( DEVCAN ) THEN
         CALL SGS_CANCL( 'DEVICE', STATUS )
      ELSE
         CALL SGS_ANNUL( ZONE, STATUS )
      END IF

*    Deactivate SGS so that the next call to SGS_ASSOC will initialise
*    SGS, and hence can work in harmony with AGI-SGS applications.

      CALL SGS_DEACT( STATUS )

      END
