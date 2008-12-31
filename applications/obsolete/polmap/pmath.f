      SUBROUTINE PMATH(NPARAMS,PARAMS,TOP_STK,
     &   STK_STOKES_I,STK_STOKES_Q,STK_STOKES_QV,
     &   STK_STOKES_U,STK_STOKES_UV,STK_LAMBDA,
     &   STK_NPTS,STOKES_I,STOKES_Q,
     &   STOKES_QV,STOKES_U,STOKES_UV,LAMBDA,NPTS,SYMB,OUT_LU)
C+
C
C Subroutine: 
C
C   P M A T H
C
C
C Author: Tim Harries (tjh@st-and.ac.uk)
C
C Parameters: 
C
C NPARAMS (<), PARAMS (<), TOP_STK (<),
C STK_STOKES_I (<), STK_STOKES_Q (<), STK_STOKES_QV (<),
C STK_STOKES_U (<), STK_STOKES_UV (<), STK_LAMBDA (<),
C STK_NPTS (<), STOKES_I (>), STOKES_Q (>),
C STOKES_QV (>), STOKES_U (>), STOKES_UV (>),
C LAMBDA (>), NPTS (>), SYMB (<), OUT_LU (<)
C
C History: 
C  
C   May 1994 Created
C 
C
C  
C
C
C Performs mathematical operations on two polarization spectra.
C
C
C
C
C-
      IMPLICIT NONE
      INTEGER OUT_LU
      INCLUDE 'array_size.inc'
C
C Stack polarization spectra.
C
      REAL STK_LAMBDA(MAXPTS,MAXSPEC)
      REAL STK_STOKES_I(MAXPTS,MAXSPEC)
      REAL STK_STOKES_Q(MAXPTS,MAXSPEC)
      REAL STK_STOKES_QV(MAXPTS,MAXSPEC)
      REAL STK_STOKES_U(MAXPTS,MAXSPEC)
      REAL STK_STOKES_UV(MAXPTS,MAXSPEC)
      INTEGER STK_NPTS(MAXSPEC)
      INTEGER TOP_STK
C
C Temp polarization spectrum
C
      REAL TMP_STOKES_I(MAXPTS)
      REAL TMP_STOKES_Q(MAXPTS)
      REAL TMP_STOKES_QV(MAXPTS)
      REAL TMP_STOKES_U(MAXPTS)
      REAL TMP_STOKES_UV(MAXPTS)
      REAL TMP_LAMBDA(MAXPTS)
      REAL TMP2_STOKES_I(MAXPTS)
      REAL TMP2_STOKES_Q(MAXPTS)
      REAL TMP2_STOKES_QV(MAXPTS)
      REAL TMP2_STOKES_U(MAXPTS)
      REAL TMP2_STOKES_UV(MAXPTS)
      REAL TMP2_LAMBDA(MAXPTS)
C
C Current polarization spectrum
C
      REAL STOKES_I(MAXPTS)
      REAL STOKES_Q(MAXPTS)
      REAL STOKES_QV(MAXPTS)
      REAL STOKES_U(MAXPTS)
      REAL STOKES_UV(MAXPTS)
      REAL LAMBDA(MAXPTS)
      INTEGER NPTS
C
C Command parameters
C
      INTEGER NPARAMS
      REAL PARAMS(*)
C
C Misc.
C
      INTEGER FPE
      INTEGER BINNO
C
      REAL RECT_I
      INTEGER SP
      INTEGER I,WS
      REAL ITEMP,QTEMP,QVTEMP,UTEMP,UVTEMP
      INTEGER TMP_NPTS
      CHARACTER*1 SYMB
      LOGICAL OK
C
      IF (NPARAMS.GT.1) THEN
       CALL WR_ERROR('Additional parameters ignored',OUT_LU)
      ENDIF
      IF (NPARAMS.EQ.0) THEN
        CALL GET_PARAM('Stack entry',PARAMS(1),OK,OUT_LU)
        IF (.NOT.OK) GOTO 666
        NPARAMS = 1
      ENDIF
C
      IF (NPTS.EQ.0) THEN
        CALL WR_ERROR('Current arrays are empty',OUT_LU)
        GOTO 666
      ENDIF
C
      SP = INT(PARAMS(1))
      IF ( (SP.LT.0).OR.(SP.GT.TOP_STK) ) THEN
       CALL WR_ERROR('Stack entry out of range',OUT_LU)
       GOTO 666
      ENDIF
