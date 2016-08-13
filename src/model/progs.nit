import missions
import players

redef class Mission
	
	# The set of unit tests used to validate the mission
	#
	# TODO: Do all missions have a test-suite?
	var testsuite = new Array[TestCase]
end

# A single unit test on a mission
class TestCase

	# Provided input
	var i: String

	# Expected output
	var o: String

	# Try the test case on a `program`.
	fun run(program: Program): TestResult do
		var res = new TestResult(self, program)

		print "RUN"

		return res
	end
end

# A specific execution of a test case by a program
class TestResult
	# The test case considered
	var testcase: TestCase

	# The program considered
	var program: Program

	# The produced output
	var o: nullable String = null
end

# A submitted entry from a player for a mission
class Program
	var player: Player
	var mission: Mission

	var source: String

	var results = new HashMap[TestCase, TestResult]

	fun check
	do
		print "COMPILE"

		for test in mission.testsuite do
			var result = test.run(self)
			results[test] = result
		end
	end
end
