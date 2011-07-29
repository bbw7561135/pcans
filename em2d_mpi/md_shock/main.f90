program main

  use const
  use mpi_set
  use init
  use boundary
  use fio
  use particle
  use field

  implicit none

  integer :: it=0
  real(8) :: etime, etlim, etime0, omp_get_wtime

!**********************************************************************c
!
!    two-dimensional electromagnetic plasma simulation code
!
!    written by M Hoshino,  ISAS, 1984/09/12
!    revised  1985/03/08  1985/04/05  1997/05/06
!    revised for CANS    (by Y. Matsumoto, STEL)  2004/06/22
!    re-written in F90   (by Y. Matsumoto, STEL)  2008/10/21
!    MPI parallelization (by Y. Matsumoto, STEL)  2009/4/1
!    2-D code            (by Y. Matsumoto, STEL)  2009/6/5
!
!**********************************************************************c

  !**** Maximum elapse time ****!
  etlim = 60.*60.*60.-10.*60.
  !Test runs
!!$  etlim = 10.*60.-3.*60.
  !*****************************!
  call cpu_time(etime0)

  call init__set_param
  call MPI_BCAST(etime0,1,mnpr,nroot,ncomw,nerr)

  call fio__energy(up,uf,                         &
                   np,nsp,np2,nxs,nxe,nys,nye,bc, &
                   c,r,delt,0,it0,dir,file12,     &
                   nroot,nrank,mnpr,opsum,ncomw,nerr)

  loop: do it=1,itmax-it0

     if(nrank == nroot) call cpu_time(etime)

     call MPI_BCAST(etime,1,mnpr,nroot,ncomw,nerr)

     if(etime-etime0 >= etlim) then
        call fio__output(up,uf,np,nxgs,nxge,nygs,nyge,nxs,nxe,nys,nye,nsp,np2,bc,nproc,nrank, &
                         c,q,r,delt,delx,it-1,it0,dir)
        if(nrank == nroot) write(*,*) '*** elapse time over ***',it,etime-etime0
        exit loop
     endif

     call particle__solv(gp,up,uf,                   &
                         c,q,r,delt,                 &
                         np,nsp,np2,nxs,nxe,nys,nye)
     call field__fdtd_i(uf,up,gp,                                &
                        np,nsp,np2,nxgs,nxge,nxs,nxe,nys,nye,bc, &
                        q,c,delx,delt,gfac,                      &
                        nup,ndown,mnpr,opsum,nstat,ncomw,nerr)
     call boundary__particle(up,                                        &
                             np,nsp,np2,nxgs,nxge,nygs,nyge,nys,nye,bc, &
                             nup,ndown,nstat,mnpi,mnpr,ncomw,nerr)

     call init__inject

     if(mod(it+it0,intvl1) == 0)                                                                &
          call fio__output(up,uf,np,nxgs,nxge,nygs,nyge,nxs,nxe,nys,nye,nsp,np2,bc,nproc,nrank, &
                           c,q,r,delt,delx,it,it0,dir)
     if(mod(it+it0,intvl2) == 0)                          &
          call fio__energy(up,uf,                         &
                           np,nsp,np2,nxs,nxe,nys,nye,bc, &
                           c,r,delt,it,it0,dir,file12,    &
                           nroot,nrank,mnpr,opsum,ncomw,nerr)
  enddo loop

  call MPI_FINALIZE(nerr)


end program main