C
      IF ((LAMBDA(NPTS).LT.STK_LAMBDA(1,SP)).OR.
     &    (LAMBDA(1).GT.STK_LAMBDA(STK_NPTS(SP),SP))) THEN
       CALL WR_ERROR('Wavelength ranges do not overlap',OUT_LU)
       GOTO 666
      ENDIF
C
      DO I = 1,STK_NPTS(SP)
       TMP_STOKES_I(I) = STK_STOKES_I(I,SP)
       TMP_STOKES_Q(I) = STK_STOKES_Q(I,SP)
       TMP_STOKES_QV(I) = STK_STOKES_QV(I,SP)
       TMP_STOKES_U(I) = STK_STOKES_U(I,SP)
       TMP_STOKES_UV(I) = STK_STOKES_UV(I,SP)
       TMP_LAMBDA(I) = STK_LAMBDA(I,SP)
      ENDDO
C
      TMP_NPTS = STK_NPTS(SP)
C
      I = 1
      BINNO = 1
      FPE = 0
      DO WHILE(I.LE.NPTS)

C
C Linear interpolation used between two spectra
C
      IF ((LAMBDA(I).LT.TMP_LAMBDA(1)).OR.
     &    (LAMBDA(I).GT.TMP_LAMBDA(TMP_NPTS))) THEN
       I = I+1
        ELSE
       CALL LOCATE(TMP_LAMBDA,TMP_NPTS,LAMBDA(I),WS)
       IF (TMP_LAMBDA(1).EQ.LAMBDA(I)) WS = 1
       CALL LINTERP(TMP_LAMBDA(WS),TMP_LAMBDA(WS+1),
     & TMP_STOKES_I(WS),TMP_STOKES_I(WS+1),LAMBDA(I),ITEMP )
       CALL LINTERP(TMP_LAMBDA(WS),TMP_LAMBDA(WS+1),
     & TMP_STOKES_Q(WS),TMP_STOKES_Q(WS+1),LAMBDA(I),QTEMP )
       CALL LINTERP(TMP_LAMBDA(WS),TMP_LAMBDA(WS+1),
     & TMP_STOKES_QV(WS),TMP_STOKES_QV(WS+1),LAMBDA(I),QVTEMP )
       CALL LINTERP(TMP_LAMBDA(WS),TMP_LAMBDA(WS+1),
     & TMP_STOKES_U(WS),TMP_STOKES_U(WS+1),LAMBDA(I),UTEMP )
       CALL LINTERP(TMP_LAMBDA(WS),TMP_LAMBDA(WS+1),
     & TMP_STOKES_UV(WS),TMP_STOKES_UV(WS+1),LAMBDA(I),UVTEMP )
C
C Subracts normalized Stokes parameters
C
       IF (SYMB.EQ.'-') THEN
        IF (STOKES_I(I).NE.0.) THEN
         TMP2_STOKES_Q(BINNO) = QTEMP-ITEMP*(STOKES_Q(I)/STOKES_I(I))
         TMP2_STOKES_U(BINNO) = UTEMP-ITEMP*(STOKES_U(I)/STOKES_I(I))
         TMP2_STOKES_QV(BINNO) = QVTEMP+
     &                   (ITEMP**2)*(STOKES_QV(I)/STOKES_I(I)**2)
         TMP2_STOKES_UV(BINNO) = UVTEMP+
     &                   (ITEMP**2)*(STOKES_UV(I)/STOKES_I(I)**2)
         TMP2_STOKES_I(BINNO) = ITEMP
          ELSE
         TMP2_STOKES_Q(BINNO) = QTEMP
         TMP2_STOKES_U(BINNO) = UTEMP
         TMP2_STOKES_QV(BINNO) = QVTEMP
         TMP2_STOKES_UV(BINNO) = UVTEMP
         TMP2_STOKES_I(BINNO) = ITEMP
         FPE=FPE+1
        ENDIF
