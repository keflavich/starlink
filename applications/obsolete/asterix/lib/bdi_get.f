      SUBROUTINE BDI_GET( ID, ITEMS, TYPE, NDIM, DIMX, DATA,
     :                    DIMS, STATUS )
*+
*  Name:
*     BDI_GET

*  Purpose:
*     Get the named items with the specified type and dimensions

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL BDI_GET( ID, ITEMS, TYPE, NDIM, DIMX, DATA, DIMS, STATUS )

*  Description:
*     Retrieves the items specified by the ITEMS string with the specified
*     TYPE. Should only be used for numeric items.

*  Arguments:
*     ID = INTEGER (given)
*        ADI identifier of BinDS, Array or Scalar object, or derivatives
*        thereof
*     ITEMS = CHARACTER*(*) (given)
*        List of items to be mapped
*     TYPE = CHARACTER*(*) (given)
*        The type with which access mapping will be performed
*     NDIM = INTEGER (given)
*        The dimensionality of the users data buffer
*     DIMX[NDIM] = INTEGER (given)
*        The dimensions of the users buffer
*     DATA[] = varies (returned)
*        The returned data
*     DIMS[] = INTEGER (returned)
*        The actual sizes of the data written the users buffer
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
*     BDI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/bdi.html

*  Keywords:
*     package:bdi, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     9 Aug 1995 (DJA):
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

*  Global Variables:
      INCLUDE 'BDI_CMN'                                 ! BDI common block
*       BDI_INIT = LOGICAL (given)
*         BDI class definitions loaded?

*  Arguments Given:
      INTEGER			ID, NDIM, DIMX(*)
      CHARACTER*(*)		ITEMS, TYPE

*  Arguments Returned:
      BYTE			DATA(*)
      INTEGER			DIMS(*)

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      EXTERNAL			BDI0_BLK		! Ensures inclusion

*  Local Variables:
      CHARACTER*20		LITEM			! Local item name

      INTEGER			ARGS(3)			! Function args
      INTEGER			C1, C2			! Character pointers
      INTEGER			CURELM			! Current o/p element
      INTEGER			ESIZE			! Element size
      INTEGER			IITEM			! Item counter
      INTEGER			LITL			! Used length of LITEM
      INTEGER			NELM			! Max elements per item
      INTEGER			OARG			! Return value
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check initialised
      IF ( .NOT. BDI_INIT ) CALL BDI0_INIT( STATUS )

*  First function argument is the identifier
      ARGS(1) = ID

*  Second is the linked file object
      CALL ADI_GETLINK( ID, ARGS(2), STATUS )

*  Current element in output buffer
      CURELM = 1

*  Element size in bytes
      CALL UDI0_TYPSIZ( TYPE, ESIZE, STATUS )

*  Number of output data elements user has supplied per item
      CALL ARR_SUMDIM( NDIM, DIMX, NELM )

*  Loop over items while more of them and status is ok
      CALL UDI0_CREITI( ITEMS, C1, C2, IITEM, STATUS )
      DO WHILE ( (C1.NE.0) .AND. (STATUS.EQ.SAI__OK) )

*    Check item name is valid, and make a local copy. Removes any
*    special item names such as E_Axis_Label.
        CALL BDI0_CHKITM( ID, ITEMS(C1:C2), LITEM, LITL, STATUS )

*    Check that item can be mapped
        CALL BDI0_CHKOP( LITEM(:LITL), 'Get', STATUS )

*    Construct string for this item
        CALL ADI_NEWV0C( LITEM(:LITL), ARGS(3), STATUS )

*    Invoke the function
        CALL ADI_FEXEC( 'FileItemGet', 3, ARGS, OARG, STATUS )

*    Extract data from return value
        IF ( (STATUS .EQ. SAI__OK) .AND. (OARG.NE.ADI__NULLID) ) THEN

          CALL ADI_GET( OARG, TYPE, NDIM, DIMX, DATA(CURELM),
     :                    DIMS, STATUS )
          CALL ADI_ERASE( OARG, STATUS )

        ELSE IF ( STATUS .NE. SAI__OK ) THEN
          CALL MSG_SETC( 'ITEM', LITEM(:LITL) )
          CALL ERR_REP( 'BDI_GET_1', 'Unable to get item ^ITEM',
     :                    STATUS )

        END IF

*    Release the item string
        CALL ERR_BEGIN( STATUS )
        CALL ADI_ERASE( ARGS(3), STATUS )
        CALL ERR_END( STATUS )

*    Advance pointer into output buffer
        CURELM = CURELM + NELM * ESIZE

*    Advance iterator to next item
        CALL UDI0_ADVITI( ITEMS, C1, C2, IITEM, STATUS )

      END DO

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'BDI_GET', STATUS )

      END
