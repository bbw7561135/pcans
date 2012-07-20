module particle

  implicit none

  private

  public :: particle__solv


contains


  subroutine particle__solv(gp,up,uf,                         &
                            c,q,r,delt,                       &
                            np,nsp,np2,nxs,nxe,nxs1,nxe1,bcp)

    integer, intent(in)  :: np, nxs, nxe, nxs1, nxe1, nsp, bcp
    integer, intent(in)  :: np2(nxs:nxe+bcp,nsp)
    real(8), intent(in)  :: up(4,np,nxs:nxe+bcp,nsp)
    real(8), intent(in)  :: uf(6,nxs1:nxe1)
    real(8), intent(in)  :: c, q(nsp), r(nsp), delt
    real(8), intent(out) :: gp(4,np,nxs:nxe+bcp,nsp)
    integer :: i, ii, isp, ih
    real(8) :: dx, dxm, dx2, dxm2
    real(8) :: fac1, fac1r, fac2, fac2r, gam, txxx, bt2
    real(8) :: pf(6)
    real(8) :: uvm(6)

    do isp=1,nsp

       fac1 = q(isp)/r(isp)*0.5*delt
       txxx = fac1*fac1
       fac2 = q(isp)*delt/r(isp)
       do i=nxs,nxe+bcp
          do ii=1,np2(i,isp)

             ih = floor(up(1,ii,i,isp)+0.5)

             dx = up(1,ii,i,isp)-i
             dxm = 1.-dx
             dx2 = up(1,ii,i,isp)+0.5-ih
             dxm2 = 1.-dx2

             pf(1) = uf(1,i)
             pf(2) = +dxm*uf(2,i)+dx*uf(2,i+1)
             pf(3) = +dxm*uf(3,i)+dx*uf(3,i+1)
             pf(4) = +dxm*uf(4,i)+dx*uf(4,i+1)
             pf(5) = +dxm2*uf(5,ih-1)+dx2*uf(5,ih)
             pf(6) = +dxm2*uf(6,ih-1)+dx2*uf(6,ih)

             bt2 = pf(1)*pf(1)+pf(2)*pf(2)+pf(3)*pf(3)

             uvm(1) = up(2,ii,i,isp)+fac1*pf(4)
             uvm(2) = up(3,ii,i,isp)+fac1*pf(5)
             uvm(3) = up(4,ii,i,isp)+fac1*pf(6)

             gam = dsqrt(c*c+uvm(1)*uvm(1)+uvm(2)*uvm(2)+uvm(3)*uvm(3))

             fac1r = fac1/gam
             fac2r = fac2/(gam+txxx*bt2/gam)
             uvm(4) = uvm(1)+fac1r*(+uvm(2)*pf(3)-uvm(3)*pf(2))
             uvm(5) = uvm(2)+fac1r*(+uvm(3)*pf(1)-uvm(1)*pf(3))
             uvm(6) = uvm(3)+fac1r*(+uvm(1)*pf(2)-uvm(2)*pf(1))

             uvm(1) = uvm(1)+fac2r*(+uvm(5)*pf(3)-uvm(6)*pf(2))
             uvm(2) = uvm(2)+fac2r*(+uvm(6)*pf(1)-uvm(4)*pf(3))
             uvm(3) = uvm(3)+fac2r*(+uvm(4)*pf(2)-uvm(5)*pf(1))

             gp(2,ii,i,isp) = uvm(1)+fac1*pf(4)
             gp(3,ii,i,isp) = uvm(2)+fac1*pf(5)
             gp(4,ii,i,isp) = uvm(3)+fac1*pf(6)

             gam = dsqrt(1.0+(+gp(2,ii,i,isp)*gp(2,ii,i,isp) &
                              +gp(3,ii,i,isp)*gp(3,ii,i,isp) &
                              +gp(4,ii,i,isp)*gp(4,ii,i,isp))/(c*c))
             gp(1,ii,i,isp) = up(1,ii,i,isp)+gp(2,ii,i,isp)*delt/gam
          enddo
       enddo

    enddo

  end subroutine particle__solv


end module particle
