      module MOD_FGRID

      contains

      SUBROUTINE FGRID(NFDIM,NF,XLAMBDA,FWEIGHT,AKEY,NOM,SYMBOL,NATOM,N,NCHARG,ELEVEL,EION,EINST)

      use MOD_DECFREQ, only: DECFREQ
      use MOD_SEQUIN,  only: SEQUIN,SEQUINE
      use CONSTANTS,   only: CLIGHT_SI

      use phys

C***  GENERATION OF THE FREQUENCY GRID AND INTEGRATION WEIGHTS
C***  INCLUDING PREDEFINED FREQUENCY POINTS (FROM TAPE6)
C***  AND THE CONTINUUM FREQUENCY POINTS (NO LINE FREQUENCY POINTS)
C***  XLAMBDA = CORRESPONDING WAVELENGTH POINTS IN ANGSTROEMS

      IMPLICIT REAL*8(A-H,O-Z)

      real*8, intent(out), dimension(NFDIM) :: AKEY,XLAMBDA,FWEIGHT
      integer,intent(out) ::                   NF

      integer,intent(in) :: NFDIM, NOM, NATOM, N, NCHARG(N)
      real*8, intent(in) :: ELEVEL(N), EION(N), EINST(N, N)

      DIMENSION NOM(N)
      CHARACTER*2,intent(in):: SYMBOL(NATOM)
      PARAMETER (ONE=1.d0, TWO=2.d0)   
C***  STEBOL = STEFAN-BOLTZMANN CONSTANT / PI  (ERG/CM**2/S/STERAD/KELVIN**4)
      DATA STEBOL / 1.8046D-5 /
