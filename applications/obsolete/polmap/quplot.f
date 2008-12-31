      SUBROUTINE QUPLOT(NPARAMS,PARAMS,TITLE,QUJOIN_DOTS,
     &IT,Q,U,QV,UV,
     &WAVE,NPTS,BOX,QMAX,QMIN,UMAX,UMIN,QAUTOLIM,UAUTOLIM,
     &WMAX,WMIN,WAUTOLIM,LCOL,LSTYLE,CROT,PSTYLE,QUARROW,ARROWSIZE,
     &OUT_LU)
C+
C
C Subroutine: 
C
C      Q U P L O T
C
C
C Author: Tim Harries (tjh@st-and.ac.uk)
C
C Parameters: 
C
C NPARAMS (<), PARAMS (<), TITLE (<), QUJOIN_DOTS (<),
C IT (<), Q (<), U (<), QV (<), UV (<),
C WAVE (<), NPTS (<), BOX (<), QMAX (<), QMIN (<), UMAX (<), UMIN (<),
C QAUTOLIM (<), UAUTOLIM (<),
C WMAX (<), WMIN (<), WAUTOLIM (<), LCOL (<), LSTYLE (<), CROT (<),
C PSTYLE (<), QUARROW (<),ARROWSIZE (<), OUT_LU (<)
C
C
C History: 
C  
C   May 1994 Created
C 
C
C
C Plots a polarization spectrum in QU-plane
C
C
C
C
C
C-
      IMPLICIT NONE
      INTEGER OUT_LU
      INCLUDE 'array_size.inc'
      REAL QRANGE,URANGE,RANGE,MID,ARROWSIZE
      INTEGER NPTS
      INTEGER NEW_NPTS
      INTEGER NPARAMS
      REAL XMID,YMID,XDIR,YDIR,XCH,YCH,DIST
      REAL PARAMS(*)
      REAL IT(*)
      REAL IT_T(MAXPTS)
      REAL Q(*)
      REAL U(*)
      REAL QV(*)
      REAL UV(*)
C
C
C
C
      REAL WMAX
      REAL WMIN
C
      LOGICAL QUARROW
      INTEGER LCOL,LSTYLE,PSTYLE
      REAL BIN_ERR
      REAL WAVE(*)
C
C
C
C
C
C
C
C
C
      REAL NEW_I(MAXPTS)
      REAL NEW_Q(MAXPTS)
      REAL NEW_QV(MAXPTS)
      REAL NEW_U(MAXPTS)
      REAL NEW_UV(MAXPTS)
      REAL NEW_LAMBDA(MAXPTS)
C
      REAL TMP_Q(MAXPTS)
      REAL TMP_QV(MAXPTS)
      REAL TMP_U(MAXPTS)
      REAL TMP_UV(MAXPTS)
      REAL QMAX
      REAL QMIN
      REAL UMAX
      REAL UMIN
      REAL HTEMP
      INTEGER I,TMP_NPTS
C
      INTEGER WS,WE
      CHARACTER*80 TITLE
      LOGICAL BOX,CROT,OK
      LOGICAL QUJOIN_DOTS
      LOGICAL WAUTOLIM,QAUTOLIM,UAUTOLIM
C
C
      CALL PGQCH(HTEMP)
C
      IF (NPARAMS.EQ.0) THEN
       CALL GET_PARAM('Bin error',PARAMS(1),OK,OUT_LU)
       IF (.NOT.OK) GOTO 666
      ENDIF
C
      BIN_ERR = PARAMS(1)
C
      IF (NPTS.EQ.0) THEN
       CALL WR_ERROR('Current arrays are empty',OUT_LU)
       GOTO 666
      ENDIF
      CALL TRI_CONST_BIN(
     &   BIN_ERR,WAVE,
     &   IT,Q,QV,
     &   U,UV,NPTS,NEW_I,IT_T,NEW_Q,
     &   NEW_QV,NEW_U,NEW_UV,NEW_LAMBDA,NEW_NPTS)

      IF (WAUTOLIM) THEN
         WS = 1
         WE = NEW_NPTS
        ELSE
         IF (WMIN.LT.NEW_LAMBDA(1)) THEN
          WS = 1
         ELSE
          CALL LOCATE(NEW_LAMBDA,NEW_NPTS,WMIN,WS)
        ENDIF
        IF (WMAX.GT.NEW_LAMBDA(NEW_NPTS)) THEN
          WE = NEW_NPTS
         ELSE
          CALL LOCATE(NEW_LAMBDA,NEW_NPTS,WMAX,WE)
         ENDIF
      ENDIF
      TMP_NPTS = 0
      DO I = WS,WE
       TMP_NPTS = TMP_NPTS+1
       TMP_Q(TMP_NPTS) = 100.*NEW_Q(I)/NEW_I(I)
       TMP_U(TMP_NPTS) = 100.*NEW_U(I)/NEW_I(I)
       TMP_QV(TMP_NPTS) = 1.e4*NEW_QV(I)/NEW_I(I)**2
       TMP_UV(TMP_NPTS) = 1.e4*NEW_UV(I)/NEW_I(I)**2
      ENDDO
      IF (QAUTOLIM.AND.BOX) THEN
      QMIN = 1.E30
      QMAX = -1.E30
      DO I = 1,TMP_NPTS
       QMAX = MAX(TMP_Q(I)+SQRT(TMP_QV(I)),QMAX)
       QMIN = MIN(TMP_Q(I)-SQRT(TMP_QV(I)),QMIN)
      ENDDO
