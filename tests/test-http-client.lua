--[[

Copyright 2015 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

local http = require('http')

local HOST = '127.0.0.1'
local PORT = 10082

local body = "Hello world\n"

require('tap')(function(test)
  test("http-client", function(expect)
    function onServerConnection(req, res)
      res:setHeader("Content-Type", "text/plain")
      res:setHeader("Content-Length", #body)
      res:finish(body)
    end

    function onResp(resp)
      p('resp:on("complete")')

      function onData(data)
        p('resp:on("data")', data)
        assert(data == body)
      end

      resp:on('data', expect(onData))
    end

    http.createServer(onServerConnection):listen(PORT)

    http.request({port=PORT, host=HOST}, onResp)
  end)
end)
