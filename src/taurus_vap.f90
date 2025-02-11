!==============================================================================!
! PROGRAM TAURUS_vap                                                           !
!                                                                              !
! This program performs the variation after particle-number projection of real !
! general quasi-particle states represented in a spherical harmonic ocillator  !
! basis.                                                                       !
!                                                                              !
! Licence: GNU General Public License version 3 or later                       !
! DOI: 10.5281/zenodo.4130680                                                  !
! Repository: github.com/project-taurus/taurus_vap                             !
!                                                                              !
! Article describing the code: arXiv:2010.14169                                !
!==============================================================================!
PROGRAM TAURUS_vap

!cmpi use MPI
!cmpi use Parallelization
use Nucleus
use Basis
use Fields
use Operators
use Projection
use Gradient
use Initialization
use DensityDep
use DensDepResultExportings

implicit none

integer :: iter=0, iter_max, iter_write, iter_print
integer :: dt(8)
!cmpi integer :: ierr=0

!!!
!!! INITIALIZATION
!!!

!cmpi call mpi_init(ierr)
!cmpi call mpi_comm_size(mpi_comm_world,paral_worldsize,ierr)
!cmpi call mpi_comm_rank(mpi_comm_world,paral_myrank,ierr)

!!! Reads the input parameters
call print_version
call read_input(iter_max,iter_write,iter_print)

call date_and_time(VALUES=dt)
print '(A,i4,5(a,i2.2),A,i0.3)', &
    "TIME_START: ",dt(1),'/',dt(2),'/',dt(3),' ', &
    dt(5), '_', dt(6), '_', dt(7), '.', dt(8)

!!! Sets the basis, wave functions, and all the important operators
!cmpi call set_parallel_teams
call set_nucleus
call set_basis
call set_hamiltonian
call set_wavefunctions
call set_fields
call set_particle_number
call set_pairs
call set_angular_momentum
call set_multipoles
call set_radius
call set_projection

!!! Generates/Reads the seed wave function and performs a first adjustment of
!!! the constraints (if not just printing a converged file)
call generate_wavefunction(HOsp_dim)
call check_symmetries(HOsp_dim)
call set_constraints
call set_gradient
if ( (iter_max > 0) .or. (seed_type /= 1) ) then
  call adjust_constraints(gradient_Zi,HOsp_dim)
endif

!! DENSITY DEP. MODULE
call set_densty_dependent(seed_type, iter_max, proj_Mphip, proj_Mphin)
!!!
!!! MINIMIZATION
!!!

!cmpi if ( paral_myrank == 0 ) then
if ( iter_max > 0 ) print '(/,60("%"),/,19x,"ITERATIVE MINIMIZATION",19x,/, &
                            & 60("%"))'
!cmpi endif


call date_and_time(VALUES=dt)
print '(A,i4,5(a,i2.2),a,i0.3)', &
    "TIME_START: ",dt(1),'/',dt(2),'/',dt(3),' ', &
    dt(5), '_', dt(6), '_', dt(7), '.', dt(8)
!!! Loop for the gradient
do iter = 1, iter_max

  !!! Initialization of the iteration
  !cmpi if ( paral_myrank == 0 ) then
  field_H20v = zero
  call calculate_densities_real(bogo_U0,bogo_V0,dens_rhoRR,dens_kappaRR, &
                                HOsp_dim)
  call update_constraints_qpbasis
  !cmpi endif

  !!! Computes the projected gradient and some other projected quantities
  !cmpi call broadcast_densities
  call project_wavefunction(0,iter_print,proj_Mphip,proj_Mphin,HOsp_dim)
  !cmpi if ( paral_myrank == 0 ) then
  call calculate_lagrange_multipliers(field_H20v,HOsp_dim)
  !cmpi endif
  if ( gradient_type > 0 ) call diagonalize_hsp_and_H11(0,HOsp_dim)
  !cmpi if ( paral_myrank == 0 ) then
  call calculate_gradient(HOsp_dim)

  !!! Exits the loop if the gradient is converged. Otherwise, adjusts the
  !!! constraints and evolves the wave function for the next iteration
  call print_iteration(iter_print,iter)
  !cmpi endif

  !cmpi call mpi_bcast(gradient_norm,1,mpi_double_precision,0,mpi_comm_world, &
  !cmpi                ierr)
  if ( gradient_norm <= gradient_eps ) then
    !cmpi if ( paral_myrank == 0 ) then
    print '(/,"Calculation converged")'
    !cmpi endif
    exit
  endif

  !cmpi if ( paral_myrank == 0 ) then
  call adjust_constraints(gradient_Zi,HOsp_dim)
  gradient_Zim1 = gradient_Zi

  !!! Writes the intermediate wave function if needed
  if ( iter == iter_max ) then
    print '(/,"Maximum number of iterations reached")'
  elseif ( (iter_write /= 0) .and. (mod(iter,max(1,iter_write)) == 0) ) then
    call write_wavefunction(1,iter,real(pnp_ener/pnp_over))
  endif
  !cmpi endif

enddo

call date_and_time(VALUES=dt)
print '(A,i4,5(a,i2.2),A,i0.3,A,I6)', &
    "TIME_END: ",dt(1),'/',dt(2),'/',dt(3), ' ',&
    dt(5),'_',dt(6),'_',dt(7),'.', dt(8), " ITER_FINAL=", iter

!!!
!!! PRINTING
!!!

!!! Computes the densities to store the final SP/QP basis
!cmpi if ( paral_myrank == 0 ) then
call calculate_densities_real(bogo_U0,bogo_V0,dens_rhoRR,dens_kappaRR,HOsp_dim)

!cmpi endif
!cmpi call broadcast_densities
call diagonalize_hsp_and_H11(1,HOsp_dim)

!!! Final writing and printing (projected and unprojected)
!cmpi if ( paral_myrank == 0 ) then
call write_wavefunction(0,iter_max,real(pnp_ener/pnp_over))
!cmpi endif
if ( max(proj_Mphip,proj_Mphin) > 1 ) then
  call print_results(proj_Mphip,proj_Mphin)
endif
call print_results(1,1)

!! Exporting of the spherical QP valence space from DD interaction
call export_densityAndHamiltonian(bogo_U0,bogo_V0, dens_rhoRR, dens_kappaRR, &
                                  HOsp_dim)

!cmpi if ( paral_myrank == 0 ) then
print '(/,"This is the end, my only friend, the end.")'
!cmpi endif

!cmpi call mpi_finalize(ierr)

END PROGRAM TAURUS_vap
!==============================================================================!
! End of file                                                                  !
!==============================================================================!