C      QMAX = QMAX+0.1*QRANGE
C      QMIN = QMIN-0.1*QRANGE
      ENDIF
      IF (UAUTOLIM.AND.BOX) THEN
      UMIN = 1.E30
      UMAX = -1.E30
      DO I = 1,TMP_NPTS
       UMAX = MAX(TMP_U(I)+SQRT(TMP_UV(I)),UMAX)
       UMIN = MIN(TMP_U(I)-SQRT(TMP_UV(I)),UMIN)
      ENDDO
C      UMAX = UMAX+0.1*URANGE
C      UMIN = UMIN-0.1*URANGE
      ENDIF
      QRANGE=QMAX-QMIN
      URANGE=UMAX-UMIN
      RANGE=MAX(QRANGE,URANGE)
      RANGE=RANGE*1.2
      IF (QRANGE.GT.URANGE) THEN
       MID = (UMAX+UMIN)/2.
       UMIN = MID - RANGE/2.
       UMAX = MID + RANGE/2.
       QMIN = QMIN-0.1*RANGE
       QMAX = QMIN + RANGE
      ELSE
       MID = (QMAX+QMIN)/2.
       QMIN = MID - RANGE/2.
       QMAX = MID + RANGE/2.
       UMIN = UMIN-0.1*RANGE
       UMAX = UMIN + RANGE
      ENDIF
C
      IF ((.NOT.BOX).AND.CROT) THEN
        CALL PGQCI(LCOL)
        LCOL = MAX(1,MOD(LCOL+1,6))
      ENDIF
      IF (BOX) THEN
C
       CALL PGVPORT(0.1,0.9,0.1,0.9)
       LCOL=1
       CALL PGWNAD(QMIN,QMAX,UMIN,UMAX)
       CALL PGSLS(1)
       CALL PGSCI(1)
       CALL PGPAGE
       CALL PGBOX('NBCST',0.0,0.0,'NBCST',0.0,0.0)  
       CALL PGLABEL('Stokes Q (%)','Stokes U (%)',TITLE)
      ENDIF
C
      CALL PGSCI(LCOL)
      CALL PGSLS(1)
      CALL PGPOINT(TMP_NPTS,TMP_Q,TMP_U,PSTYLE)
      DO I = 1,TMP_NPTS
       CALL PGERRX(1,TMP_Q(I)+SQRT(TMP_QV(I)),
     &             TMP_Q(I)-SQRT(TMP_QV(I)),TMP_U(I),1.)
       CALL PGERRY (1,TMP_Q(I),TMP_U(I)+SQRT(TMP_UV(I)),
     &             TMP_U(I)-SQRT(TMP_UV(I)),1.)
 
      ENDDO
      IF (QUJOIN_DOTS) THEN
       CALL PGSLS(LSTYLE)
       CALL PGLINE(TMP_NPTS,TMP_Q,TMP_U)
      ENDIF
      IF (QUARROW) THEN
       CALL PGSCH(ARROWSIZE)
       DO I=1,TMP_NPTS-1
        XMID=0.5*(TMP_Q(I)+TMP_Q(I+1))
        YMID=0.5*(TMP_U(I)+TMP_U(I+1))
        XDIR=(TMP_Q(I+1)-TMP_Q(I))
        YDIR=(TMP_U(I+1)-TMP_U(I))
        DIST=SQRT(XDIR**2+YDIR**2)
        IF (DIST.GT.0.) THEN
        XDIR=XDIR/DIST
        YDIR=YDIR/DIST
         ELSE
        XDIR=0.
        YDIR=0.
        ENDIF
        CALL PGQCS(0,XCH,YCH)
        XMID=XMID+XCH*XDIR/2.
        YMID=YMID+YCH*YDIR/2.
        IF ((XDIR.NE.0.).AND.(YDIR.NE.0.)) THEN
         CALL PGARRO(XMID,YMID,XMID+XDIR/1.E5,YMID+YDIR/1.E5)
        ENDIF
       ENDDO
       CALL PGSCH(HTEMP)
       ENDIF
666   CONTINUE
      END
