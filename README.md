# Signed Distance Field (SDF) plugin for Brayns

This repository is about Signed Distance Fields (SDF) plugin for Brayns.

https://github.com/BlueBrain/Brayns

## About

The following platforms and build environments are tested:

* Linux: Ubuntu 16.04, Debian 9, RHEL 6.8 (Makefile, x64)

## Building from Source

```
  mkdir Build
  cd Build
  CMAKE_PREFIX_PATH=<OSPRAY_INSTALLATION_DIR> cmake ..
  make
```

Where OSPRAY_INSTALLATION_DIR is the OSPRay installation folder

## Screenshots

![SDF](./doc/SDF.png)
