Docker files for the logankennelly/arduino-cli-esp8266 image.

NOTE: This is still a work in progress.

# Build

```
docker build -t logankennelly/arduino-cli-esp8266:latest .
```

# Non-ESP8266 Builds

To slim down the image, skip installing `esptool.py`:

```
docker build --target arduino-cli-base -t logankennelly/arduino-cli-base:latest .
```

You may also target other boards through the `CORE` build arg.

```
docker build --target arduino-cli-base -t logankennelly/arduino-cli-esp8266 --build_arg CORE=arduino:avr .
```
