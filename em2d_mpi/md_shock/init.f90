module init

  use const
  use mpi_set
  use random_gen

  implicit none

  private

  public :: init__set_param, init__inject

  integer, public, parameter   :: nroot=0
  integer, allocatable, public :: np2(:,:)
  integer, public              :: itmax, it0, intvl1, intvl2
  real(8), public              :: delx, delt, gfac
  real(8), public              :: c, q(nsp), r(nsp)
  real(8), allocatable, public :: uf(:,:,:)
  real(8), allocatable, public :: up(:,:,:,:)
  real(8), allocatable, public :: gp(:,:,:,:)
  character(len=128), public   :: dir
  character(len=128), public   :: file12
  real(8), save                :: pi, n0, v0, gam0, b0, vti, vte


contains

  
  subroutine init__set_param

    use fio, only : fio__input, fio__param
    real(8)              :: fgi, fpi, alpha, beta, va, fpe, fge, rgi, rge, ldb, rtemp
    character(len=128)   :: file9 
    character(len=128)   :: file11

!************** MPI settings  *******************!
    call mpi_set__init(nxgs,nxge,nygs,nyge,nproc)

    allocate(np2(nys:nye,nsp))
    allocate(uf(6,nxs-2:nxe+2,nys-2:nye+2))
    allocate(up(5,np,nys:nye,nsp))
    allocate(gp(5,np,nys:nye,nsp))
!*********** End of MPI settings  ***************!

