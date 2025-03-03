# qvscode

*qvscode* is a script that can be run on NCAR systems to start a new VSCode session on a compute node.  The script can either take user input via terminal prompts or source a settings file in your home directory or a defined path.

## Launching a VSCode session using NCAR compute node job

You must have a running login session within VSCode to launch the *qvscode* script.  Connect to the login node in VSCode using the method described here: https://ncar-hpc-docs.readthedocs.io/en/latest/environment-and-software/vscode/#connecting-to-compute-nodes  

The command `qvscode` can be called directly in the latest NCAR software stack 24.12.  The `qvscode` script is only available on Casper.  We are looking to add this script to Derecho in the future.

Alternatively, you can clone the repository and call it a login node launch the script:

`bin/qvscode`

## Procedure

1. Open VSCode on your local machine
2. In VSCode, connect to a Casper login node using RemoteSSH as described [here](https://ncar-hpc-docs.readthedocs.io/en/latest/environment-and-software/vscode/#connecting-to-derecho-or-casper)
3. Once connected to the login node, open up a new terminal window (Ctrl+Shift+\`)
4. Load the ncarenv/24.12 using `module load ncarenv/24.12` in the terminal
5. Call `qvscode`
6. Enter a valid project code and follow the prompts to launch a PBS job
7. A new VSCode window will open and connect to the compute node when your PBS job has started

Step 6 will not prompt you for a project code if you have PBS_ACCOUNT defined or if you are using the [Settings](#settings) mode and have set your project code with in `.qvscode_settings` file.

### Usage
```
Usage: qvscode [-b | --bypass] [-p | --path] [-h | --help]
-b | --bypass: Use prompt mode to enter job arguments and bypass the user settings file
-p | --path: Provide the path to a qvscode settings file to use in settings mode
-h | --help: Display this help message
```

### Operating Modes

#### Prompt Mode
*Prompt Mode* will prompt the user for the values needed to launch the PBS job.  It contains default values to make launching a job faster.  The default modes assume basic CPU activity with values of:

```
Account:  $PBS_ACCOUNT
Nodes:    1         
CPUs:     1         
Memory:   10GB         
GPUs:     0         
Walltime: 02:00:00         
Path:     $(pwd)
```

If you do not have a variable `PBS_ACCOUNT` setup then you will always be prompted to enter a valid project.

After the project prompt you will be asked if you would like to use the default values.  Answering 'N' to the default values prompts the user to enter variables for each of these basic job settings.  Note that the bracketed values are the default values and will be used if you do not enter any value.  After entering the basic settings you will be prompted to enter advanced options.  The advanced options are:

```
CPU Type:    
GPU Type:    
MPI Procs:   
OMP Threads: 
```

Prompt Mode Structure:
```
- Basic options:
    - Project
    - Number of CPUs
    - Memory
    - Number of GPUs
    - Walltime
    - Path
- Advanced options:
    - CPU type
    - GPU type
    - MPI Procs
    - OMP Threads
```

#### Settings Mode

If the script finds a `qvscode_settings` file in `$HOME/.qvscode_settings` then it will import the variables into the script. The template requires specific keywords to pull values in.  It is *highly* recommended to copy the repository's `qvscode_settings_template` to your `$HOME` directory, rename it to `.qvscode_settings`, and then modify the values for each argument instead of manually creating the settings file.  The template can also be found in `/glade/work/csgteam/qvscode` The format for the template:

```
system=casper
project=SCSG0001
nodes=1
num_cpus=1
cpu_type=
memory=4GB
mpi_procs=1
ompthreads=1
num_gpus=
gpu_type=
walltime=01:00:00
path=$(pwd)
```

You can specify a custom settings file to quickly launch jobs with different resources.  Use the `-p` flag to set a custom path for the qvscode settings file:

`qvscode -p /path/to/settings/file`

### New VSCode Job Window

If the qsub arguments are valid then a new VSCode window will launch and connect to the compute node's hostname.  You will be required to enter your NCAR two-factor authentication again and may be asked to verify the SSH connection if you have not connected to the node previously.  You can close the new window and reconnect using the command provided by the script at job launch from the login node.  The format will be:

```code --remote ssh-remote+$USER@<computenode_hostname>.hpc.ucar.edu```

Pressing `Ctrl+C` from the login node will kill the PBS job and end your compute node session.

### Logs

Log files are stored in `$SCRATCH/.qvscode_logs` and show the user arguments and job submission details.
