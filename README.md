# anone

anone API server

## API docs

### API

#### send audio text

POST /api/<from>/audios

- <from>: child or papa

request data

- to: child or papa
- text: audio text

Example:

curl -d "to=child" -d "message=Hello" http://localhost:4567/api/papa/audios

-> {"content":{"id":14,"from":"papa","to":"papa","type":"audio","message":"Hello","created_at":"2016-03-20T12:18:29+09:00"},"post_path":"/api/papa/audios/14","status":"ok"}

Then post audio binary data. use response "post_path" key's value (ex. "/api/papa/audios/14")

#### send audio binary data

POST /api/<from>/audios/<id>

Example:

curl -H "Content-Type:application/octet-stream" --data-binary @audio.wav http://localhost:4567/api/papa/audios/19

#### send stamp text

POST /api/<from>/stamps

- <from>: child or papa

request data

- to: child or papa

Example:

curl -d "to=child" http://localhost:4567/api/papa/stamps

-> {"content":{"id":19,"from":"papa","to":"child","type":"stamp","message":null,"created_at":"2016-03-20T12:26:02+09:00"},"post_path":"/api/papa/stamps/19","status":"ok"}

Then post audio binary data. use response "post_path" key's value (ex. "/api/papa/stamps/19")

#### send stamp binary data

POST /api/<from>/stamps/<id>

Example:

curl -H "Content-Type:application/octet-stream" --data-binary @stamp.png http://localhost:4567/api/papa/stamps/19

#### get messages

GET /api/<user>/stamps

- <user>: child or papa

Query

- since: Greater than the date(use created_at)
- limit: limit message count(default 1)

Example:

curl "http://localhost:4567/api/papa/messages?since=2016-03-20T11:44:44+09:00"

Audio message

-> [{"id":11,"from":"papa","to":"papa","type":"audio","message":"Hello","created_at":"2016-03-20T11:47:39+09:00"}]

Stamp message

-> [{"id":11,"from":"papa","to":"papa","type":"audio","message":"Hello","created_at":"2016-03-20T11:47:39+09:00"}]
