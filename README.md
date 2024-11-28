It is the morning of Thanksgiving 2024. I wonder, as i write this, why i put myself through the suffering colloquially known as linux. Alas, pain begets progress and so i shall.

### Step 1
Download the gnome [iso](https://github.com/Yejashi/nixOS-Configuration.git) and you know the rest.

### Step 2
Once you've booted into the OS then you need to temporarly aquire git as it is not installed by default. 

This is done through the following command: `nix-shell -p git`

### Step 3
Clone this repository `https://github.com/Yejashi/nixOS-Configuration.git`.

Checkout the `gnome` branch.

### Step 4
The next order of things is to get any submodules contained within this repository. This can be done by `git submodule update --init --recursive`

### Step 5
Please `cd` into wherever you have the repository installed.

Then do the following `sudo nixos-rebuild switch -I nixos-config=./system/configuration.nix`. This will install the system configurations.

### Step 6
Now, its time to install any necessary packages and dot files using the home-manager.

First, let's home-manager to the nix channels: `nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager`

Now update the channels: `nix-channel --update`

### Step 7
Now, let's begin the installation: `home-manager switch -f users/yejashi/home.nix`
