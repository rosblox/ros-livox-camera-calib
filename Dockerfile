FROM ros:melodic-ros-core

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential wget \
    libgoogle-glog-dev libgflags-dev libatlas-base-dev \
    ros-${ROS_DISTRO}-cv-bridge \
    ros-${ROS_DISTRO}-eigen-conversions ros-${ROS_DISTRO}-rviz \
    ros-${ROS_DISTRO}-pcl-conversions \
    ros-${ROS_DISTRO}-pcl-ros \
    && rm -rf /var/lib/apt/lists/*

COPY ceres-solver ceres-solver
WORKDIR /ceres-solver/ceres-bin
RUN cmake .. && make -j4 && make test && make install

# Fix compilation bug, taken from https://github.com/ethz-asl/lidar_align/issues/16#issuecomment-630596839
RUN mv /usr/include/flann/ext/lz4.h /usr/include/flann/ext/lz4.h.bak && \
    mv /usr/include/flann/ext/lz4hc.h /usr/include/flann/ext/lz4.h.bak && \
    ln -s /usr/include/lz4.h /usr/include/flann/ext/lz4.h && \
    ln -s /usr/include/lz4hc.h /usr/include/flann/ext/lz4hc.h


WORKDIR /catkin_ws/src
COPY livox_camera_calib livox_camera_calib


WORKDIR /catkin_ws
RUN . /opt/ros/${ROS_DISTRO}/setup.sh && catkin_make --cmake-args -DCMAKE_BUILD_TYPE=Release

WORKDIR /
COPY resources/ros_entrypoint.sh .

# Download calibration image and pointcloud
ARG GDRIVE_IMAGE_ID=1M89FPwBMP7UHMWwktQjunMbFYwuq4v0h
ARG GDRIVE_IMAGE_NAME=0.png

ARG GDRIVE_POINTCLOUD_ID=1G2lOnvCHbX6uWnBOiVQlxUlUKzaZHCBV
ARG GDRIVE_POINTCLOUD_NAME=0.pcd

RUN wget -q --load-cookies /tmp/cookies.txt \ 
    "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=$GDRIVE_IMAGE_ID' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$GDRIVE_IMAGE_ID" -O $GDRIVE_IMAGE_NAME && rm -rf /tmp/cookies.txt && \
    wget -q --load-cookies /tmp/cookies.txt \ 
    "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=$GDRIVE_POINTCLOUD_ID' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$GDRIVE_POINTCLOUD_ID" -O $GDRIVE_POINTCLOUD_NAME && rm -rf /tmp/cookies.txt
    
WORKDIR /catkin_ws

RUN echo 'alias build="catkin_make --cmake-args -DCMAKE_BUILD_TYPE=Release"' >> ~/.bashrc
RUN echo 'alias run="roslaunch livox_camera_calib docker_calib.launch"' >> ~/.bashrc
