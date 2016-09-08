# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Pep/8 terminal engine for submissions
#
# TODO: Pep8Term is crap software to install and to execute.
# Currently, this program assume that it is installed in the subdirectory `pep8term`.
# Use `make pep8term` to install and compile it.
module pep8

import engine_base

# The absolute path of a `file` in pep8term.
# Aborts if not found
fun pep8term(file: String): String do
	var dir = "pep8term"
	if not dir.file_exists then
		print_error "{dir}: does not exists. Please install it (make pep8term)."
		exit 1
	end
	file = dir.realpath / file
	if not file.file_exists then
		print_error "{file}: does not exists. Please check the pep8term installation."
		exit 1
	end
	return file
end

# Handler for a Pep/8 submission
class Pep8Engine
	super Engine

	redef fun language do return "Pep/8"

	redef fun compile(program)
	do
		var player = program.player
		var mission = program.mission
		var source = program.source

		# Get a workspace
		# We need to create a unique working directory
		# The following is not thread/process safe
		var ws
		var z = 0
		loop
			# Get a unique timestamp for this submission
			var date = (new TimeT).to_i.to_s + "_" + z.to_s
			ws = "out/{date}"
			if not ws.file_exists then break
			z += 1
		end
		ws.mkdir
		program.workspace = ws
		print "{player}/{mission} compiled in {ws}"

		# Copy source
		var sourcefile = ws / "source.pep"
		source.write_to_file(sourcefile)

		# Copy scripts and requirements
		system("cp {pep8term("trap")} {pep8term("pep8os.pepo")} {pep8term("asem8")} {pep8term("pep8")} share/peprun.sh {ws}")

		# Copy each test input
		var tests = program.mission.testsuite
		var i = 0
		for test in tests do
			i += 1
			var tdir = "test{i}"
			# We get a subdirectory (a testspace) for each test case
			var ts = ws / tdir
			ts.mkdir

			var ifile = ts / "input.txt"
			test.provided_input.write_to_file(ifile)
		end

		# Run the payload
		system("cd {ws} && bash peprun.sh")


		# Retrieve information
		var objfile = ws / "source.pepo"
		if not objfile.file_exists then
			var err = (ws/"cmperr.txt").to_path.read_all
			program.compilation_messages = "compilation error: {err}"
			return false
		end

		# Compilation OK: get some score
		program.size_score = objfile.to_path.read_all.split(" ").length - 1

		return true
	end

	redef fun run_test(program, test) do
		var res = new TestResult(test, program)

		var tdir = "test{program.results.length + 1}"
		# We get a subdirectory (a testspace) for each test case
		var ws = program.workspace.as(not null)
		var ts = ws / tdir

		# Chech the output
		var ofile = ts / "output.txt"
		var sfile = ts / "sav.txt"
		test.expected_output.write_to_file(sfile)

		var instr_cpt = (ts/"timescore.txt").to_path.read_all.trim
		if instr_cpt.is_int then res.time_score = instr_cpt.to_i

		# Compare the result with diff
		# TODO: some HTML-rich diff? Maybe client-side?
		res.produced_output = ofile.to_path.read_all
		var r = system("cd {ws} && echo '' >> {tdir}/output.txt && diff -u {tdir}/sav.txt {tdir}/output.txt > {tdir}/diff.txt")
		if r != 0 then
			var out = (ts/"diff.txt").to_path.read_all
			res.error = "Error: the result is not the expected one\n{out}"
			return res
		end

		return res
	end
end
