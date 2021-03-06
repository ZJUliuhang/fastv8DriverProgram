module purge
module use /nopt/nrel/apps/modules/candidate/modulefiles/
if [ "${COMPILER}" == 'gnu' ]; then
    module load openmpi-gcc/1.10.0-5.2.0 mkl cmake/3.3.2 
elif [ "${COMPILER}" == 'intel' ]; then
    module load impi-intel/5.1.3-16.0.2 lapack/3.4.2/intel-16.0.2 mkl/16.2.181 cmake/3.3.2
elif [ "${COMPILER}" == 'intelPhi' ]; then
    module load impi-intel/5.1.3-16.0.2 lapack/3.4.2/intel-16.0.2 mkl/16.2.181 cmake/3.3.2
    export LD_LIBRARY_PATH=/nopt/intel/16.0/compilers_and_libraries_2016.2.181/linux/mkl/lib/mic:$LD_LIBRARY_PATH
fi
module unload epel
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:FASTDIR/fastv8/lib/
export PATH=$PATH:FASTDIR/fastv8/bin/