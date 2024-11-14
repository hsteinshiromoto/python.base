FROM hsteinshiromoto/alpix:latest

RUN nix-env -iA nixpkgs.pyenv nixpkgs.poetry
