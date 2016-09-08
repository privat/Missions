#!/bin/bash

# simple 

# The directory, in the containter, to watch
directory=out

# The r on the in the real host.
# Since we will call the real `docker` to create a sibling container,
# we need in indicate the real path of the watched directory.
real=/home/privat/prog/missions

# Process a worker in the path.
# $1: a relative path to a `todo.token`
process() {
	dir=`dirname "$1"`
	todo_token=$1
	doing_token="$dir"/doing.token
	done_token="$dir"/done.token

	absdir=`readlink -f "$dir"`

	# Atomically consume the token
	if ! mv "$todo_token" "$doing_token"; then
		if test -e "$todo_token"; then
			echo >2 "FATAL! $todo_token cannot be removed. exit!"
			exit 1
		fi
		echo >2 "RACE? token $todo_token was removed. skip."
		return
	fi

	echo "WORK: $absdir"
	docker run --rm -v "$real/$dir":/work mission_worker 2>&1 | tee "$dir/log.txt"
	echo "DONE: $absdir $?"

	touch "$done_token"
	ls -ls "$done_token"
}

# Infinite loop, just check and run.
echo "CHECK $directory"
while :; do
	something=""
	for f in "$directory"/*/todo.token; do
		test -e "$f" || continue

		echo "SEE token $f"
		process "$f"
		something=yes
	done

	if test -z "$something"; then
		# Wait for something new in the directory.
		# Add a timeout in case of inotify drop the ball.
		inotifywait -q -e create -e modify -t 10 "$directory"
	fi
done
