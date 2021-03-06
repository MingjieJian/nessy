      MODULE MOD_GEOMESH

      CONTAINS

      SUBROUTINE GEOMESH(RADIUS, ENTOT, T, FAL, P, Z, RSTAR, AMU, ATMEAN, ND, NP)

!     THIS SUBROUTINE GENERATES THE GEOMETRICAL POINT MESH IN RADIUS, P AND Z
!     P and Z mesh is needed for the ray-by-ray solution of the radiative transfer equation in spherical symmetry

      INTEGER, INTENT(OUT) ::  ND, NP
      REAL*8,  INTENT(IN)  ::  RSTAR

      real*8, intent(in) :: AMU, ATMEAN

      logical, intent(in) :: FAL

      real*8, allocatable, dimension(:), intent(out) :: Z, P
      real*8, allocatable, dimension(:), intent(out) :: T, entot, radius

      CALL RGRIDM(RADIUS, ENTOT, T, FAL, RSTAR, AMU, ATMEAN, ND)

      CALL PGRID(NP, ND, RADIUS, P)

      CALL ZGRID(RADIUS, P, Z, ND, NP)

      return

      end subroutine

      SUBROUTINE RGRIDM(radius, entot, T, FAL, rstar, AMU, ATMEAN, ND)

      USE COMMON_BLOCK
      use FILE_OPERATIONS

      integer, intent(out) :: ND

      real*8,  intent(in)  :: rstar

      logical, intent(in) :: FAL

      real*8, intent(in) :: AMU, ATMEAN

      real*8, allocatable, dimension(:), intent(out) :: T, entot, radius

!     height: height in km
!     T:      Temperature in K
!     entot:  HEAVY PARTICLE DENSITY
!     radius: HEIGHT IN UNITS OF SOLAR RADII

      if (FAL)       call read_fal_mod(rstar, height, radius, T, entot, ND)

      if (.not. FAL) call read_kur_mod(amu, atmean, rstar, height, radius, T, entot, ND)

      dpn = ND

      end subroutine

      SUBROUTINE PGRID(NP, ND, R, P)
!     GRID OF IMPACT-PARAMETER POINTS

      integer,                intent(in) ::  ND
      real*8,  dimension(ND), intent(in) ::  R

      integer, intent(out) :: NP

      real*8, allocatable, dimension(:), intent(out) :: P

      real*8, dimension(13) :: cp

      data cp /0.0d0, 0.1d0, 0.2d0, 0.3d0, 0.4d0, 0.5d0, 0.6d0, 0.7d0, 0.8d0, 
     $         0.91652d0, 0.97980d0, 0.99499d0, 0.99875d0/

!     NC = NUMBER OF CORE-INTERSECTING RAYS

      NC = 13; NP = ND + NC

      allocate(P(NP))

      P(1 : NC) = cp(1 : NC)

!     CORE RAYS EQUELLY SPACED

      do L = 1, ND; J = NP + 1 - L; P(J) = R(L); enddo

      return

      end subroutine

      SUBROUTINE ZGRID(RADIUS, P, Z, ND, NP)

      implicit none
!     THIS SUBROUTINE GENERATES THE GEOMETRICAL POINT MESH IN Z

      integer, intent(in)  :: ND, NP
      real*8,  intent(in)  :: RADIUS(ND), P(NP)

      real*8,  allocatable, dimension(:), intent(out) :: Z

      integer :: i, j, L, JMAX

      allocate(z(nd * np))

      z(1 : nd * np) = 0.0d0

      do L = 1, ND

         JMAX = NP + 1 - L

         do j = 1, JMAX

            i = (j - 1) * ND + L

            Z(i) = SQRT((radius(l) - P(j)) * (radius(l) + P(j)))

        enddo

      enddo

      RETURN

      END subroutine

      subroutine read_fal_mod(rstar, height, radius, T, entot, ND)

      use file_operations

      real*8,  intent(in)  :: rstar

      integer, intent(out) :: ND

      real*8, allocatable, dimension(:), intent(out) :: T, entot, radius, height

      ND = num_of_lines(fal_mod_file)

!          if (allocated(T))      deallocate(T)
!          if (allocated(entot))  deallocate(entot)
!          if (allocated(radius)) deallocate(radius)
          if (allocated(height)) deallocate(height)

      allocate(T(ND))
      allocate(entot(ND))
      allocate(radius(ND))
      allocate(height(ND))

      height = read_atm_mod(fal_mod_file, '1')
      T =      read_atm_mod(fal_mod_file, '2')
      entot =  read_atm_mod(fal_mod_file, '4')

      radius = 1.0d0 + height * 1.0d5 / rstar ! height in km, rstar and radius in cm

      end subroutine

      subroutine read_kur_mod(amu, atmean, rstar, height, radius, T, entot, ND)

      use file_operations

      real*8,  intent(in)  :: rstar

      real*8, intent(in) :: amu, atmean

      integer, intent(out) :: ND

      real*8, allocatable, dimension(:), intent(out) :: T, entot, radius, height

      real*8, allocatable, dimension(:) :: entotn, delr

      real*8, allocatable, dimension(:) :: elec_conc, rho, vturb, pressure

!     ak - Boltzmann constant
      real*8, parameter :: ak =  1.38062259d-16
      real*8, parameter :: MUN = 1.66054d-24

      ND = num_of_lines(kur_mod_file) - 1

!          if(allocated(T))         deallocate(T)
!          if(allocated(entot))     deallocate(entot)
!          if(allocated(radius))    deallocate(radius)
          if(allocated(height))    deallocate(height)
!          if(allocated(rho))       deallocate(rho)
!          if(allocated(pressure))  deallocate(pressure)
!          if(allocated(elec_conc)) deallocate(elec_conc)
!          if(allocated(vturb))     deallocate(vturb)
!          if(allocated(entotn))    deallocate(entotn)
!          if(allocated(delr))      deallocate(delr)

      allocate(T(ND))
      allocate(entot(ND))
      allocate(radius(ND))
      allocate(height(ND))
      allocate(rho(ND))
      allocate(pressure(ND))
      allocate(elec_conc(ND))
      allocate(vturb(ND))
      allocate(entotn(ND))
      allocate(delr(ND))

      rho =       read_atm_mod(kur_mod_file, '1')
      T =         read_atm_mod(kur_mod_file, '2')
      pressure =  read_atm_mod(kur_mod_file, '3')
      elec_conc = read_atm_mod(kur_mod_file, '4')
      vturb =     read_atm_mod(kur_mod_file, '7')

      pressure = rho * 10.0**4.44 ! this is from the old version and I do not understand what's it doing there

!         TAKING INTO ACCOUNT TURBULEN PRESSURE
              
      ENTOTN = pressure / (AK * T + 0.5 * ATMEAN * MUN * vturb**2.)

      ENTOT  = ENTOTN - elec_conc

      DO L = 1, ND - 1

         DELR(L) = (2 / (AMU * ATMEAN * RSTAR)) * (RHO(L + 1) - RHO(L)) / (ENTOT(L + 1) + ENTOT(L))

      ENDDO

      RADIUS(ND) = 1.0

      DO K = 1, ND - 1; RADIUS(ND - K) = RADIUS(ND - K + 1) + DELR(ND - K); ENDDO

      height = (radius - radius(ND)) * rstar / 1D+5 ! height in km, rstar and radius in cm

      deallocate(rho)
      deallocate(vturb)
      deallocate(elec_conc)
      deallocate(pressure)
      deallocate(delr)
      deallocate(entotn)

      end subroutine

      end module
