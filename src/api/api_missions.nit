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

module api_missions

import model
import api::api_tracks
import api::engine_configuration

redef class APIRouter
	redef init do
		super
		use("/missions", new APIMissions(config))
		use("/missions/:mid", new APIMission(config))
	end
end

class APIMissions
	super APIHandler

	redef fun get(req, res) do
		res.json new JsonArray.from(config.missions.find_all)
	end
end

class APIMission
	super MissionHandler
	super AuthHandler

	redef fun post(req, res) do
		var player = get_player(req, res)
		if player == null then return
		var mission = get_mission(req, res)
		if mission == null then return

		var post = req.body

		var deserializer = new JsonDeserializer(post)
		var submission_form = new SubmissionForm.from_deserializer(deserializer)
		if not deserializer.errors.is_empty then
			res.error 400
			print "Error deserializing submitted mission: {post}"
			return
		end
		var runner = config.engine_map[submission_form.engine]
		var submission = new Submission(player, mission, submission_form.source.decode_base64.to_s)
		runner.run(submission, config)

		res.json submission
	end

	redef fun get(req, res) do
		var mission = get_mission(req, res)
		if mission == null then return
		res.json mission
	end
end
