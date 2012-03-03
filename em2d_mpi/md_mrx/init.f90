module init

  use const
  use mpi_set

  implicit none

  private

  public :: init__set_param

  integer, public, parameter :: nroot=0
  integer, allocatable, public :: np2(:,:)
  integer, public :: itmax, it0, intvl1, intvl2, intvl3
  real(8), public :: delx, delt, gfac
  real(8), public :: c
  real(8), allocatable, public :: uf(:,:,:)
  real(8), allocatable, public :: up(:,:,:,:)
  real(8), public :: q(nsp), r(nsp)
  real(8), allocatable, public :: gp(:,:,:,:)
  character(len=64), public :: dir
  character(len=64), public :: file12
  real(8)                   :: pi, vti, vte, va, rtemp, fpe, fge, rgi, rge, ldb, b0


contains

  
  subroutine init__set_param

    use fio, only : fio__input, fio__param
    real(8) :: fgi, fpi, alpha, beta, n0
    character(len=64) :: file9 
    character(len=64) :: file11

!************** MPI settings  *******************!
    call mpi_set__init(nxgs,nxge,nygs,nyge,nproc)

    allocate(np2(nys:nye,nsp))
    allocate(uf(6,nxs1:nxe1,nys1:nye1))
    allocate(up(5,np,nys:nye,nsp))
    allocate(gp(5,np,nys:nye,nsp))
!*********** End of MPI settings  ***************!

!*********************************************************************
!   time0   : start time (if time0 < 0, initial data from input.f)
!   itmax   : number of iteration
!   it0     : base count
!   intvl1  : storage interval for particles & fields
!   intvl2  : printing interval for energy variation
!   intvl3  : printing interval for wave analysis
!   dir     : directory name for data output
!   file??  : output file name for unit number ??
!           :  9 - initial parameters
!           : 10 - for saving all data
!           : 11 - for starting from saved data
!           : 12 - for saving energy history
!   gfac    : implicit factor
!             gfac < 0.5 : unstable
!             gfac = 0.5 : no implicit
!             gfac = 1.0 : full implicit
!*********************************************************************
    pi     = 4.0*atan(1.0)
    itmax  = 100
    intvl1 = 100
    intvl2 = 10
    intvl3 = 10
    dir    = './dat/'
    file9  = 'init_param.dat'
    file12 = 'energy.dat'
    gfac   = 0.505

    it0    = 0
    if(it0 /= 0)then
       !start from the past calculation
       write(file11,'(a,i3.3,a)')'000100_rank=',nrank,'.dat'
       call fio__input(up,uf,np2,c,q,r,delt,delx,it0,                             &
                       np,nxgs,nxge,nygs,nyge,nxs,nxe,nys,nye,nsp,bc,nproc,nrank, &
                       dir,file11)
       return
    endif

