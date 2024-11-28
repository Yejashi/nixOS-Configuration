sudo nixos-rebuild switch -I nixos-config=./system/configuration.nix

nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager
nix-channel --update

home-manager switch -f users/yejashi/home.nix 
