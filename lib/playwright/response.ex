defmodule Playwright.Response do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [:status, :url]

  require Logger

  def new(parent, args) do
    # Logger.info("Response.new/2 args: #{Jason.encode!(args)}")
    channel_owner(parent, args)
  end

  # initializer
  # ---------------------------------------------------------------------------
  def ok(r) do
    r.status === 0 || (r.status >= 200 && r.status <= 299)
  end

  # def status(r) do
  #   r.status
  # end


  # reference
  # ---------------------------------------------------------------------------


  # API call
  # ---------------------------------------------------------------------------


  # def body(subject) do

  # end
end

# backlog:
# - from initializer: (???)
#   - [ ] url()
#   - [x] ok()
#   - [n] status()
#   - [ ] status_text()
# - async/await (API call):
#   - [ ] all_headers()
#   - [ ] headers_array()
#   - [ ] header_value()
#   - [ ] header_values()
#   - [ ] finished()
#   - [ ] body()
#   - [ ] text()
#   - [ ] json()
#   - [ ] server_addr()
#   - [ ] security_details()
# - reference:
#   - [ ] request()
#   - [ ] frame()

# console.info
# ----> SEND {
#   id: 5,
#   guid: 'response@8b460320a2000f1f7a9b19bf01173f90',
#   method: 'body',
#   params: undefined
# }

#   at Connection.sendMessageToServer (node_modules/playwright-core/lib/client/connection.js:142:13)

# console.info
# <---- RECV {
#   guid: 'frame@ba9a073a573b36964454068e1a0b6410',
#   method: 'loadstate',
#   params: { add: 'domcontentloaded' }
# }

#   at Connection.dispatch (node_modules/playwright-core/lib/client/connection.js:176:15)

# console.info
# <---- RECV {
#   guid: 'page@7faa3a22e662802c2b33cb086b8456a2',
#   method: 'domcontentloaded',
#   params: undefined
# }

#   at Connection.dispatch (node_modules/playwright-core/lib/client/connection.js:176:15)

# console.info
# <---- RECV {
#   id: 5,
#   result: {
#     binary: 'PGRpdiBpZD0ib3V0ZXIiIG5hbWU9InZhbHVlIj48ZGl2IGlkPSJpbm5lciI+VGV4dCwKbW9yZSB0ZXh0PC9kaXY+PC9kaXY+PGlucHV0IGlkPSJjaGVjayIgdHlwZT1jaGVja2JveCBjaGVja2VkIGZvbz0iYmFyJnF1b3Q7Ij4KPGlucHV0IGlkPSJpbnB1dCI+PC9pbnB1dD4KPHRleHRhcmVhIGlkPSJ0ZXh0YXJlYSI+PC90ZXh0YXJlYT4KPHNlbGVjdCBpZD0ic2VsZWN0Ij48b3B0aW9uPjwvb3B0aW9uPjxvcHRpb24gdmFsdWU9ImZvbyI+PC9vcHRpb24+PC9zZWxlY3Q+Cg=='
#   }
# }

#   at Connection.dispatch (node_modules/playwright-core/lib/client/connection.js:176:15)

# console.info
#     body <div id="outer" name="value"><div id="inner">Text,
# more text</div></div><input id="check" type=checkbox checked foo="bar&quot;">
# <input id="input"></input>
# <textarea id="textarea"></textarea>
# <select id="select"><option></option><option value="foo"></option></select>