!*********************************************************************
!   r(1)  : ion mass             r(2)  : electron mass
!   q(1)  : ion charge           q(2)  : electron charge
!   c     : speed of light       ldb   : debye length
!
!   rgi   : ion Larmor radius    rge   : electron Larmor radius
!   fgi   : ion gyro-frequency   fge   : electron gyro-frequency
!   vti   : ion thermal speed    vte   : electron thermal speed
!   b0    : magnetic field       
!  
!   alpha : wpe/wge
!   beta  : ion plasma beta
!   rtemp : Te/Ti
!*********************************************************************
    delx = 1.0
    c    = 1.0
    delt = 0.2
    ldb  = delx

    r(1) = 16.0
    r(2) = 1.0

    alpha = 2.0
    beta  = 0.1
    rtemp = 1.0

    fpe = dsqrt(beta*rtemp)*c/(dsqrt(2.D0)*alpha*ldb)
    fge = fpe/alpha

    va  = fge/fpe*c*dsqrt(r(2)/r(1))
    rge = fpe/fge*ldb*dsqrt(2.D0)
    rgi = rge*dsqrt(r(1)/r(2))/dsqrt(rtemp)

    vte = rge*fge
    vti = vte*dsqrt(r(2)/r(1))/dsqrt(rtemp)

    fgi = fge*r(2)/r(1)
    fpi = fpe*dsqrt(r(2)/r(1))

    np2(nys:nye,1) = 50*(nxe+bc-nxs+1)
    np2(nys:nye,2) = np2(nys:nye,1)

    if(nrank == nroot)then
       if(max(np2(nys,1), np2(nye,1), np) > np)then
          write(*,*)'Too large number of particles'
          stop
       endif
    endif

    !charge
    if(nrank == nroot) n0 = dble(np2(nys,1))/dble((nxge-nxgs+1))
    call MPI_BCAST(n0,1,mnpr,nroot,ncomw,nerr)
    q(1) = fpi*dsqrt(r(1)/(4.0*pi*n0))
    q(2) = -q(1)

    !Magnetic field strength
    b0 = fgi*r(1)*c/q(1)

    call init__loading
    call init__set_field
    call fio__param(np,nsp,np2,                     &
                    nxgs,nxge,nygs,nyge,nys,nye,    &
                    c,q,r,n0,0.5*r(1)*vti**2,rtemp,fpe,fge, &
                    ldb,delt,delx,dir,file9,        &
                    nroot,nrank)

  end subroutine init__set_param


  subroutine init__loading

    use boundary, only : boundary__particle

    integer :: j, ii, isp, n
    integer, allocatable :: seed(:)
    real(8) :: sd, aa, bb

    call random_seed()
    call random_seed(size=n)
    allocate(seed(n))
    call random_seed(get=seed)
!!$    seed(1:n) = seed(1:n)+nrank
    seed(1:n) = nrank
    call random_seed(put=seed)
    deallocate(seed)

    !particle position
    isp=1
    do j=nys,nye
       do ii=1,np2(j,isp)
          call random_number(aa)
          up(1,ii,j,1) = nxs*delx+aa*delx*(nxe+bc-nxs+1.)
          up(1,ii,j,2) = up(1,ii,j,1)
          call random_number(aa)
          up(2,ii,j,1) = dble(j)*delx+delx*aa
          up(2,ii,j,2) = up(2,ii,j,1)
       enddo
    enddo

    !velocity
    !Maxwellian distribution
    do isp=1,nsp
       if(isp .eq. 1) then 
          sd = vti/dsqrt(2.0D0)
       endif
       if(isp .eq. 2) then
          sd = vte/dsqrt(2.0D0)
       endif

       do j=nys,nye
          do ii=1,np2(j,isp)
             call random_number(aa)
             call random_number(bb)
             up(3,ii,j,isp) = sd*dsqrt(-2.*dlog(aa))*cos(2.*pi*bb)

             call random_number(aa)
             call random_number(bb)
             up(4,ii,j,isp) = sd*dsqrt(-2.*dlog(aa))*cos(2.*pi*bb)
             up(5,ii,j,isp) = sd*dsqrt(-2.*dlog(aa))*sin(2.*pi*bb)
          enddo
       enddo
    enddo

    call boundary__particle(up,                                        &
                            np,nsp,np2,nxgs,nxge,nygs,nyge,nys,nye,bc, &
                            nup,ndown,nstat,mnpi,mnpr,ncomw,nerr)

  end subroutine init__loading


  subroutine init__set_field

    use boundary, only : boundary__field

    integer :: i, j

    !magnetic field
    do j=nys,nye
    do i=nxs,nxe+bc
       uf(1,i,j) = 0.0
    enddo
    enddo
    do j=nys,nye
    do i=nxs,nxe
       uf(2,i,j) = 0.0
       uf(3,i,j) = b0
    enddo
    enddo

    !electric field
    do j=nys,nye
    do i=nxs,nxe
       uf(4,i,j) = 0.0
    enddo
    enddo
    do j=nys,nye
    do i=nxs,nxe+bc
       uf(5,i,j) = 0.0
       uf(6,i,j) = 0.0
    enddo
    enddo

    call boundary__field(uf,                 &
                         nxs,nxe,nys,nye,bc, &
                         nup,ndown,mnpr,nstat,ncomw,nerr)

  end subroutine init__set_field


end module init