C***  CLIGHT = SPEED OF LIGHT IN ANGSTROEM / SECOND IN VACUUM
      real*8,parameter :: CLIGHT = CLIGHT_SI*1d10
      real*8 :: NEDGE  ! micha: NEDGE should be a real...
      PRINT 9
    9 FORMAT(//,20X,'2. FREQUENCY POINTS AND INTEGRATION WEIGHTS',/) 

C***  DECODE THE FREQUENCY GRID (WAVELENGTHS IN A) FROM TAPE6 = FGRID
      CALL DECFREQ(XLAMBDA, NF, NFDIM, TREF)

C***  SET KEYWORD ARRAY TO BLANKS
      DO 23 K=1,NF
   23 AKEY(K)=8H          
C***  ADDITION OF THE REDMOST LINE FREQUENCY POINT
     
C***  FIND THE REDMOST LINE CENTER FREQUENCY POINT
      IF (XLAMBDA(NF) .GT. XLAMBDA(1)) THEN
          REDMOST=XLAMBDA(NF)
      ELSE
          REDMOST=XLAMBDA(1)
      ENDIF
      IND=0
      INDRED=0
      DO 25 J=2,N
      JM=J-1
      DO 25 I=1,JM
      IF ((NOM(J) .NE. NOM(I)) .OR. (NCHARG(J) .NE. NCHARG(I))) GOTO 25
      IND=IND+1
      WLENG=1.D8/(ELEVEL(J)-ELEVEL(I))
      IF (WLENG .GT. REDMOST) THEN
          REDMOST=WLENG
          INDRED=IND
          IRED=I
          JRED=J
      ENDIF
   25 CONTINUE
      IF (INDRED.GT.0) THEN
      IND=INDRED
      WLENG=REDMOST
      CALL SEQUIN(NFDIM,NF,XLAMBDA,K,WLENG)
      ENCODE (7,22,ANAME) 'LINE',IND
   22 FORMAT (A4,I3)
      IF (EINST(IRED,JRED) .EQ. -2.) ANAME=7HRUDLINE
      NFM=NF-1
      IF (K.GT.0) CALL SEQUINE(NFDIM, NFM, AKEY, K, ANAME)
      IF (K.LT.0) AKEY(-K)=ANAME
      ENDIF
     
C***  ONLY INSERTION OF CONTINUUM EDGES
   30 DO 19 J=2,N
      JM=J-1
      DO 19 I=1,JM
      IF((NOM(I) .NE. NOM(J)) .OR. (NCHARG(I)+1 .NE. NCHARG(J))) GOTO 19
      WLENG=1.D8/(EION(I)-ELEVEL(I))
C***  IF YOU CHANGE THE 1.001 THEN CHANGE ALSO THE TEST VALUE IN SEQUIN
      !WPLUS=1.001*WLENG
      WPLUS=1.00001*WLENG
c     WPLUS=1.02*WLENG
      IF (WPLUS.LT.1.7D+4) THEN
C***  INSERT A LONGWAVELENGTH POINT ONLY IF THE WAVELENGTH IS SHORTER THAN 1.7MU
         CALL SEQUIN(NFDIM,NF,XLAMBDA,K,WPLUS)
         ENCODE(7,17,NEDGE) 'EDGE+',SYMBOL(NOM(I))
   17    FORMAT (A5,A2)
         NFM=NF-1
         IF (K.GT.0) CALL SEQUINE(NFDIM, NFM, AKEY, K, NEDGE)
         ENDIF
      !WMINUS=0.999*WLENG
      WMINUS=0.9999*WLENG
      CALL SEQUIN(NFDIM,NF,XLAMBDA,K,WMINUS)
      ENCODE(7,17,NEDGE) 'EDGE-',SYMBOL(NOM(I))
      NFM=NF-1
      IF (K.GT.0) CALL SEQUINE(NFDIM, NFM, AKEY, K, NEDGE)
   19 CONTINUE
     
C***  FREQUENCY INTEGRATION WEIGHTS ACCORDING TO THE TRAPEZOIDAL RULE **********
      NFM=NF-1
      DO 2 K=2,NFM
      WAVEM=ONE/XLAMBDA(K-1)
      WAVEP=ONE/XLAMBDA(K+1)
      FWEIGHT(K)=(WAVEM - WAVEP)*CLIGHT/TWO
   !   print *, FWEIGHT(K)
    2 CONTINUE
      FWEIGHT(1)=(ONE/XLAMBDA(1) - ONE/XLAMBDA(2))*CLIGHT/TWO
      FWEIGHT(NF)=(ONE/XLAMBDA(NFM) - ONE/XLAMBDA(NF))*CLIGHT/TWO
     
C***  RENORMALIZATION TO RETAIN THE EXACT INTEGRAL SUM OF PLANCKS FUNCTION
C***   AT REFERENCE TEMPERATURE TREF
      SUM=.0D0
      DO 3 K=1,NF
    3 SUM=SUM+FWEIGHT(K)*BNUE(XLAMBDA(K),TREF)
      BTOT =STEBOL*TREF*TREF*TREF*TREF
      RENORM=BTOT/SUM
      DO 4 K=1,NF
      FWEIGHT(K)=FWEIGHT(K)*RENORM
!      print *, FWEIGHT(K)      
    4 CONTINUE     

      PRINT 18
   18 FORMAT(//,1X,
     $' NR   LAMBDA/ANGSTROEM    KEY     WAVENUMBER(KAYSER)  ',
     $' FREQUENCY(HERTZ)        WEIGHT    REL.INTEGRAL CONTRIBUTION',/)
      DO K=1,NF
      XLAM=XLAMBDA(K)
      RELCO=NF*FWEIGHT(K)*BNUE(XLAM,TREF)/BTOT
!***  BELOW 2000 A THE WAVELENGTH IS GIVEN WITH RESPECT TO SPEED OF LIGHT IN VACUUM
!***  ABOVE 2000 A WITH RESPECT TO SPEED OF LIGHT IN AIR
!***  THE REFRACTIVE INDEX OF AIR IS 1.0003 
!      IF (XLAM .LE. 2000) THEN
!        PRINT 12,K,XLAM,AKEY(K),1.D8/XLAM,CLIGHT/XLAM,FWEIGHT(K),RELCO
!      ELSE
!        PRINT 12,K,XLAM*1.0003,AKEY(K),1.D8/XLAM,CLIGHT/XLAM,
!     $             FWEIGHT(K),RELCO
!        ENDIF
       ENDDO

   12 FORMAT(1X,I4,F15.2,2X,A7,2X,F15.2,2E22.6,F15.3)
      PRINT 10,RENORM,TREF
   10 FORMAT(//,' RENORMALIZATION FACTOR :',F10.6,
     $ '     REFERENCE TEMPERATURE :',F8.0,' K')

      return

      end subroutine

      end module
