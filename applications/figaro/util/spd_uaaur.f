      REAL FUNCTION SPD_UAAUR( WRT, CEN, PEA, WID, X )
*+
*  Name:
*     SPD_UAAU{DR}

*  Purpose:
*     Get one value for triangular profile derivative.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     RESULT = SPD_UAAUR( WRT, CEN, PEA, WID, X )

*  Description:
*     This function returns for one given abscissa value the value
*     of the derivative of a triangular profile with respect to one of
*     the profile parameters. Note that this is not the derivative with
*     respect to abscissa values.

*  Arguments:
*     WRT = INTEGER (Given)
*        1/2/3 in order to return the derivative w.r.t. centre, peak or
*        width. If WRT has an invalid value, this routine will return a
*        result of zero.
*     CEN = REAL (Given)
*        The abscissa value of the centre of the profile.
*     PEA = REAL (Given)
*        The ordinate value of the centre of the profile.
*     WID = REAL (Given)
*        The full width at half maximum of the profile. As it happens
*        this is also the half width at zero. WID must not equal zero.
*     X = REAL (Given)
*        The abscissa value for which the profile derivative's ordinate
*        value is to be returned.

*  Returned Value:
*     SPD_UAAUR = REAL
*        The ordinate value of the profile derivative at the given
*        abscissa value.

*  Authors:
*     ajlf: Amadeu Fernandes (UoE)
*     hme: Horst Meyerdierks (UoE, Starlink)
*     {enter_new_authors_here}

*  History:
*     31 Jan 1992 (ajlf):
*        Original version (FUNC_Y in AMFUN.FOR).
*     24 Jul 1992 (hme):
*        Prologue. Generic routine.
*     19 Dec 1994 (hme):
*        Renamed from SPABAR.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Arguments Given:
      INTEGER WRT
      REAL CEN
      REAL PEA
      REAL WID
      REAL X

*.

*  Default value for invalid WRT and for x outside profile.
      SPD_UAAUR = 0.

*  With respect to centre.
      IF      ( WRT .EQ. 1 ) THEN
         IF      ( X .GT. CEN - WID .AND. X .LE. CEN ) THEN
            SPD_UAAUR = - PEA / WID
         ELSE IF ( X .GE. CEN .AND. X .LT. CEN + WID ) THEN
            SPD_UAAUR = + PEA / WID
         END IF

*  With respect to peak.
      ELSE IF ( WRT .EQ. 2 ) THEN
         IF      ( X .GT. CEN - WID .AND. X .LE. CEN ) THEN
            SPD_UAAUR = 1. - ( CEN - X ) / WID
         ELSE IF ( X .GE. CEN .AND. X .LT. CEN + WID ) THEN
            SPD_UAAUR = 1. - ( X - CEN ) / WID
         END IF

*  With respect to FWHM.
      ELSE IF ( WRT .EQ. 3 ) THEN
         IF      ( X .GT. CEN - WID .AND. X .LE. CEN ) THEN
            SPD_UAAUR = PEA * ( CEN - X ) / WID / WID
         ELSE IF ( X .GE. CEN .AND. X .LT. CEN + WID ) THEN
            SPD_UAAUR = PEA * ( X - CEN ) / WID / WID
         END IF
      END IF

*  Return.
      END