!*********************************************************************
!   time0   : start time (if time0 < 0, initial data from input.f)
!   itmax   : number of iteration
!   it0     : base count
!   intvl1  : storage interval for particles & fields
!   intvl2  : printing interval for energy variation
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
    itmax  = 30000
    intvl1 = 5000
    intvl2 = 100
    dir    = './dat/'
    file9  = 'init_param.dat'
    file12 = 'energy.dat'
    gfac   = 0.505
    it0    = 0

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
    delt = 0.5*delx/c
    ldb  = delx

    r(1) = 25.0
    r(2) = 1.0

    alpha = 10.0
    beta  = 0.5
    rtemp = 1.0

    fpe = dsqrt(beta*rtemp)*c/(dsqrt(2.D0)*alpha*ldb)
    fge = fpe/alpha

    va   = fge/fpe*c*dsqrt(r(2)/r(1))
    rge  = alpha*ldb*dsqrt(2.D0)
    rgi  = rge*dsqrt(r(1)/r(2))/dsqrt(rtemp)
    vte  = rge*fge
    vti  = vte*dsqrt(r(2)/r(1))/dsqrt(rtemp)
    v0   = 10.0*va
    gam0 = 1./dsqrt(1.-(v0/c)**2)
   
    fgi = fge*r(2)/r(1)
    fpi = fpe*dsqrt(r(2)/r(1))

    !average number density at x=nxgs (magnetosheath)
    n0 = 20.

    if(nrank == nroot)then
       if(n0*(nxge+bc-nxgs+1) > np)then
          write(*,*)'Too large number of particles'
          stop
       endif
    endif

    !number of particles in each cell in y
    np2(nys:nye,1:nsp) = n0*(nxge-nxgs)*delx

    !charge
    q(1) = fpi*dsqrt(r(1)/(4.0*pi*n0))
    q(2) = -q(1)

    !Magnetic field strength
    b0 = fgi*r(1)*c/q(1)

    if(it0 /= 0)then
       !start from the past calculation
       write(file11,'(i6.6,a,i3.3,a)') it0,'_rank=',nrank,'.dat'
       call fio__input(up,uf,np2,c,q,r,delt,delx,it0,                             &
                       np,nxgs,nxge,nygs,nyge,nxs,nxe,nys,nye,nsp,bc,nproc,nrank, &
                       dir,file11)
       return
    endif

    call random_gen__init(nrank)
    call init__loading
    call fio__param(np,nsp,np2,                             &
                    nxgs,nxge,nygs,nyge,nys,nye,            &
                    c,q,r,n0,0.5*r(1)*vti**2,rtemp,fpe,fge, &
                    ldb,delt,delx,dir,file9,                &
                    nroot,nrank)

  end subroutine init__set_param


  subroutine init__loading

    use boundary, only : boundary__field

    integer :: i, j, ii, isp
    real(8) :: sd, r1, r2, gamp

    !*** setting of fields ***!
    !magnetic field
    do j=nys,nye
    do i=nxs,nxe+bc
       uf(1,i,j) = 0.0D0
    enddo
    enddo

    do j=nys,nye
    do i=nxs,nxe
       uf(2,i,j) = 0.0D0
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
       uf(5,i,j) = v0*b0/c
       uf(6,i,j) = 0.0
    enddo
    enddo

    call boundary__field(uf,                 &
                         nxs,nxe,nys,nye,bc, &
                         nup,ndown,mnpr,nstat,ncomw,nerr)
    !*** end of ***!

    !particle position
    isp = 1
    do j=nys,nye
       do ii=1,np2(j,isp)
          call random_number(r1)
          up(1,ii,j,1) = nxs*delx+r1*delx*(nxe+bc-nxs+1.)
          up(1,ii,j,2) = up(1,ii,j,1)

          call random_number(r1)
          up(2,ii,j,1) = dble(j)*delx+delx*r1
          up(2,ii,j,2) = up(2,ii,j,1)
       enddo
    enddo

    !velocity
    !Maxwellian distribution
    do isp=1,nsp
       do j=nys,nye
          do ii=1,np2(j,isp)
             if(isp .eq. 1) then 
                sd = vti/sqrt(2.)
             endif
             if(isp .eq. 2) then
                sd = vte/sqrt(2.)
             endif

             call random_gen__bm(r1,r2)
             up(3,ii,j,isp) = sd*r1
             up(4,ii,j,isp) = sd*r2

             call random_gen__bm(r1,r2)
             up(5,ii,j,isp) = sd*r1

             gamp = dsqrt(1.D0+(up(3,ii,j,isp)**2+up(4,ii,j,isp)**2+up(5,ii,j,isp)**2)/(c*c))

             ! Density fix: Zenitani, Phys. Plasmas 22, 042116 (2015)
             call random_number(r1)
             if(up(3,ii,j,isp)*v0 >= 0.)then
                up(3,ii,j,isp) = (+up(3,ii,j,isp)+v0*gamp)*gam0
             else
                if(r1 < (-v0*up(3,ii,j,isp)/gamp))then
                   up(3,ii,j,isp) = (-up(3,ii,j,isp)+v0*gamp)*gam0
                else
                   up(3,ii,j,isp) = (+up(3,ii,j,isp)+v0*gamp)*gam0
                endif
             endif
          enddo
       enddo
    enddo

  end subroutine init__loading


  subroutine init__inject

    use boundary, only : boundary__field

    integer :: isp, ii, ii2, ii3, j, dn
    real(8) :: sd, r1, r2, dx, gamp

    !Inject particles in x=nxs~nxs+v0*dt

    dx  = v0*delt/delx
    dn  = n0*dx

    do j=nys,nye
       do ii=1,dn
          ii2 = np2(j,1)+ii
          ii3 = np2(j,2)+ii
          call random_number(r1)
          up(1,ii2,j,1) = nxs*delx+r1*dx
          up(1,ii3,j,2) = up(1,ii2,j,1)

          call random_number(r1)
          up(2,ii2,j,1) = dble(j)*delx+delx*r1
          up(2,ii3,j,2) = up(2,ii2,j,1)
       enddo
    enddo

    !velocity
    !Maxwellian distribution
    do isp=1,nsp
       if(isp == 1) then 
          sd = vti/dsqrt(2.0D0)
       endif
       if(isp == 2) then
          sd = vte/dsqrt(2.0D0)
       endif

       do j=nys,nye
          do ii=np2(j,isp)+1,np2(j,isp)+dn
             call random_gen__bm(r1,r2)
             up(3,ii,j,isp) = sd*r1
             up(4,ii,j,isp) = sd*r2

             call random_gen__bm(r1,r2)
             up(5,ii,j,isp) = sd*r1

             gamp = dsqrt(1.D0+(up(3,ii,j,isp)**2+up(4,ii,j,isp)**2+up(5,ii,j,isp)**2)/(c*c))

             call random_number(r1)
             if(up(3,ii,j,isp)*v0 >= 0.)then
                up(3,ii,j,isp) = (+up(3,ii,j,isp)+v0*gamp)*gam0
             else
                if(r1 < (-v0*up(3,ii,j,isp)/gamp))then
                   up(3,ii,j,isp) = (-up(3,ii,j,isp)+v0*gamp)*gam0
                else
                   up(3,ii,j,isp) = (+up(3,ii,j,isp)+v0*gamp)*gam0
                endif
             endif
          enddo
       enddo
    enddo

    do isp=1,nsp
       do j=nys,nye
          np2(j,isp) = np2(j,isp)+dn
       enddo
    enddo

    !set Ex and Bz
    do j=nys,nye
       uf(3,nxs,j) = b0
       uf(5,nxs,j) = v0*b0/c
       uf(3,nxs+1,j) = b0
       uf(5,nxs+1,j) = v0*b0/c
    enddo

    call boundary__field(uf,                 &
                         nxs,nxe,nys,nye,bc, &
                         nup,ndown,mnpr,nstat,ncomw,nerr)

  end subroutine init__inject


end module init
