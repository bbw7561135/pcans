module fio

  implicit none

  private

  public :: fio__input, fio__psd, fio__mom

  logical, save                :: lflag=.true.
  integer, public              :: it0, np, nxgs, nxge, nxs, nxe, nsp, bc, bcp
  integer, public, allocatable :: np2(:,:)
  real(8), public, allocatable :: up(:,:,:,:)
  real(8), public, allocatable :: uf(:,:)
  real(8), public, allocatable :: q(:), r(:)
  real(8), public              :: c, delt, delx


contains


  subroutine fio__input(nproc,file)

    integer, intent(in)          :: nproc
    character(len=*), intent(in) :: file
    integer                      :: inproc, iit0
    integer, allocatable         :: np2tmp(:,:)
    real(8), allocatable         :: uptmp(:,:,:,:),uftmp(:,:)

    open(11,file=trim(file),form='unformatted')

    !parameters
    read(11)it0,np,nxgs,nxge,nxs,nxe,nsp,inproc,bc,bcp,delt,delx,c

    if(inproc /= nproc)then
       write(*,*)'error in no. of procs'
       stop
    endif

    if(lflag)then
       allocate(q(nsp))
       allocate(r(nsp))
       allocate(np2(nxgs:nxge+bc,nsp))
       allocate(up(4,np,nxgs:nxge+bc,nsp))
       allocate(uf(6,nxgs-1:nxge+1))
       lflag = .false.
    endif

    allocate(np2tmp(nxs:nxe+bcp,nsp))
    allocate(uftmp(6,nxs-1:nxe+1))
    allocate(uptmp(4,np,nxs:nxe+bcp,nsp))

    read(11)np2tmp
    read(11)q
    read(11)r

    !field data
    read(11)uftmp

    !particle data
