      SUBROUTINE sgs_STXJ (TXJ)
*+
*   - - - - -
*    S T X J
*   - - - - -
*
*   Set text justification.
*
*   Given:
*      TXJ       c*2      text justification code
*
*      The text justification code is a string whose first two
*      characters specify the vertical and horizontal alignments
*      respectively.  The first can be B(ottom), C(entre) or T(op); the
*      second can be L(eft), C(entre) or R(ight); other characters cause
*      no change.  The alignment refers to where in the character string
*      the nominated X,Y lies; thus a code of 'BL' would place the
*      nominated X,Y at the bottom left of the string.  The terms 'TOP',
*      'LEFT' etc refer to the character string as seen in its normal
*      orientation, rather than as actually displayed.
*
*   Written to COMMON:
*      CTXJ      c*2      current text justification
*
*   Externals:
*      sgs_OTEXT, sgs_1UPCAS, sgs_1SETTX
*
*   P.T.Wallace, D.L.Terrett   Starlink   14 September 1991
*-

      IMPLICIT NONE

      CHARACTER*(*) TXJ

      CHARACTER LTXJ*2

      INCLUDE 'sgscom'




*  Flush any existing text string
      CALL sgs_OTEXT

*  Convert to uppercase
      CALL sgs_1UPCAS(TXJ(:2),LTXJ)

*  Vertical
      IF (LTXJ(:1).EQ.'B') CTXJ(:1)='B'
      IF (LTXJ(:1).EQ.'C') CTXJ(:1)='C'
      IF (LTXJ(:1).EQ.'T') CTXJ(:1)='T'

*  Horizontal
      IF (LTXJ(2:2).EQ.'L') CTXJ(2:)='L'
      IF (LTXJ(2:2).EQ.'C') CTXJ(2:)='C'
      IF (LTXJ(2:2).EQ.'R') CTXJ(2:)='R'

      CALL sgs_1SETTX

      END
