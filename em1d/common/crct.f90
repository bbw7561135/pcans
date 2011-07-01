module crct

  implicit none

  private

  public :: crct__init
  public :: crct__ef

  integer, save              :: np, nx, nsp, bc
  real(8), save              :: delx
  real(8), save, allocatable :: q(:)


contains


  subroutine crct__init(npin,nxin,nspin,bcin,qin,delxin)
    integer, intent(in) :: npin, nxin, nspin, bcin
    real(8), intent(in) :: qin(nspin), delxin

    np   = npin
    nx   = nxin
    nsp  = nspin
    bc   = bcin
    allocate(q(nsp))
    q    = qin
    delx = delxin

  end subroutine crct__init


  subroutine crct__ef(uf,up,np2)

    use boundary, only : boundary__charge
    integer, intent(in)    :: np2(1:nx+bc,nsp)
    real(8), intent(in)    :: up(4,np,1:nx+bc,nsp)
    real(8), intent(inout) :: uf(6,0:nx+1)
    real(8), parameter :: eps = 1.0e-6
    integer :: i
    real(8) :: pi
    real(8) :: xx1, xx2, idelx
    real(8) :: cden(-1:nx+2), b(0:nx+1), x(0:nx+1)

    pi = 4.0*atan(1.0)
    idelx = 1.D0/delx

!-----------------------------------------------------------------------
!   E(after) = E(before) - d/dx p
!   d2/dx2 p = div E(before) - 4 pi den
!-----------------------------------------------------------------------

    call charge(cden,up,np2,idelx)
    call boundary__charge(cden)

    !div E - 4 pi den
    xx1 = 0.0
    xx2 = 0.0
    do i=1,nx+bc
       b(i) = (-uf(4,i)+uf(4,i+1))*idelx-4.*pi*cden(i)
       xx1 = xx1+b(i)*b(i)
       xx2 = xx2+uf(4,i)*uf(4,i)+uf(5,i)*uf(5,i)+uf(6,i)*uf(6,i)
    enddo

    if(xx2 > 0.0)then
       if(xx1/xx2 <= eps) return
    endif

    call poisn(x,b)

    do i=1,nx
       uf(4,i) = uf(4,i)-(-x(i-1)+x(i))*idelx
    enddo

    call boundary__field(uf)

  end subroutine crct__ef


  subroutine charge(cden,up,np2,idelx)

    integer, intent(in)  :: np2(1:nx+bc,nsp)
    real(8), intent(in)  :: up(4,np,1:nx+bc,nsp)
    real(8), intent(in)  :: idelx
    real(8), intent(out) :: cden(-1:nx+2)
    integer :: ii, i, isp, ih
    real(8) :: dx, dxm

    !memory clear
    cden(-1:nx+2) = 0.0D0

    !caluculate charge density
    do isp=1,nsp
       do i=1,nx+bc
          do ii=1,np2(i,isp)
             ih = floor(up(1,ii,i,isp)-0.5)
             dx = up(1,ii,i,isp)-0.5-ih
             dxm = 1.-dx

             cden(ih)   = cden(ih)  +q(isp)*dxm
             cden(ih+1) = cden(ih+1)+q(isp)*dx 
          enddo
       enddo
    enddo

    if(bc == 0)then
       do i=-1,nx+2
          cden(i) = cden(i)*idelx
       enddo
    else if(bc == -1)then
       do i=0,nx
          cden(i) = cden(i)*idelx
       enddo
    else
       write(*,*)'choose bc=0 (periodic) or bc=-1 (reflective)'
       stop
    endif

  end subroutine charge


  subroutine poisn(x,b)

    real(8), intent(in)  :: b(0:nx+1)
    real(8), intent(out) :: x(0:nx+1)
    integer :: i
    real(8) :: tmp

!-----------------------------------------------------------------------
!  #  poisson solver 
!  #  bc =  0 periodic boundary condition
!  #  bc = -1 reflective boundary condition
!-----------------------------------------------------------------------

      tmp = 0.0D0
      do i=1,nx+bc
         tmp = tmp+dble(i)*b(i)
      enddo

      x(1) = 0.0D0
      if(bc == -1)then
         x(nx) = 0.0
      endif

      x(nx+bc)   = -tmp/dble(nx)
      x(nx+bc-1) = b(nx+bc)+2.0*x(nx+bc)

      do i=nx+bc-2,2+bc,-1
         x(i) = +2.0*x(i+1)-x(i+2)+b(i+1)
      enddo

      if(bc == 0)then
         x(0) = x(nx)
         x(nx+1) = x(1)
      endif

  end subroutine poisn


end module crct
