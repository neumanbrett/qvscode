#!/bin/bash

# function usage {
# Usage: $my_name
# This command launches a PBS job on a NCAR HPC system and opens a VSCode window on the compute node.
# It contains two modes for populating the PBS arguments required to launch a job:

# User Settings file mode:
#     - Looks for a file named $HOME/.vscc_settings for default values
#     - Format for settings file:
#         system=casper
#         project=SCSG0001
#         nodes=1
#         num_cpus=4
#         cpu_type=
#         memory=6GB
#         mpi_procs=4
#         ompthreads=1
#         gpu_count=0
#         gpu_type=v100
#         walltime=01:00:00
#         path=$HOME

# User prompt mode:
#     - Basic options:
#         - Project
#         - Number of CPUs
#         - Memory
#         - Number of GPUs
#         - Walltime
#         - Path
#     - Advanced options:
#         - CPU type
#         - GPU type
#         - MPI Procs
#         - OMP Threads
#

# Project: 
# - NCAR Project Account
#     - Default: $PBS_ACCOUNT
#         - User defined variable in startup scripts
#     - 
# }

my_name=$(basename $0)
my_root=$(cd $(dirname $(readlink -f $0))/..; pwd)
launch_script=/glade/u/home/bneuman/scripts/vscode/qvscode/launch.pbs
mkdir -p $SCRATCH/.qvscode_logs
qvscode_log=$SCRATCH/.qvscode_logs/qvscode.$(date +"%Y%m%d%H%M%S").log

# Determine the NCAR system and exit if invalid
hostname=$(hostname)
if [[ "$hostname" =~ ^derecho.* ]]; then
    queue="main"
    vshost="derecho"
    echo "VSCode compute access is not available on Derecho, please launch this script on Casper"
    echo "Exiting..."
    exit 1
elif [[ "$hostname" =~ ^casper.* ]]; then
    queue="casper"
    vshost="casper"
    echo "Submitting job to Casper"
else
    echo "This script must be run on a host named derecho* or casper-login*"
    exit 1
fi

dav_max_cpus=128
dav_max_gpus=8

# Check to see if the $HOME/.qvscode_settings file exists, and if not, use the default values
if [[ -f "$HOME/.qvscode_settings" ]]; then
    echo "Using settings file: $HOME/.qvscode_settings"
    source $HOME/.qvscode_settings
    user_settings=1
else
    #echo "No settings file found. Using default values."
    user_settings=0
fi

# Parse user settings file
if [ $user_settings -eq 1 ]; then

    while IFS= read -r line; do
        if [[ $line == *"project"* ]]; then
            default_project=$(echo $line | cut -d'=' -f2)
        elif [[ $line == *"nodes"* ]]; then
            default_nodes=$(echo $line | cut -d'=' -f2)
        elif [[ $line == *"num_cpus"* ]]; then
            default_num_cpus=$(echo $line | cut -d'=' -f2)
        elif [[ $line == *"cpu_type"* ]]; then
            default_cpu_type=$(echo $line | cut -d'=' -f2)
        elif [[ $line == *"memory"* ]]; then
            default_memory=$(echo $line | cut -d'=' -f2)
        elif [[ $line == *"mpi_procs"* ]]; then
            default_mpi_procs=$(echo $line | cut -d'=' -f2)
        elif [[ $line == *"ompthreads"* ]]; then
            default_ompthreads=$(echo $line | cut -d'=' -f2)
        elif [[ $line == *"gpu_count"* ]]; then
            default_gpu_count=$(echo $line | cut -d'=' -f2)
        elif [[ $line == *"gpu_type"* ]]; then
            default_gpu_type=$(echo $line | cut -d'=' -f2)
        elif [[ $line == *"walltime"* ]]; then
            default_walltime=$(echo $line | cut -d'=' -f2)
        elif [[ $line == *"path"* ]]; then
            default_path=$(echo $line | cut -d'=' -f2 | sed 's/^ *//;s/ *$//')
            eval default_path=$default_path
        fi
    done < "$HOME/.qvscode_settings"