!!$    read(11)uptmp

    close(11)

    !copy to global variables
    np2(nxs:nxe+bcp,1:nsp) = np2tmp(nxs:nxe+bcp,1:nsp)
    uf(1:6,nxs-1:nxe+1) = uftmp(1:6,nxs-1:nxe+1)
    up(1:4,1:np,nxs:nxe+bcp,1:nsp) = uptmp(1:4,1:np,nxs:nxe+bcp,1:nsp)

    deallocate(np2tmp)
    deallocate(uftmp)
    deallocate(uptmp)

  end subroutine fio__input


  subroutine fio__psd(dir)

    character(len=*), intent(in) :: dir
    integer                      :: i, ii, isp, ieq
    character(len=256)           :: filename

    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'psd_i.dat'
    open(90,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'psd_e.dat'
    open(91,file=filename,status='unknown')

    isp=1
    do i=nxgs,nxge+bc
       do ii=1,np2(i,isp)
          write(90,'(4e15.3)')(up(ieq,ii,i,isp),ieq=1,4)
       enddo
    enddo

    isp=2
    do i=nxgs,nxge+bc
       do ii=1,np2(i,isp)
          write(91,'(4e15.3)')(up(ieq,ii,i,isp),ieq=1,4)
       enddo
    enddo

  end subroutine fio__psd


  subroutine fio__mom(den,vel,temp,dir)

    real(8), intent(inout)       :: den(nxgs-1:nxge+1,nsp),   &
                                    vel(nxgs-1:nxge+1,3,nsp), &
                                    temp(nxgs-1:nxge+1,3,nsp)
    character(len=*), intent(in) :: dir
    integer :: i
    real(8) :: tmp(nxgs:nxge,6)
    character(len=256) :: filename

    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'den_i.dat'
    open(10,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'den_e.dat'
    open(11,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'Txx_i.dat'
    open(12,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'Tyy_i.dat'
    open(13,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'Tzz_i.dat'
    open(14,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'Txx_e.dat'
    open(15,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'Tyy_e.dat'
    open(16,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'Tzz_e.dat'
    open(17,file=filename,status='unknown')

    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'vxi.dat'
    open(18,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'vyi.dat'
    open(19,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'vzi.dat'
    open(20,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'vxe.dat'
    open(21,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'vye.dat'
    open(22,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'vze.dat'
    open(23,file=filename,status='unknown')

    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'bx.dat'
    open(24,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'by.dat'
    open(25,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'bz.dat'
    open(26,file=filename,status='unknown')

    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'ex.dat'
    open(27,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'ey.dat'
    open(28,file=filename,status='unknown')
    write(filename,'(a,i6.6,a)')trim(dir),it0,'_'//'ez.dat'
    open(29,file=filename,status='unknown')

    !fields at x=i+1/2
    do i=nxgs,nxge+bc
       tmp(i,1) = uf(1,i)
       tmp(i,2) = 0.5*(+uf(2,i)+uf(2,i+1))
       tmp(i,3) = 0.5*(+uf(3,i)+uf(3,i+1))
       tmp(i,4) = 0.5*(+uf(4,i)+uf(4,i+1))
       tmp(i,5) = uf(5,i)
       tmp(i,6) = uf(6,i)
    enddo
    
    !propose vel and temperature
    vel(nxgs:nxge+bc,1,1:nsp) = vel(nxgs:nxge+bc,1,1:nsp)/den(nxgs:nxge+bc,1:nsp)
    vel(nxgs:nxge+bc,2,1:nsp) = vel(nxgs:nxge+bc,2,1:nsp)/den(nxgs:nxge+bc,1:nsp)
    vel(nxgs:nxge+bc,3,1:nsp) = vel(nxgs:nxge+bc,3,1:nsp)/den(nxgs:nxge+bc,1:nsp)
    temp(nxgs:nxge+bc,1,1:nsp) = +temp(nxgs:nxge+bc,1,1:nsp)/den(nxgs:nxge+bc,1:nsp) &
                                 -vel(nxgs:nxge+bc,1,1:nsp)**2
    temp(nxgs:nxge+bc,2,1:nsp) = +temp(nxgs:nxge+bc,2,1:nsp)/den(nxgs:nxge+bc,1:nsp) &
                                 -vel(nxgs:nxge+bc,2,1:nsp)**2
    temp(nxgs:nxge+bc,3,1:nsp) = +temp(nxgs:nxge+bc,3,1:nsp)/den(nxgs:nxge+bc,1:nsp) &
                                 -vel(nxgs:nxge+bc,3,1:nsp)**2

    write(10,99)(den(i,1),i=nxgs,nxge+bc)
    write(11,99)(den(i,2),i=nxgs,nxge+bc)
    write(12,99)(temp(i,1,1),i=nxgs,nxge+bc)
    write(13,99)(temp(i,2,1),i=nxgs,nxge+bc)
    write(14,99)(temp(i,3,1),i=nxgs,nxge+bc)
    write(15,99)(temp(i,1,2),i=nxgs,nxge+bc)
    write(16,99)(temp(i,2,2),i=nxgs,nxge+bc)
    write(17,99)(temp(i,3,2),i=nxgs,nxge+bc)
    write(18,99)(vel(i,1,1),i=nxgs,nxge+bc)
    write(19,99)(vel(i,2,1),i=nxgs,nxge+bc)
    write(20,99)(vel(i,3,1),i=nxgs,nxge+bc)
    write(21,99)(vel(i,1,2),i=nxgs,nxge+bc)
    write(22,99)(vel(i,2,2),i=nxgs,nxge+bc)
    write(23,99)(vel(i,3,2),i=nxgs,nxge+bc)
    write(24,99)(tmp(i,1),i=nxgs,nxge+bc)
    write(25,99)(tmp(i,2),i=nxgs,nxge+bc)
    write(26,99)(tmp(i,3),i=nxgs,nxge+bc)
    write(27,99)(tmp(i,4),i=nxgs,nxge+bc)
    write(28,99)(tmp(i,5),i=nxgs,nxge+bc)
    write(29,99)(tmp(i,6),i=nxgs,nxge+bc)
99  format(100000E15.5)

    close(10)
    close(11)
    close(12)
    close(13)
    close(14)
    close(15)
    close(16)
    close(17)
    close(18)
    close(19)
    close(20)
    close(21)
    close(22)
    close(23)
    close(24)
    close(25)
    close(26)
    close(27)
    close(28)
    close(29)

  end subroutine fio__mom


end module fio
