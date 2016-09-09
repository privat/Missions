The various scripts and Docker images to compile and execute in possible sandboxed environment

The core principle, is the following:

* each submission is associated to a workdir
* the web server prepare some specific payload in the workdir with bash script (from the engine), source-code (from the submission) and inputs (from the testcases)
* the script is then executed by the test environment and produce results files
* after the execution, the web server check the result files and compare them to what is expected

The way the script is executed in thought the command

    share/saferun.sh <dir> <command>

Whereas saferun.sh is a symbolic link towards one of the specific schemes:

* `saferun_bash.sh` (debug) just run the command, as is, in the directory with the current user
* `saferun_docker.sh` (still debug) run the command in a specific spawned docker image `mission_worked`
* `saferun_docker_spool.sh` (prod) mark the command to be executed by the background running `mission_runner`


The `saferun_docker_spool.sh` scheme is in fact quite complex:

* `mission_runner` watches and waits for modifications in the workdir
* `saferun_docker_spool.sh` notify (thought th FS) 
