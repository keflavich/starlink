      INTEGER FUNCTION MDH_CTOI( CVAL )
      CHARACTER*(*) CVAL
      INTEGER MDH_ENDWORD
      READ( CVAL( :MDH_ENDWORD( CVAL ) ) , '( I )' ) MDH_CTOI
      END
