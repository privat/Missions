# Copyright 2016 Alexandre Terrasa <alexandre@moz-code.org>.
#
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

module missions

import model::tracks
import mongodb::queries

redef class AppConfig
	var missions = new MissionRepo(db.collection("missions")) is lazy
end

redef class Track
	fun missions(config: AppConfig): Array[Mission] do
		return config.missions.find_by_track(self)
	end
end

class Mission
	super Entity
	serialize

	redef var id
	var track: nullable Track
	var title: String
	var desc: String

	# List of allowed languages
	var languages = new Array[String]

	var parents = new Array[String]
	var stars = new Array[MissionStar]
	var path: nullable String = null is writable

	# Number of points to solve the mission (excluding stars)
	var solve_reward: Int = 1 is writable

	# Template for the source code
	var template: nullable String = null is writable

	fun add_star(star: MissionStar) do stars.add star

	# Total number of points for the mission (including stars)
	var reward: Int is lazy do
		var r = solve_reward
		for star in stars do r += star.reward
		return r
	end

	redef fun to_s do return title

	# The set of unit tests used to validate the mission
	#
	# This is done in `Mission` instead of a subclass to limit the number of classes
	# and maybe simplify the serialization/API.
	# If a mission has no test-case, an empty array should be enough for now.
	var testsuite = new Array[TestCase]

	# Load mission parents from DB
	fun load_parents(config: AppConfig): Array[Mission] do
		var parents = new Array[Mission]
		for parent_id in self.parents do
			var parent = config.missions.find_by_id(parent_id)
			if parent == null then continue
			parents.add parent
		end
		return parents
	end

	# Load mission parents from DB
	fun load_children(config: AppConfig): Array[Mission] do
		var children = new Array[Mission]

		var track = self.track
		if track == null then return children

		for mission in track.missions(config) do
			if not mission.parents.has(id) then continue
			var child = config.missions.find_by_id(mission.id)
			if child == null then continue
			children.add child
		end
		return children
	end
end

class MissionRepo
	super MongoRepository[Mission]

	fun find_by_track(track: nullable Track): Array[Mission] do
		if track == null then return find_all
		return find_all((new MongoMatch).eq("track._id", track.id))
	end
end

# A single unit test on a mission
#
# They are provided by the author of the mission.
class TestCase
	serialize

	# The number of the test in the test-suite (starting with 1)
	var number: Int

	# The input that is feed to the tested program.
	var provided_input: String

	# The expected response from the program for `provided_input`.
	var expected_output: String
end

# Mission requirements
class MissionStar
	super Entity
	serialize

	# The star explanation
	var title: String

	# The reward (in points) accorded when this star is unlocked
	var reward: Int
end

# For stars that asks the player to minimize a quantity
class ScoreStar
	super MissionStar
	serialize

	# The value to earn the star
	var goal: Int
end

class SizeStar
	super ScoreStar
	serialize
end

class TimeStar
	super ScoreStar
	serialize
end
