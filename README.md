Container for building Haskell code. It provides:
* Cabal 3.6.0.0
* GHC 8.10.7
* GHCJS 8.10.7

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
This script mounts the host's current working directory as `/workdir` inside
container and proceeds into an interactive shell session within the created
container.
