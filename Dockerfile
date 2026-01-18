FROM dart:3.10.6 as builder
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/schat_api.dart -o server

FROM ubuntu:24.10 as runner
COPY --from=builder /app/server /server
EXPOSE 4400
CMD [ "/server" ]