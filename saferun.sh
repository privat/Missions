# Small script that executes in a sibling docker a command in a given sub-directory of `out`
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

# The protocol is the following
#
# * put a `todo.token` in the target directory to indicate which one to process
# * put a `todo.token` in the watched directory to wake up the runner
# * wait for a `done.token`
#
# * the runner wakes up, find the token, execute in a docker.
# * the runner writes a `done.token`.

# Prepare `todo` tokens
rm -f "$dir/done.token"
touch $dir/todo.token
echo "$dir" > out/todo.token
echo "Fire: '$dir/todo.token'"

# Wait for the `done` token
while :; do
	test -e "$dir/done.token" && break
	echo "Wait... $dir/done.token"
	inotifywait -q -t 10 -e create -e modify "$dir"
done

# End the job
echo "Done: `ls -lh $dir/done.token`"
cat "$dir/log.txt"
