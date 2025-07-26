Server schat

A free messenger server schat that you can deploy on any device

Сервер свободного месседжера schat, который вы можете развернуть на любом устройстве 

генерация прото моделей:
export PATH="$PATH:$HOME/.pub-cache/bin"
protoc --dart_out=grpc:lib/generated -Iproto proto/auth.proto     //для модели пользователя
protoc --dart_out=grpc:lib/generated -Iproto proto/chats.proto     //для модели чатов с сообщениями 
protoc --dart_out=grpc:lib/generated -Iproto proto/call.proto     //для модели звонков
protoc --dart_out=grpc:lib/generated -Iproto proto/social.proto     //для модели 

миграция базы данных:
dart run build_runner build

dart run stormberry migrate
DB_HOST_ADDRESS=localhost
DB_PORT=5432 
DB_NAME=schat
DB_SSL=false
DB_USERNAME=postgres
DB_PASSWORD=postgres

dart run stormberry migrate --db=schat --host=localhost --port=5432 --username=postgres --password=postgres --[no-]ssl
dart run stormberry migrate --db=schat --host=192.168.0.51 --port=5432 --username=postgres --password=postgres --no-ssl  -o ./init_db


envoy -c ./envoy.yaml

Run to docker:
docker-compose up -d --build