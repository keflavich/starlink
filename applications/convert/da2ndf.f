      SUBROUTINE DA2NDF( STATUS )
*+
*  Name:
*     DA2NDF

*  Purpose:
*     Converts a direct-access unformatted file to an NDF.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL DA2NDF( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application converts a direct-access (fixed-length records)
*     unformatted file to an NDF.  It can therefore also process
*     unformatted data files generated by C routines.  Only one of the
*     array components may be created from the input file.   The shape
*     of the NDF has be to be supplied.

*  Usage:
*     da2ndf in out [comp] noperec shape [type]

*  ADAM Parameters:
*     COMP = LITERAL (Read)
*        The NDF component to be copied.  It may be "Data", "Quality"
*        or "Variance".  To create a variance or quality array the NDF
*        must already exist. ["Data"]
*     IN = FILENAME (Read)
*        Name of the input direct-access unformatted file.
*     NOPEREC = _INTEGER (Read)
*        The number of data values per record of the input file.  It
*        must be positive.  The suggested default is the size of the
*        first dimension of the array.  A null (!) value for NOPEREC
*        causes the size of first dimension to be used.
*     OUT = NDF (Read and Write)
*        Output NDF data structure.  When COMP is not "Data" the NDF
*        is modified rather than a new NDF created.  It becomes the new
*        current NDF.  Unusually for an output NDF, there is a suggested
*        default---the current value---to facilitate the inclusion of
*        variance and quality arrays.
*     SHAPE = _INTEGER (Read)
*        The shape of the NDF to be created.  For example, [40,30,20]
*        would create 40 columns by 30 lines by 10 bands.
*     TYPE = LITERAL (Read)
*        The data type of the direct-access file and the NDF.  It must
*        be one of the following HDS types: "_BYTE", "_WORD", "_REAL",
*        "_INTEGER", "_INT64", "_DOUBLE", "_UBYTE", "_UWORD"
*        corresponding to signed byte, signed word, real, integer,
*        64-bit integers, double precision, unsigned byte, and unsigned
*        word respectively.  See SUN/92 for further details.  An
*        unambiguous abbreviation may be given.  TYPE is ignored when
*        COMP = "Quality" since the QUALITY component must comprise
*        unsigned bytes (equivalent to TYPE = "_UBYTE") to be a valid
*        NDF.  The suggested default is the current value. ["_REAL"]

*  Examples:
*     da2ndf ngc253.dat ngc253 shape=[100,60] noperec=8
*        This copies a data array from the direct-access file ngc253.dat
*        to the NDF called ngc253.  The NDF is two-dimensional: 100
*        elements in x by 60 in y.  Its data array has type _REAL.  The
*        data records each have 8 real values.
*     da2ndf ngc253q.dat ngc253 q 100 [100,60]
*        This copies a quality array from the direct-access file
*        ngc253q.dat to an existing NDF called ngc253 (such as created
*        in the first example).  The NDF is two-dimensional: 100
*        elements in x by 60 in y.  Its data array has type _UBYTE.
*        The data records each have 100 unsigned-byte values.
*     da2ndf type="_uword" in=ngc253.dat out=ngc253 \
*        This copies a data array from the direct-access file ngc253.dat
*        to the NDF called ngc253.  The NDF has the current shape and
*        data type is unsigned word.  The current number of values per
*        record is used.

*  Notes:
*     The details of the conversion are as follows:
*        -  the direct-access file's array is written to the NDF array
*        as selected by COMP.  When the NDF is being modified, the
*        shape of the new component must match that of the NDF.  This
*        enables more than one array (input file) to be used to form an
*        NDF.  Note that the data array must be created first to make a
*        valid NDF.  Indeed the application prevents you from doing
*        otherwise.
*        -  Other data items such as axes are not supported, because of
*        the direct-access file's simple structure.

*  Related Applications:
*     CONVERT: NDF2DA.

*  Copyright:
*     Copyright (C) 1996, 2004 Central Laboratory of the Research
*     Councils.  Copyright (C) 2011-2012 Science & Technology
*     Facilities Council.  All Rights Reserved.

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
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     1996 October 19 (MJC):
*        Original version.
*     2004 September 9 (TIMJ):
*        Use CNF_PVAL.
*     2011 January 12 (MJC):
*        Use KPG_TYPSZ instead of COF_TYPSZ.
*     2012 April 30 (MJC):
*        Add _INT64 type.
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! Data-system constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT public constants
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER * ( 8 ) COMP     ! The component of NDF to write
      INTEGER DIMS( NDF__MXDIM ) ! The dimensions of the input NDF
      INTEGER EL                 ! Number of mapped elements
      INTEGER FD                 ! File descriptor
      INTEGER I                  ! Loop counter
      INTEGER LBND( NDF__MXDIM ) ! Lower bounds of NDF
      INTEGER LUN                ! Logical unit number
      CHARACTER MACHIN * ( 24 )  ! Machine name
      INTEGER NBYTES             ! Number of bytes per data value
      INTEGER NDF                ! Identifier for NDF
      INTEGER NDIM               ! The dimensionality of the input array
      CHARACTER NODE * ( 20 )    ! Node name
      INTEGER NUMPRE             ! Number of data values per record
      INTEGER ODIMS( NDF__MXDIM ) ! The dimensions of the existing NDF
      INTEGER ONDIM              ! The dimensionality of the existing
                                 ! NDF
      INTEGER PNTR( 1 )          ! Pointer to NDF mapped array
      INTEGER RECLEN             ! Record length
      CHARACTER RELEAS * ( 10 )  ! Release of operating system
      CHARACTER SYSNAM * ( 10 )  ! Operating system
      CHARACTER * ( NDF__SZTYP ) TYPE ! Data type for processing
      LOGICAL UPDATE             ! True if an NDF is to be modified
      LOGICAL VALID              ! True if it is valid to insert the new
                                 ! array into an existing NDF
      CHARACTER VERSIO * ( 10 )  ! Sub-version of operating system
      LOGICAL VMS                ! True if running on a VAX/VMS system

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Find out which component is to be processed.
*  ============================================

*  Find which component to copy.
      CALL PAR_CHOIC( 'COMP', 'Data', 'Data,Variance,Quality',
     :                .FALSE., COMP, STATUS )
      UPDATE = COMP .NE. 'DATA'

*  Check the status to prevent possibly adding confusing error messages.
      IF ( STATUS .NE. SAI__OK ) GOTO 999

*  Obtain additional parameters.
*  =============================
*  Obtain the shape of the NDF.
      CALL PAR_GDRVI( 'SHAPE', NDF__MXDIM, 1, VAL__MAXI, DIMS,
     :                NDIM, STATUS )

*  Get type of data required, selected from the menu of HDS numeric
*  types.  Note that the QUALITY component must be unsigned byte.
      IF ( COMP .EQ. 'QUALITY' ) THEN
         TYPE = '_UBYTE'

      ELSE
         CALL PAR_CHOIC( 'TYPE', '_REAL', '_BYTE,_DOUBLE,_INTEGER,'/
     :                   /'_INT64,_REAL,_UBYTE,_UWORD,_WORD', .FALSE.,
     :                   TYPE, STATUS )
      END IF

*  Obtain the number of bytes corresponding to the chosen data type.
      CALL KPG_TYPSZ( TYPE, NBYTES, STATUS )

*  Exit here in case an error arose so as to prevent spurious error
*  messages.
      IF ( STATUS .NE. SAI__OK ) GOTO 999

*  Obtain the input NDF.
*  =====================

*  Begin an NDF context.
      CALL NDF_BEGIN

*  Obtain an identifier for the updated NDF.
      IF ( UPDATE ) THEN
         CALL NDF_ASSOC( 'OUT', 'UPDATE', NDF, STATUS )

*  Validate the dimensions.
         CALL NDF_DIM( NDF, NDF__MXDIM, ODIMS, ONDIM, STATUS )
         VALID = ONDIM .EQ. NDIM
         I = 0
         DO WHILE ( VALID .AND. I .LT. ONDIM )
            I = I + 1
            VALID = VALID .AND. DIMS( I ) .EQ. ODIMS( I )
         END DO

*  Report an error if copying the new array would produce an invalid
*  NDF.
         IF ( .NOT. VALID ) THEN
            STATUS = SAI__ERROR
            CALL NDF_MSG( 'NDF', NDF )
            CALL ERR_REP( 'DA2NDF_SHAPE',
     :        'DA2NDF: The shape of the new array is not the same '/
     :        /'as that of the NDF ^NDF.', STATUS )
            GOTO 980
         END IF

*  Create a new simple NDF.
      ELSE
         DO I = 1, NDIM
            LBND( I ) = 1
         END DO
         CALL NDF_CREAT( 'OUT', TYPE, NDIM, LBND, DIMS, NDF, STATUS )
      END IF

*  Fix the data type.
*  ==================

*  This is required so that that one- and two-byte integer types may be
*  mapped as integer for reading, but are actually stored with the
*  correct type.  The type cannot be altered for the QUALITY array.
      IF ( COMP .EQ. 'VARIANCE' )
     :  CALL NDF_STYPE( TYPE, NDF, COMP, STATUS )

*  Determine whether or not the operating system is VMS/Digital.
*  =============================================================
*
*  This assumes that the system is either VMS or UNIX.  It is needed
*  to specify the path of the file containing the global parameters.
      CALL PSX_UNAME( SYSNAM, NODE, RELEAS, VERSIO, MACHIN, STATUS )
      VMS = INDEX( SYSNAM, 'VMS' ) .NE. 0

*  Obtain the number of values per record.
*  =======================================
      IF ( VMS ) THEN
         CALL PAR_GDR0I( 'NOPEREC', MIN( 16383, DIMS( 1 ) ), 1,
     :                   16383, .TRUE., NUMPRE, STATUS )
      ELSE
         CALL PAR_GDR0I( 'NOPEREC', DIMS( 1 ), 1,
     :                   VAL__MAXI, .TRUE., NUMPRE, STATUS )
      END IF

*  Open the direct-access unformatted file.
*  ========================================

*  Define the record length.
      RECLEN = NUMPRE * NBYTES

*  Open the FORTRAN file.
      CALL RIO_ASSOC( 'IN', 'READ', 'UNFORMATTED', RECLEN, FD, STATUS )

*  Obtain the logical unit number of the file.
      CALL FIO_UNIT( FD, LUN, STATUS )

*  Process the input array.
*  ========================

*  Map the input data array using the input data type.
      CALL NDF_MAP( NDF, COMP, TYPE, 'WRITE', PNTR, EL, STATUS )

*  Call a routine to read the data from the direct-access unformatted
*  file.  The selected routine depending on the data type of the array.
      IF ( TYPE .EQ. '_BYTE' ) THEN
         CALL CON_IUDAB( FD, EL, NUMPRE, 0,
     :                   %VAL( CNF_PVAL( PNTR( 1 ) ) ),
     :                   STATUS )

      ELSE IF ( TYPE .EQ. '_DOUBLE' ) THEN
         CALL CON_IUDAD( FD, EL, NUMPRE, 0,
     :                   %VAL( CNF_PVAL( PNTR( 1 ) ) ),
     :                   STATUS )

      ELSE IF ( TYPE .EQ. '_INTEGER' ) THEN
         CALL CON_IUDAI( FD, EL, NUMPRE, 0,
     :                   %VAL( CNF_PVAL( PNTR( 1 ) ) ),
     :                   STATUS )

      ELSE IF ( TYPE .EQ. '_INT64' ) THEN
         CALL CON_IUDAK( FD, EL, NUMPRE, 0,
     :                   %VAL( CNF_PVAL( PNTR( 1 ) ) ),
     :                   STATUS )

      ELSE IF ( TYPE .EQ. '_REAL' ) THEN
         CALL CON_IUDAR( FD, EL, NUMPRE, 0,
     :                   %VAL( CNF_PVAL( PNTR( 1 ) ) ),
     :                   STATUS )

      ELSE IF ( TYPE .EQ. '_UBYTE' ) THEN
         CALL CON_IUDAUB( FD, EL, NUMPRE, 0,
     :                    %VAL( CNF_PVAL( PNTR( 1 ) ) ),
     :                    STATUS )

      ELSE IF ( TYPE .EQ. '_UWORD' ) THEN
         CALL CON_IUDAUW( FD, EL, NUMPRE, 0,
     :                    %VAL( CNF_PVAL( PNTR( 1 ) ) ),
     :                    STATUS )

      ELSE IF ( TYPE .EQ. '_WORD' ) THEN
         CALL CON_IUDAW( FD, EL, NUMPRE, 0,
     :                   %VAL( CNF_PVAL( PNTR( 1 ) ) ),
     :                   STATUS )

      END IF

*  Close the output file.
      CALL FIO_CLOSE( FD, STATUS )

*  End the NDF context.
  980 CONTINUE
      CALL NDF_END( STATUS )

  999 CONTINUE

*  If an error occurred, then report context information.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'DA2NDF_ERR',
     :     'DA2NDF: Error converting a direct-access unformatted file '/
     :     /'to an NDF.', STATUS )
      END IF

      END
