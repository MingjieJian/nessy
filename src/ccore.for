      module MOD_CCORE

      contains

      SUBROUTINE CCORE(NF,MODHEAD,JOBNUM,
     $                 SCOLD,RADIUS,XLAMBDA,ND,T,RNE,POP1,ENTOT,RSTAR,
     $                 IWARN,MAINPRO,MAINLEV,NOM,
     $                 N,LEVEL,NCHARG,WEIGHT,ELEVEL,EION,EINST,SIGMAKI,
     $                 WAVARR,SIGARR)

C***  THE CONT. SOURCE FUNCTION IS CALCULATED FROM OLD POP.NUMBERS (=SCOLD)

      use MOD_COOP

      implicit none

      ! GLOBAL Variables intent(out)
      integer,intent(in) :: JOBNUM
      integer :: N
      integer :: NOM(N)
      integer :: ND, NF	! Number of depth- & frequency-points
	
      integer :: XLBKG1, XLBKG2

	! gobal variables, intent(inout)  (inout because of subprocedures)
      real*8,dimension(ND) :: OPA,ETA,THOMSON
      real*8,dimension(ND) :: RADIUS  ! = [1+delta, ... ,1] given in relative solar units
	
      character,dimension(*) :: MAINPRO*10, MAINLEV*10, LEVEL*10
      real*8,dimension(NF,ND) :: SCOLD

	!global variables, intent(in)
      character::MODHEAD*104
      real*8,dimension(N,NF) :: WAVARR, SIGARR
      real*8,dimension(NF)    :: XLAMBDA ! Array of Wavelength
      logical :: LBKG
      real*8 ::  RSTAR
	
	! local variables
      real*8 :: OPAL	! OPAL =(OPA*(1-THOMSON))(L)
      real*8 :: XLAM   			! wavelength at point k(@see XLAMBDA)
      real*8,allocatable :: DUMMY1(:)
      character*8,allocatable :: CDUMMY1(:)
      integer :: K, L			! loop variables

! micha: added dimensions for modules
      integer, dimension(*) :: NCHARG, IWARN
      real*8, dimension(*)  :: T, RNE, POP1, ENTOT,WEIGHT,ELEVEL,EION
      real*8, dimension(*)  :: EINST,SIGMAKI
     
C***  LOOP OVER ALL CONTINUUM FREQUENCIES
      DO K = 1, NF

        XLAM = XLAMBDA(K)

        CALL COOP(XLAM,ND,T,RNE,POP1,ENTOT,RSTAR,
     $            OPA,ETA,THOMSON,IWARN,MAINPRO,MAINLEV,NOM,
     $	          N,LEVEL,NCHARG,WEIGHT,ELEVEL,EION,EINST,
     $	          DUMMY1,DUMMY1,CDUMMY1,K,
     $            SIGMAKI,WAVARR(1 : N, 1 : NF),
     $            SIGARR(1 : N, 1 : NF),NF)

C***  SOURCE FUNCTION WITH OLD POP.NUMBERS (WITHOUT THOMSON OPACITY)
	  DO L=1,ND
C***  LASER SECURITY - if medium acts as a laser reset it
	    OPAL=OPA(L)*(1d0-THOMSON(L))
	    IF (OPAL .GT. 0d0) THEN
	      SCOLD(K,L)=ETA(L)/OPAL
	    ELSE
	      SCOLD(K,L)=.0d0
	    ENDIF
	  ENDDO
      ENDDO
      
      RETURN

      END subroutine

      end module