# User settings file not found, use the default values
else
    echo "User Prompt Mode"
    default_project=$PBS_ACCOUNT
    default_nodes="1"
    default_num_cpus="1"
    default_cpu_type=""
    default_memory="10GB"
    default_mpi_procs="1"
    default_ompthreads="1"
    default_gpu_count="0"
    default_gpu_type="v100"
    default_walltime="02:00:00"
    default_path=$(pwd)
    jobdatetime=$(date +"%Y%m%d%H%M%S")
fi    


# Required project argument
if [ "$user_settings" -eq 1 ]; then
    project=$default_project
    nodes=$default_nodes
    num_cpus=$default_num_cpus
    cpu_type=$default_cpu_type
    memory=$default_memory
    mpi_procs=$default_mpi_procs
    ompthreads=$default_ompthreads
    gpu_count=$default_gpu_count
    gpu_type=$default_gpu_type
    walltime=$default_walltime
    eval path=$default_path
else
    read -p "Enter Project [${default_project}]: " project
    if [[ -z "$project" ]]; then
        usage
        exit 1
    else
        project=${project:-$default_project}
    fi
fi

# Ask if user wants default values
if [[ "$user_settings" -eq 0 ]]; then
    echo -e "Do you want to use default resource and path values:\
        \nNodes:    $default_nodes \
        \nCPUs:     $default_num_cpus \
        \nMemory:   $default_memory \
        \nGPUs:     $default_gpu_count \
        \nWalltime: $default_walltime \
        \nPath:     $default_path" 
    read -p "(Y/N) [default: Y]: " use_defaults
    use_defaults=${use_defaults:-Y}
fi


if [[ "$use_defaults" =~ ^[Nn]$ ]]; then
    read -p "Enter number of nodes [${default_nodes}]: " nodes
    nodes=${nodes:-$default_nodes}

    read -p "Enter number of CPUs [${default_num_cpus}]: " num_cpus
    num_cpus=${num_cpus:-$default_num_cpus}

    read -p "Enter memory [${default_memory}]: " memory
    memory=${memory:-$default_memory}

    read -p "Enter number of GPUs [${default_gpu_count}]: " gpu_count
    gpu_count=${gpu_count:-$default_gpu_count}

    read -p "Enter walltime [${default_walltime}]: " walltime
    walltime=${walltime:-$default_walltime}

    read -p "Enter path [${default_path}]: " path
    path=${path:-$default_path}

    read -p "Do you want to enter advanced options? (Y/N) [N]: " advanced_options
    advanced_options=${advanced_options:-N}
else
    nodes=$default_nodes
    num_cpus=$default_num_cpus
    memory=$default_memory
    gpu_count=$default_gpu_count
    walltime=$default_walltime
    path=$default_path
fi


if [[ "$advanced_options" =~ ^[Yy]$ ]] && [[ "$user_settings" -eq 0 ]]; then
    read -p "Enter CPU type [${default_cpu_type}]: " cpu_type
    cpu_type=${cpu_type:-$default_cpu_type}

    if [[ "$gpu_count" -gt 0 ]]; then
        read -p "Enter GPU type (v100, a100, h100, l40, gp100) [${default_gpu_type}]): " gpu_type
        gpu_type=${gpu_type:-$default_gpu_type}
    else
        gpu_type=${gpu_type:-$default_gpu_type}
    fi

    read -p "Enter MPI Ranks [${default_mpi_procs}]: " mpi_procs
    mpi_procs=${mpi_procs:-$default_mpi_procs}

    read -p "Enter OMP Threads [${default_ompthreads}]: " ompthreads
    ompthreads=${ompthreads:-$default_ompthreads}
fi


echo ""
echo "Starting VSCode Compute Node Job..."
echo "-----------------------------------"
echo "Project:     $project"
echo "Queue:       $queue"
echo "Nodes:       $nodes"
echo "CPUs:        $num_cpus"
echo "Memory:      $memory"
echo "Walltime:    $walltime"
echo "Path:        $path"
if [[ "$advanced_options" =~ ^[Yy]$ ]] || [[ "$user_settings" -eq 1 ]]; then
    echo "CPU Type:    $cpu_type"
    echo "GPU Type:    $gpu_type"
    echo "MPI Procs:   $mpi_procs"
    echo "OMP Threads: $ompthreads"
