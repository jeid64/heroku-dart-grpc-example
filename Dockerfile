# Specify the Dart SDK base image version using dart:<version> (ex: dart:2.12)
FROM dart:stable AS build
#FROM dart:stable


# Resolve app dependencies.
WORKDIR /app
#COPY pubspec.* ./

# Copy app source code and AOT compile it.
COPY . .
WORKDIR /app/example/helloworld

#RUN pwd && sleep 60
RUN dart pub get

# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server
RUN dart compile exe bin/client.dart -o bin/client

# # Build minimal serving image from AOT-compiled `/server` and required system
# # libraries and configuration files stored in `/runtime/` from the build stage.
FROM envoyproxy/envoy:v1.21-latest
COPY --from=build /runtime/ /
COPY --from=build /app/example/helloworld/bin/server /app/bin/
COPY --from=build /app/example/helloworld/bin/client /app/bin/
COPY --from=build /app/envoy-client.yaml /app
COPY --from=build /app/envoy-server.yaml /app

RUN apt-get update && apt-get install gettext -y

# Start server.
EXPOSE 50051
#CMD ["/app/example/helloworld/bin/server"]