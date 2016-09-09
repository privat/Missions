# Small script that executes in a docker a command in a given sub-directory of `out`
#
# usage:
#   ./saferun.sh dir command

dir=$1
cmd=$2

run=$dir/run.sh

echo "$cmd" > "$run"
chmod +x "$run"

if ! test -e "$run"; then
	echo >&2 "Error. '$run' not found."
	exit 1
fi

rdir=`readlink -f "$dir"`

docker run --rm -v "$rdir":/work mission_worker 2>&1 | tee "$dir/log.txt"