fi
echo "-----------------------------------"

# Function to clean up background process
cleanup() {
    echo " "
    echo "Deleting job $job_id"
    qdel $job_id
    #kill $pbsjob_pid
}

convert_to_seconds() {
    IFS=: read -r hours minutes seconds <<< "$walltime"
    total_seconds=$((hours * 3600 + minutes * 60 + seconds))
    echo $total_seconds
}
walltime_seconds=$(convert_to_seconds)

qsub_cmd () {
    # Base case arguments [ USER SETTINGS -eq 0 ] && [ ADVANCED OPTIONS -eq 0]
    base_args="-A $project -q $queue -N qvscode_${USER}" 
    select_args="-l select=$nodes:ncpus=$num_cpus:mem=$memory" 
    walltime_arg="-l walltime=$walltime"
    log_args="-j oe -o $qvscode_log"
    launch_pbs="-v walltime_seconds=$walltime_seconds $launch_script"

    if [[ "$advanced_options" =~ ^[Yy]$ ]] || [[ "$user_settings" -eq 1 ]]; then
        if [ -n "$mpi_procs" ]; then
            select_args="$select_args:mpiprocs=$mpi_procs"
        fi

        if [ -n "$ompthreads" ]; then
            select_args="$select_args:ompthreads=$ompthreads"
        fi

        if [[ -n "$cpu_type" ]]; then
            select_args="$select_args:cpu_type=$cpu_type"
        fi

        if [[ $gpu_count -gt 0 ]]; then
            select_args="$select_args:ngpus=$gpu_count"
            if [[ -n "$gpu_type" ]]; then
                select_args="$select_args -l gpu_type=$gpu_type"
            fi
        fi
    fi

    #echo "qsub $base_args $select_args $walltime_arg $launch_pbs"
    echo "qsub $base_args $select_args $walltime_arg $log_args $launch_pbs"
}

# --- Launch the job with PBS scheduler and collect the job ID --- #
qsub_call=$(qsub_cmd)
echo "Qsub request: $qsub_call"
job_id=$(eval $qsub_call)
qsub_status=$?

# Check that job ID was produced
if [[ $qsub_status != 0 ]]; then
    echo $qcmd_job
    echo "Error: error in qsub submission. Exiting ..."
    exit $qsub_status
fi

echo "$job_id"

# Trap EXIT signal (Ctrl+C) to ensure cleanup is called
trap cleanup EXIT

# Poll qstat to check if job has started
timeout=0
jobstarted=0
while [[ "$jobstarted" -eq 0 ]] && [[ "$timeout" -le 1200 ]]; do
    jobstatus=$(qstat $job_id | tail -n 1 | awk '{print $5}')

    # Polling qstat to get job status and exit loop if job is in 'R' state
    if [ "$jobstatus" == 'R' ]; then
        echo "Job $job_id has started successfully. Launching VSCode Window..."
        jobstarted=1
    fi
    sleep 1
    timeout=$((timeout+1))
done

# Get the compute node name after job has started
computenode=$(qstat -f $job_id | grep exec_host | awk '{print $3}' | cut -d'/' -f1)
echo $computenode

# Command to launch a new VSCode window on the compute node
launchvsc() {
    # If no path provided
    if [ -z "$path" ]; then
        code --remote ssh-remote+$USER@$computenode.hpc.ucar.edu
    # If path provided
    else
        code --folder-uri "vscode-remote://ssh-remote+$USER@$computenode.hpc.ucar.edu/$path"
    fi
}
launchvsc

#vscode_cmd="code --remote ssh-remote+$USER@$vshost.hpc.ucar.edu $path"
echo "----------------------------------- "
echo "You can reconnect to this session by running the following command on a login node terminal: "
echo "code --remote ssh-remote+$USER@$computenode.hpc.ucar.edu"
echo "----------------------------------- " 
echo "Press Ctrl+C to kill the job and cleanup the VSCode session..."

convert_to_seconds() {
    IFS=: read -r hours minutes seconds <<< "$walltime"
    total_seconds=$((hours * 3600 + minutes * 60 + seconds))
    echo $total_seconds
}

walltime_seconds=$(convert_to_seconds)

sleep $walltime_seconds 

cleanup