      SUBROUTINE ADI2_CHKPRV( FID, CHDU, WRKEYS, STATUS )
*+
*  Name:
*     ADI2_CHKPRV

*  Purpose:
*     Define data areas of HDUs up the point being worked on

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ADI2_CHKPRV( FID, CHDU, WRKEYS, STATUS )

*  Description:
*     Commit any changes to keywords or data to the FITS file on disk. The
*     file is not closed.

*  Arguments:
*     FID = INTEGER (given)
*        ADI identifier of the FITSfile object
*     CHDU = INTEGER (given)
*        The HDU being worked on
*     WRKEYS = LOGICAL (given)
*        Commit keywords to file?
*     STATUS = INTEGER (given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Pitfalls:
*     {pitfall_description}...

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     {routine_prior_requirements}...

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     {algorithm_description}...

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     ADI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/adi.html

*  Keywords:
*     package:adi, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     2 Feb 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ADI_PAR'

*  Arguments Given:
      INTEGER			FID			! FITSfile identifier
      INTEGER			CHDU			! Current HDU
      LOGICAL			WRKEYS			! Write keywords?

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      INTEGER			FSTAT			! FITSIO status
      INTEGER			HDUTYPE			! Type of HDU
      INTEGER			IHDU			! Loop over HDUs
      INTEGER			KCID			! Keyword container
      INTEGER			LUN			! Logical unit
      INTEGER			NKEY			! Keyword count
      INTEGER			OHID			! Old HDU object

      LOGICAL			CREATED			! HDU already created?
      LOGICAL			DEFBEG			! Definition started?
      LOGICAL			DEFEND			! Definition ended?
      LOGICAL			MOVED			! Moved to HDU yet?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise
      FSTAT = 0

*  Extract logical unit
      CALL ADI2_GETLUN( FID, LUN, STATUS )

*  Loop over all specified HDU's, ensuring they have defined data areas
      DO IHDU = 1, CHDU

*    Initialise for this HDU
        FSTAT = 0
        MOVED = .FALSE.
        NKEY = 0

*    Locate an HDU by its consecutive number
        CALL ADI2_LOCIHD( FID, IHDU, OHID, STATUS )

*    Is the definition incomplete?
        CALL ADI_CGET0L( OHID, 'DefEnd', DEFEND, STATUS )
        IF ( .NOT. DEFEND ) THEN

*      The definition may be unfinished, or it may not even be started
          CALL ADI_CGET0L( OHID, 'DefStart', DEFBEG, STATUS )
          IF ( DEFBEG ) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETI( 'HDU', IHDU )
            CALL ERR_REP( ' ', 'Error creating HDU, previous HDU '/
     :       /'number ^HDU data area length is undefined', STATUS )

          ELSE

*        Has the HDU even been created?
            CALL ADI_CGET0L( OHID, 'Created', CREATED, STATUS )

*        Create it if it doesn't exist
            IF ( .NOT. CREATED ) THEN

*          Move to the IHDU'th HDU
              CALL FTMAHD( LUN, IHDU, HDUTYPE, FSTAT )
              MOVED = .TRUE.
              IF ( FSTAT .EQ. 107 ) FSTAT = 0
              IF ( IHDU .GT. 1 ) THEN
                CALL FTCRHD( LUN, FSTAT )
              END IF

              IF ( (FSTAT.NE.0) .AND. (FSTAT.NE.107) ) THEN
                CALL ADI2_FITERP( FSTAT, STATUS )
                GOTO 99
              ELSE IF ( FSTAT .EQ. 107 ) THEN
                FSTAT = 0
              END IF

              CALL ADI_CPUT0L( OHID, 'Created', .TRUE., STATUS )

*          Locate the keywords structure
              CALL ADI_FIND( OHID, 'Keys', KCID, STATUS )

*          How many components?
              CALL ADI_NCMP( KCID, NKEY, STATUS )

*          Release keywords structure
              CALL ADI_ERASE( KCID, STATUS )

            END IF

*        There is no definition, however, so create a default one
	    CALL FTPDEF( LUN, 8, 0, 0, 0, 1, FSTAT )
            CALL FTPHPR( LUN, .TRUE., 8, 0, 0, 0, 1, .TRUE., FSTAT )

*        Reserve keyword space?
            IF ( NKEY .GT. 0 ) THEN
              CALL FTHDEF( LUN, NKEY, FSTAT )
            END IF
c	    CALL FTRDEF( LUN, FSTAT )
            IF ( FSTAT .NE. 0 ) THEN
              CALL ADI2_FITERP( FSTAT, STATUS )
            END IF

*        Mark as defined
            CALL ADI_CPUT0L( OHID, 'DefStart', .TRUE., STATUS )
            CALL ADI_CPUT0L( OHID, 'DefEnd', .TRUE., STATUS )

          END IF

        END IF

*    Still ok?
        IF ( STATUS .EQ. SAI__OK ) THEN

*      Write keywords?
          IF ( WRKEYS ) THEN

*        Move to HDU unless already there
            IF ( .NOT. MOVED ) THEN
              CALL FTMAHD( LUN, IHDU, HDUTYPE, FSTAT )
            END IF

*        Write the keywords
            CALL ADI2_FCOMIT_HDU( FID, .TRUE., LUN, IHDU, LUN, OHID,
     :                            STATUS )

          END IF

        END IF

*    Release old HDU
        CALL ADI_ERASE( OHID, STATUS )

      END DO

*  Report any errors
 99   IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'ADI2_CHKPRV', STATUS )

      END
