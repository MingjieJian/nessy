      module MOMENTS

      contains

      SUBROUTINE MOMENT0_ELIMIN(ND, R, L, JMAX, Z, XJ, XJMEAN)

C***  INTEGRATION OF THE ZERO-MOMENT OF THE RADIATION FIELD (MEAN INTENSITY)
C***   IF ( MODE = .TRUE.    ) THE INTEGRATION WEIGHTS ARE GENERATED (VECTOR XJ)
C***   ELSE : XJ IS CONSIDERED AS ANGLE-DEPENDENT INTENSITY AND THE
C***          INTEGRATION IS PERFORMED ( RESULT XJMEAN)
C***  RADIUS-MESH R, ACTUAL INDEX L, AND Z-MESH Z(L,J) ARE GIVEN
C***  WEIGHTS ARE ACCORDING TO TRAPEZOIDAL RULE IN Z=SQRT(R*R-P*P)
CMH	INTEGRATION WEIGHTS XJ = DZ/2/R IN "\MU" UNITS

      implicit real*8(a - h, o - z)

      real*8, intent(in) :: R(ND), Z(ND, JMAX), XJ(JMAX)

      real*8, intent(out) :: XJMEAN

      RL2 = 2d0 * R(L)

C***  FIRST STEP
      ZJ = Z(L, 1)
      ZNEXT = Z(L, 2)

      XJMEAN = (ZJ - ZNEXT) * XJ(1)

!      write(*, '(A,2(2x,i4),4(2x,e15.7))'), 'moment0, check 1:', L, 1, zj, znext, xj(1), xjmean

C***  MIDDLE STEPS
      DO J = 3, JMAX

         ZLAST = ZJ
         ZJ = ZNEXT
         ZNEXT = Z(L, J)

         XJMEAN = XJMEAN + XJ(J - 1) * (ZLAST - ZNEXT)

!         write(*, '(A,2(2x,i4),4(2x,e15.7))'), 'moment0, check 2:', L, j - 1, zlast, znext, xj(j - 1), xjmean

      ENDDO

C***  LAST STEP, IMPLYING Z(L,JMAX)=.0
      XJMEAN=XJMEAN+XJ(JMAX)*ZJ
      XJMEAN=XJMEAN/RL2

!      write(*, '(A,2(2x,i4),4(2x,e15.7))'), 'moment0, check 3:', L, jmax, zj, rl2, xj(jmax), xjmean

      end subroutine

      SUBROUTINE MOMENT0_SETUP(ND, R, L, JMAX, Z, XJ)

C***  INTEGRATION OF THE ZERO-MOMENT OF THE RADIATION FIELD (MEAN INTENSITY)
C***   IF ( MODE = .TRUE.    ) THE INTEGRATION WEIGHTS ARE GENERATED (VECTOR XJ)
C***   ELSE : XJ IS CONSIDERED AS ANGLE-DEPENDENT INTENSITY AND THE
C***          INTEGRATION IS PERFORMED ( RESULT XJMEAN)
C***  RADIUS-MESH R, ACTUAL INDEX L, AND Z-MESH Z(L,J) ARE GIVEN
C***  WEIGHTS ARE ACCORDING TO TRAPEZOIDAL RULE IN Z=SQRT(R*R-P*P)
CMH	INTEGRATION WEIGHTS XJ = DZ/2/R IN "\MU" UNITS

      implicit real*8(a - h, o - z)

      real*8, intent(in) ::  R(ND), Z(ND, JMAX)

      real*8, intent(out) :: XJ(JMAX)

      RL2 = 2d0 * R(L)

C***  FIRST STEP
      ZJ = Z(L, 1)
      ZNEXT = Z(L, 2)

      XJ(1) = (ZJ - ZNEXT) / RL2

!     print*, 'moment0, check 1:', zj, znext, xj(1), xjmean

C***  MIDDLE STEPS
      DO J = 3, JMAX

         ZLAST = ZJ
         ZJ = ZNEXT
         ZNEXT = Z(L, J)

         XJ(J-1)=(ZLAST-ZNEXT)/RL2

!        print*, 'moment0, check 2:', xjmean

      ENDDO

C***  LAST STEP, IMPLYING Z(L,JMAX)=.0
      XJ(JMAX) = ZJ / RL2

!     print*, 'moment0, check 3:', xjmean

      end subroutine

      SUBROUTINE MOMENT1(R, NP, P, U, H)
C***  CALCULATES AN ANGLE INTEGRAL H OF THE RADIATION FIELD U
C***  BESIDES OF THE OUTER BOUNDARY, THIS IS NOT THE 1. MOMENT H,
C***  BUT RATHER AN INTENSITY-LIKE QUANTITY
C***  INTEGRATION WITH TRAPEZOIDAL RULE, WEIGHTS P * DP
      implicit real*8(a-h,o-z)
     
      DIMENSION U(NP),P(NP)
      NPM=NP-1
      A=.0
      B=P(2)
      W=(B-A)*(B+2.*A)
      H=W*U(1)
    1 DO 2 J=2,NPM
      C=P(J+1)
      W=(A+B+C)*(C-A)
      H=H+W*U(J)
    3 A=B
    2 B=C
      W=(B-A)*(2.*B+A)
      H=H+W*U(NP)
    7 H=H/R/R/6.
      RETURN

      end subroutine

      SUBROUTINE MOMENT2(R, JMAX, P, U, XK)

C***  INTEGRATION OF THE 2. MOMENT XK OF THE RADIATION FIELD U
C***  FEAUTRIER-INTENSITY U(J), IMPACT PARAMETER MESH P(J)
C***  AND RADIUS POINT R ARE GIVEN.
C***  WEIGHTS ARE ACCORDING TO TRAPEZOIDAL RULE IN Z*Z*DZ, Z=SQRT(R*R-P*P)

      implicit real*8(a - h, o - z)

      DIMENSION P(JMAX), U(JMAX)

      RR = R * R

C***  FIRST STEP, IMPLYING P(1)=0
      Z=R
      ZQ=RR
      PJ=P(2)
      ZNQ = (R - PJ) * (R + PJ)
      ZNEXT=SQRT(ZNQ)
      W=Z*(3*ZQ-ZNQ)-ZNEXT*(ZQ+ZNQ)
      XK=W*U(1)

C***  MIDDLE STEPS
      DO J = 3, JMAX

         ZLAST = Z
         ZLQ = ZQ
         Z = ZNEXT
         ZQ = ZNQ
         PJ = P(J)
         ZNQ = (R - PJ) * (R + PJ)
         ZNEXT = SQRT(ZNQ)
         W = Z * (ZLQ - ZNQ) + ZLAST * (ZLQ + ZQ) - ZNEXT * (ZQ + ZNQ)
         XK = XK + W * U(J - 1)

      enddo

C***  LAST STEP, IMPLYING P(JMAX)=R
      W=Z*ZQ
      XK=XK+W*U(JMAX)
      XK=XK/R/RR/12.

      RETURN

      end subroutine

      end module
