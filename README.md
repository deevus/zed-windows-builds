# Unofficial nightly builds of Zed for Windows

## Installation

Install using [Scoop](https://scoop.sh/)

```
scoop bucket add versions
scoop install versions/zed-nightly
```

## Is it safe?

This repository is just a [simple GitHub workflow](./.github/workflows/build.yml) that builds Zed from `main` and publishes a release every night at UTC+0000. (Additionally on push for testing).

See the [Zed homepage](https://zed.dev/) or [official repository](https://github.com/zed-industries/zed) for more details.
