module const

  implicit none

!!************************ NUMERICAL CONSTANTS ***********************************!!
  integer, parameter :: nx  = 2048   ! NUMBER OF GRID POINTS
  integer, parameter :: np  = 100    ! NUMBER OF PARTICLES IN EACH CELL
  integer, parameter :: nsp = 2      ! NUMBER OF PARTICLE SPECIES
  integer, parameter :: bc  = 0      ! BOUNDARY CONDITION (PERIODIC:0, REFLECTIVE:-1)

!! SETUP FOR SUBROUTINES CALLED IN MAIN PROGRAM
  integer, parameter :: itmax  = 2048 !NUMBER OF ITERATION
  integer            :: it0    = 0    !0:INITIAL, NONZERO/9999999: RESTART DATA
  integer, parameter :: intvl1 = 1024 !INTERVAL FOR PARTICLES & FIELDS STORAGE
  integer, parameter :: intvl2 = 124  !INTERVAL FOR ENERGY CALC.
  integer, parameter :: intvl3 = 10   !INTERVAL FOR RECORDING MOMENT & FIELDS DATA	
  integer, parameter :: intvl4 = 6    !INTERVAL FOR RECORDING FIELDS DATA FOR FOURIER TRANS.	
  character(len=128) :: dir    = './dat/' !DIRECTORY FOR OUTPUT
  character(len=128) :: dir_mom= './mom/' !DIRECTORY FOR MOMENT DATA
  character(len=128) :: dir_psd= './psd/' !DIRECTORY FOR MOMENT DATA
  character(len=128) :: file9  = 'init_param.dat' !FILE NAME OF INIT CONDITIONS
  character(len=128) :: file10 = 'file10.dat' !FILE NAME OF PARTICLE DATA
  character(len=128) :: file12 = 'energy.dat' !FILE NAME OF ENERGY VARIATION
  character(len=128) :: file13 = 'wk_by.dat'  !FILE NAME OF BY COMPONENT
  character(len=128) :: file14 = 'wk_bz.dat'  !FILE NAME OF BZ COMPONENT

!! OTHER CONSTANTS
  real(8), parameter :: gfac   = 0.501D0 !IMPLICITNESS FACTOR > 0.5
  real(8), parameter :: cfl    = 1.0D0   !CFL CONDITION FOR LIGHT WAVE
  real(8), parameter :: delx   = 1.0D0   !CELL WIDTH
  real(8), parameter :: rdbl   = 1.0D0   !DEBYE LENGTH / CELL WIDTH
  real(8), parameter :: pi     = 4.0D0*atan(1.0D0)

!!************************ PHYSICAL CONSTANTS ***********************************!!
!!      n0 : NUMBER OF PARTICLES/CELL
!!       c : SPEED OF LIGHT
!!      mr : ION-TO-ELECTRON MASS RATIO
!!   alpha : wpe/wge = c/vth_e * sqrt(beta_e)
!!    beta : ION PLASMA BETA
!!   rtemp : Te/Ti
!!      v0 : BULK SPEED
  integer, parameter :: n0     = 40
  real(8), parameter :: c      = 1.0D0
  real(8), parameter :: mr     = 16.0D0
  real(8), parameter :: alpha  = 2.0D0, beta = 0.05D0, rtemp=1.0D0
  real(8), parameter :: v0     = 0.0D0

end module
  