C
C Adds normalized Stokes parameters
C
       ELSE IF (SYMB.EQ.'+') THEN
        IF (STOKES_I(I).NE.0.) THEN
         TMP2_STOKES_Q(BINNO) = QTEMP+ITEMP*(STOKES_Q(I)/STOKES_I(I))
         TMP2_STOKES_U(BINNO) = UTEMP+ITEMP*(STOKES_U(I)/STOKES_I(I))
         TMP2_STOKES_QV(BINNO) = QVTEMP+
     &                   (ITEMP**2)*(STOKES_QV(I)/STOKES_I(I)**2)
         TMP2_STOKES_UV(BINNO) = UVTEMP+
     &                   (ITEMP**2)*(STOKES_UV(I)/STOKES_I(I)**2)
         TMP2_STOKES_I(BINNO) = ITEMP
        ELSE
         TMP2_STOKES_Q(BINNO) = QTEMP
         TMP2_STOKES_U(BINNO) = UTEMP
         TMP2_STOKES_QV(BINNO) = QVTEMP
         TMP2_STOKES_UV(BINNO) = UVTEMP
         TMP2_STOKES_I(BINNO) = ITEMP
         FPE=FPE+1
        ENDIF
C
C Divides the Stokes I's keeping the polarization information
C
       ELSE IF (SYMB.EQ.'I') THEN
         IF (STOKES_I(I).NE.0.) THEN
          RECT_I = ITEMP/STOKES_I(I)
          TMP2_STOKES_Q(BINNO) = QTEMP/ITEMP*RECT_I
          TMP2_STOKES_U(BINNO) = UTEMP/ITEMP*RECT_I
          TMP2_STOKES_QV(BINNO) = (QVTEMP/ITEMP**2)*RECT_I**2
          TMP2_STOKES_UV(BINNO) = (UVTEMP/ITEMP**2)*RECT_I**2
          TMP2_STOKES_I(BINNO) = RECT_I
         ELSE
          TMP2_STOKES_Q(BINNO) = 0.
          TMP2_STOKES_U(BINNO) = 0.
          TMP2_STOKES_QV(BINNO) = 0.
          TMP2_STOKES_UV(BINNO) = 0.
          TMP2_STOKES_I(BINNO) = 0.
          FPE=FPE+1
         ENDIF
C
C Performs a direct subtraction of Stokes parameters
C
        ELSE IF (SYMB.EQ.'C') THEN
         TMP2_STOKES_Q(BINNO) = QTEMP-STOKES_Q(I)
         TMP2_STOKES_U(BINNO) = UTEMP-STOKES_U(I)
         TMP2_STOKES_I(BINNO) = ITEMP-STOKES_I(I)
         IF (ITEMP.LT.0.) THEN
          TMP2_STOKES_Q(BINNO) = -TMP2_STOKES_Q(BINNO)
          TMP2_STOKES_U(BINNO) = -TMP2_STOKES_U(BINNO)
          TMP2_STOKES_I(BINNO) = -TMP2_STOKES_I(BINNO)
         ENDIF
         TMP2_STOKES_QV(BINNO) = QVTEMP+STOKES_QV(I)
         TMP2_STOKES_UV(BINNO) = UVTEMP+STOKES_UV(I)
         IF ( (TMP2_STOKES_Q(BINNO)**2+TMP_STOKES_U(BINNO)**2)
     &        .GT.TMP2_STOKES_I(BINNO)**2 ) BINNO = BINNO-1
C
C Performs a direct addition of Stokes parameters
C
        ELSE IF (SYMB.EQ.'A') THEN
         TMP2_STOKES_Q(BINNO) = QTEMP+STOKES_Q(I)
         TMP2_STOKES_U(BINNO) = UTEMP+STOKES_U(I)
         TMP2_STOKES_I(BINNO) = ITEMP+STOKES_I(I)
         TMP2_STOKES_QV(BINNO) = QVTEMP+STOKES_QV(I)
         TMP2_STOKES_UV(BINNO) = UVTEMP+STOKES_UV(I)
       ENDIF
       TMP2_LAMBDA(BINNO) = LAMBDA(I)
       I = I+1
       BINNO = BINNO+1
      ENDIF
      ENDDO
      NPTS = BINNO-1
C
C Put the result in the current arrays
C
      DO I = 1,NPTS
       STOKES_I(I) = TMP2_STOKES_I(I)
       STOKES_Q(I) = TMP2_STOKES_Q(I)
       STOKES_QV(I) = TMP2_STOKES_QV(I)
       STOKES_U(I) = TMP2_STOKES_U(I)
       STOKES_UV(I) = TMP2_STOKES_UV(I)
       LAMBDA(I) = TMP2_LAMBDA(I)
      ENDDO
      IF (FPE.GT.0) THEN
       WRITE(OUT_LU,*) '!',FPE,' divide by zeros trapped'
      ENDIF
C      
666   CONTINUE
      END
