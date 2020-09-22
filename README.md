This docker image deploys the Haskell's stack, as well as provides
a convenient environment for experimenting with Haskell code.
I made this image for the purposes of learning Haskell.

## Usage

### Build image

Run the build script:
```
$ <repo-dir>/build
```

### Run container

Run shell inside the container:
```
$ <repo-dir>/run
```
This script mounts the host's working directory as `/workdir` inside container
and proceeds into an interactive shell session within the created container.
