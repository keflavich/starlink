C SUBROUTINE REALFT FOR THE FOURIER TRANSFORM OF A SINGLE REAL
C ARRAY.  FROM NUMERICAL RECIPES.
      SUBROUTINE TIM_REALFT(DATA,N,ISIGN)
C CALCULATES FOURIER TRANSFORM OF A SET OF 2N REAL-VALUED DATA
C POINTS.  REPLACES THIS DATA (STORED IN ARRAY "DATA") BY THE
C POSITIVE FREQUENCY HALF OF ITS COMPLEX FOURIER TRANSFORM.
C THE REAL-VALUED FIRST AND LAST COMPONENTS OF THE COMPLEX
C TRANSFORM ARE RETURNED AS ELEMENTS DATA(1) AND DATA(2) RESPECTIVELY.
C N MUST BE A POWER OF 2.  THIS ROUTINE ALSO CALCULATES THE INVERSE
C TRANSFORM OF A COMPLEX DATA ARRAY IF IT IS THE TRANSFORM OF REAL DATA.
C (RESULT MUST BE MULTIPLIED BY 1/N IN THIS CASE).
C
      REAL*8 WR,WI,WPR,WPI,WTEMP,THETA
      DIMENSION DATA(2*N+2)
C INITIALIZE TRIG. RECURRENCE IN D.P.
      THETA=6.28318530717959D0/2.0D0/DFLOAT(N)
      WR=1.0D0
      WI=0.0D0
      C1=0.5
      IF(ISIGN.EQ.1)THEN
         C2=-0.5
C DO FORWARD TRANSFORM...
         CALL TIM_FOUR1(DATA,N,+1)
         DATA(2*N+1)=DATA(1)
         DATA(2*N+2)=DATA(2)
      ELSE
C ...OTHERWISE SET UP FOR INVERSE TRANSFORM.
         C2=0.5
         THETA=-THETA
         DATA(2*N+1)=DATA(2)
         DATA(2*N+2)=0.0
         DATA(2)=0.0
      ENDIF
      WPR=-2.0D0*DSIN(0.5D0*THETA)**2
      WPI=DSIN(THETA)
      N2P3=2*N+3
      DO 11 I=1,N/2+1
        I1=2*I-1
        I2=I1+1
        I3=N2P3-I2
        I4=I3+1
        WRS=SNGL(WR)
        WIS=SNGL(WI)
C SEPARATE THE TRANSFORMS OUT OF COMPLEX FORM...
        H1R=C1*(DATA(I1)+DATA(I3))
        H1I=C1*(DATA(I2)-DATA(I4))
        H2R=-C2*(DATA(I2)+DATA(I4))
        H2I=C2*(DATA(I1)-DATA(I3))
C ...AND RECOMBINE THEN TO GET THE TRUE TRANSFORM OF THE DATA.
        DATA(I1)=H1R+WRS*H2R-WIS*H2I
        DATA(I2)=H1I+WRS*H2I+WIS*H2R
        DATA(I3)=H1R-WRS*H2R+WIS*H2I
        DATA(I4)=-H1I+WRS*H2I+WIS*H2R
C TRIG. RECURRENCE...
        WTEMP=WR
        WR=WR*WPR-WI*WPI+WR
        WI=WI*WPR+WTEMP*WPI+WI
11    CONTINUE
C SQUEEZE FIRST AND LAST DATA TOGETHER TO GET THEM ALL WITHIN
C ORIGINAL ARRAY...
      IF(ISIGN.EQ.1)THEN
       DATA(2)=DATA(2*N+1)
      ELSE
C INVERSE TRANSFORM CASE...
       CALL TIM_FOUR1(DATA,N,-1)
      ENDIF
      RETURN
      END
