## Project densN_taurus_vap
Density dependent HFB mean field code. Main usage and original repository in [project-taurus/taurus_vap](https://github.com/project-taurus/taurus_vap.git) and [dens_taurus_vap code](https://github.com/migueldelafuente1/dens_taurus_vap). This experimental version extends it with the implementation for **N density-dependent functionals** for special interactions.

## Contents

1. [Features](#Features)
2. [Use](#Use)
3. [Contributors](#Contributors)

## Features
Present code appends the density-dependent(DD) fields to the ones obtained form the Hamiltonian part of EDF interactions, working as other EDF solvers with the explicit inclussion of terms related to the pn-mixning space.

The pn-mixing space is problematic for no-core large scale calculations due the ultraviolet divergences in the case of non-pn adjusted interactions (such as Gogny D1S), which occurr normaly for 6/7 SHO major shells. (work on progress with the introduction of cutoff or excluding the pn fields from the HFB variation).

Another limitation is the code cannot implement the VAP projection (work on progress).

**The code has not been fully tested, specially for uncommon functions, only the simplest taurus+DD evaluation is reliable**. Avoid, explicit evaluation, using of cutoffs, the additional functional modes appart from the GUT-printing shotdown, removal of DD-proton/neutron HF/pairing terms and the implementation of several forces.

## Use
In addition to the Hamiltonian matrix elements and the input file from the original program, the density functional set up requires the file `input_DD_PARAMS.txt`. This is an example for the 2 density-dependent interaction M3Y-P6 with all the exchange(spin/isospin) terms and two different alpha constants in the functional.
```
* Density dep. Interaction:    ------------
eval_density_dependent (1,0)= 1
eval_rearrangement (1,0)    = 1
eval_explicit_fieldsDD (1,0)= 0
t3_DD_CONST [real  MeV]     = 4.825000d+02
x0_DD_FACTOR                = 1.000000d+00
alpha_DD                    = 0.333333d+00
* Integration/options:         ------------
r_dim                       = 12
Omega_Order                 = 14
export_density (1, 0)       = 0
eval QuasiParticle Vs       = 0
eval/export Valence.Space   = 0 203 205 10001
additional options-modes    = 7
 DD-term (1) Heisenberg x0  = 31 1.0000
 DD-term (1) Majorana   x0  = 32 1.0000
*DD-term (2)  t3 (MeV)      = 33 96.000
 DD-term (2) Bartlett   x0  = 34 -1.000
 DD-term (2) Heisenberg x0  = 35 -1.000
 DD-term (2) Majorana   x0  = 36 1.0000
 DD-term (2) Alpha exp.     = 37 1.0000
* Integration parameters:      ------------
```
representing
$t_3^{(1)}(1+P^\sigma(B) -  P^\tau(H) - P^\tau P^\sigma(M)) \rho(r)^{1/3} + t_3^{(2)}(1 - P^\sigma(B) + P^\tau(H) - P^\tau P^\sigma(M)) \rho(r)^{1}$

For the moment, there is only parameters for two additional functionals. But the program is generalized, so only importing of the additional arguments must be updated.

If you are going to use a single DD functional form, please, use the [dens_taurus_vap repository](https://github.com/migueldelafuente1/dens_taurus_vap).

Usage of the different options.
1. **eval_density_dependent**: activate/deactivate the density-dependent part
2. **eval_rearrangement**: evaluate the rearrangement fields
3. **eval_explicit_fieldsDD**: evaluates DD fields from analytical evaluatuion of the 2-body matrix elements. The option is extremely computationally expensive and is only ment for testing purposes.
4. **t3**, **x0** & **alpha**: constants form the Gogny functional (global constant, spin-exchange factor and power of the spatial density function).
5. **r_dim**: Laguerre grid for the radial part of the density integral.
6. **Omega_order**: Order of the Lebedev integration grid. Remember that the order of symmetries in the icosaedrum, therefore the actual dimension of the angular grid scalates quicly for Omega. Order 12(230 points) - 17(590) is enought for normal calculations with no high degree of deformation.
7. **export_density** export of the spatial density in the integration grid (taurus\_vap has also an option to export also in setteable cartesian/spherical grid).
8. **eval QuasiParticle Vs** (0,1) option evaluates the quasiparticle spherical matrix elements of the DD interaction in the final state. The option demands high computational resources and is in develoment stage, additionaly, resultant matrix elements cannot include the rearrangement effects necessary to obtain a Hamiltonian form of the DD interaction (ignore the option).
9. **eval/export Valence.Space** is the list of the states for the resultant valence space, firs index is the number of states to read, set to 0 to ignore. If option **eval QuasiParticle Vs** is 0, and states are given, the program evaluates the matrix elements in the SHO basis as a valence space. Set the length greater than the dimension of shell-SHO states in the basis for the complete basis to evaluate.
10. **Additional option-modes** (integer for the number of options to read, 0 to switch off), options follows the pattern integer[I2] float, where the integer is a code for some option and usage explained latter. Invalid code raises global stop of the program.


**Additional options and codes**
|Code|Argument|Tested Description|
|----|----|----|----|
| 1 | NA | OK | Removes the "gut" internal testing files printing |
| 2 | NA | OK | Shut down the evaluation of fields (including rearrangement) for the PN-PAIRING part of the DD-interaction |
| 3 | NA | OK | Shut down the evaluation of fields (including rearrangement) for the PN-Hartree-Fock part of the DD-interaction |
| 11 | Energy CO | NO | Cutoff(CO) for the PN-interaction part, limit for the energy around the Fermi energy in the cannocical basis. Reevaluates the fields after the discard of the kappa matrix elemnts.|
| 12 | Kappa norm CO | NO | Cutoff(CO) for the PN-interaction part, lower limit for the kappa tensor value to account for the states in the cannocical basis (is around the Fermi energy)  (can be used in combination with 11).|
| 21 | float | NO - NA | Funcitonal for the D1S without spin-exchange supression [Phys.Rev.C 60, 064312 (1999)](https://doi.org/10.1103/PhysRevC.60.064312), density factor 'eta', use with alpha and x0=0 in the main arguments, also with argument 22|
| 22 | float | NO - NA | Same functional as 21, argument rho0 associated to the nuclear matter density. If not given, it is setup as the nuclear denisty 0.138 fm^-3 (r0=1.2 fm)|
| 31 | float | OK | Include Heisenberg exchange operator for -H\*P(t) for the DD term. x0H = H/t3 |
| 32 | float | OK | Include Majorana exchange operator for -M\*P(s)\*P(t) for the DD term. x0M = M/t3|
| \* | \* | Developing. |


To introduce several zero-range density dependent terms (up to 3), include the modes from 33 to 42 for including the t3, x0, x0-Heissenberg, x0-Majorana and alpha of each term. It cannot be used with options 21,22 and it is not tested with the cutoff options (11,12). The first term constants (including 31,32) will be copied for the first one, include the rest of them in order for each term following these codes:
|Code|Argument|Description|
|----|----|----|
| 33, 38 | float | **t3** constant |
| 34, 39 | float | **x0** constant |
| 35, 40 | float | **x0-Heisenberg** constant (same as 31)|
| 36, 41 | float | **x0-Majorana** constant (same as 32) |
| 37, 42 | float | **alpha** constant |

Append more, in the same order, to introduce more terms.

## Contributors 

* Miguel de la Fuente Escribano (Universidad Autónoma de Madrid-UAM)
* Original TAURUS_vap creators. Benjamin Bally (CEA Paris-Saclay) and Tomás R. Rodríguez Frutos (Universidad Complutense de Madrid-UCM)

We also thank the people that helped us benchmark and test the code.



