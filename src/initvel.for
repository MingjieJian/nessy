      module MOD_INITVEL

      contains

      SUBROUTINE INITVEL(RMAX, TEFF, GLOG, RSTAR, XMASS)
      

C***  INITIALIZATION OF THE VELOCITY-FIELD PARAMETERS

      use MOD_REGULA

      IMPLICIT REAL*8(A-H,O-Z)

      PARAMETER ( ONE = 1.D+0, TWO = 2.D+0 )
      
      COMMON/VELPAR/ VFINAL,VMIN,BETA,VPAR1,VPAR2,RCON,HSCALE
      COMMON/VELPA1/ RMA

C***  BOLTZMANN CONSTANT (ERG/DEG)
      DATA  BOLTZ/ 1.380622D-16  /
C***  ATOMIC MASS UNIT (GRAMM)
      DATA  AMU/ 1.660531D-24/

      RMA=RMAX

      IF (BETA.LE..0) THEN
            WRITE (6,'(A)') 'BETA OPTION INVALID'
            STOP 'ERROR'
            ENDIF

C***  CONVERSION OF VELOCITY-FIELD PARAMETERS (ANALYTIC LAW)
      Q=(VMIN/VFINAL)**(ONE/BETA)
      VPAR2=(ONE-Q)/(ONE-Q/RMAX)
      VPAR1=VMIN/(ONE-VPAR2)**BETA

C***  DETERMINATION OF THE SCALE HEIGHT (HYDROSTATIC EQ.)
C***  XMASS= MEAN MASS IN AMU ( 2. FOR HE II, 1.33 FOR HE III )
      HSCALE=BOLTZ*TEFF/XMASS/AMU/RSTAR/10.**GLOG

C***  ITERATIVE DETERMINATION OF THE CONNECTION POINT RCON
C***  BY REQUIRING A CONTINUOUS AND SMOOTH CONNECTION

      RCON=ONE
C***  BRANCH IF AT THE INNER BOUNDARY THE EXPONENTIAL LAW GRADIENT
C***  EXCEEDS ALREADY THE BETA-LAW GRADIENT
      IF (DELTAGR(ONE) .LT. .0) THEN
            WRITE (6,'(A)') 'INITVEL: NO HYDROSTATIC DOMAIN ENCOUNTERED'

            RETURN
            ENDIF

C***  LOWER GUESS FOR RCON
      RCON1=ONE
      WRITE (6,111) VPAR1,VPAR2,RCON,HSCALE
 176  RCONMIN=DMAX1(RCON1,VPAR2+1.D-10)
      IF (RCONMIN.GT.RMAX) THEN
         RCON=RMAX
         DEL=DELTAGR(RCON)
         WRITE (6,111) VPAR1,VPAR2,RCON,DEL
         RETURN
         ENDIF
      IF (DELTAGR(RCONMIN) .LT. .0) THEN

            RCON1=RCON1+HSCALE
            GOTO 176

            ENDIF

C***  UPPER GUESS FOR RCON
      RCONMAX=RCONMIN
    2 RCONMAX=RCONMAX+HSCALE
      IF (RCONMAX .GE. RMAX) THEN
            RCON=RMAX
            WRITE (6,*) 'INITVEL: NO BETA-LAW DOMAIN ENCOUNTERED'
            RCON=2.8D0
            DELVEL=DELTAGR(RCON)
            WRITE (6,111) VPAR1,VPAR2,RCON,DELVEL
            RETURN
            ENDIF

      IF (DELTAGR(RCONMAX) .GE. .0) GOTO 2
      RCONMIN=RCONMAX-HSCALE

    1 RCONOLD=RCON
      EPS=1.D-6
      CALL REGULA (DELTAGR,RCON,.0,RCONMIN,RCONMAX,EPS)
C***  RE-ADJUST THE BETA-LAW PARAMETERS SUCH THAT BOTH VELOCITIES AGREE
C***  AT THE CONNECTION POINT
      IF (ABS(RCON-RCONOLD) .GT. 1.D-5) GOTO 1

      WRITE (6,111) VPAR1,VPAR2,RCON,HSCALE
111   FORMAT (/,' INITVEL: VPAR1,VPAR2,RCON,HSCALE= ',/,4E12.5/)

      RETURN

      END subroutine

      FUNCTION DELTAGR(R)
C***  DIFFERENCE OF VELOCITY GRADIENTS FROM BOTH VELOCITY LAWS:
C***  THE BETA LAW (OUTER REGION) AND THE EXPONENTIAL LAW (INNER REGION)
C***  THIS ROUTINE SERVES FOR ESTIMATING THE CONNECTION POINT BETWEEN BOTH
C***  REGIONS AND IS CALLED FROM SUBROUTINE INITVEL, MAIN PROGRAM WRSTART

      IMPLICIT REAL*8(A-H,O-Z)
     
      PARAMETER ( ONE = 1.D+0, TWO = 2.D+0 )
      
      COMMON/VELPAR/ VFINAL,VMIN,BETA,VPAR1,VPAR2,RCON,HSCALE
      COMMON/VELPA1/ RMA
     
C***  ASSUMING THAT R IS THE CONECTION RADIUS
      VCON=VMIN/R/R*EXP((ONE-ONE/R)/HSCALE)
      Q=(VCON/VFINAL)**(ONE/BETA)
      VPAR2=(ONE-Q)/(ONE/R - Q/RMA)
      VPAR1=VCON/(ONE-VPAR2/R)**BETA
      DELTAGR=VPAR1*VPAR2*BETA*(ONE-VPAR2/R)**(BETA-ONE)/R/R -
     -        VMIN/R/R*EXP((ONE-ONE/R)/HSCALE)*(ONE/R/R/HSCALE-TWO/R)
      RETURN

      END function

      end module
