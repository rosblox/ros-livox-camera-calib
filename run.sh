#!/bin/bash

docker run -it --rm --privileged --net=host \
--volume $(pwd)/livox_camera_calib:/catkin_ws/src/livox_camera_calib \
-e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix \
ghcr.io/rosblox/ros-livox-camera-calib:melodic