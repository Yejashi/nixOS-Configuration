It is the morning of Thanksgiving 2024, i wonder, as i write this, why i put myself through the suffering colloquially known as linux. Alas, pain begets progress and so i shall.


git submodule update --init --recursive

sudo nixos-rebuild switch -I nixos-config=./system/configuration.nix

nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager
nix-channel --update

home-manager switch -f users/yejashi/home.nix 
