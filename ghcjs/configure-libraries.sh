#!/usr/bin/env bash
set -e

cat ghc/libraries/ghc-boot/ghc-boot.cabal.in | \
    sed "s/@ProjectVersionMunged@/8.10.7/g" > \
        ghc/libraries/ghc-boot/ghc-boot.cabal

cat ghc/libraries/ghc-boot-th/ghc-boot-th.cabal.in | \
    sed "s/@ProjectVersionMunged@/8.10.7/g" > \
        ghc/libraries/ghc-boot-th/ghc-boot-th.cabal

cat ghc/libraries/ghc-heap/ghc-heap.cabal.in | \
    sed "s/@ProjectVersionMunged@/8.10.7/g" > \
    ghc/libraries/ghc-heap/ghc-heap.cabal

cat ghc/libraries/ghci/ghci.cabal.in | \
    sed "s/@ProjectVersionMunged@/8.10.7/g" > \
    ghc/libraries/ghci/ghci.cabal

cat ghc/libraries/template-haskell/template-haskell.cabal.in | \
    sed "s/@ProjectVersionMunged@/8.10.7/g" > \
    ghc/libraries/template-haskell/template-haskell.cabal
