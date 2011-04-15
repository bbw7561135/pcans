module const

  implicit none
  integer, parameter :: nx  = 64    ! number of grid points
  integer, parameter :: np  = 10000 ! number of particles in each cell
  integer, parameter :: nsp = 2     ! number of particle species
  integer, parameter :: bc  = 0     ! boundary condition (periodic:0, reflective:-1)
end module
  