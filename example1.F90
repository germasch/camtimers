program simpleomp
  use perf_mod
  use mpi
  implicit none

  integer :: ierr
  
  call MPI_Init(ierr)
  call t_initf("input", LogPrint=.true.)

  call t_startf("t1")
  call t_stopf("t1")

  call t_startf("t1")
  call t_startf("t2")
  call t_stopf("t2")
  call t_stopf("t1")

  call t_prf(filename="ex1.txt")
  call t_finalizef()
  call MPI_Finalize(ierr)
end program simpleomp
