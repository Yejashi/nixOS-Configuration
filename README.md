It is the morning of Thanksgiving 2024. I wonder, as i write this, why i put myself through the suffering colloquially known as linux. Alas, pain begets progress and so i shall.

### Step 1
Download the gnome [iso](https://nixos.org/download/#nixos-iso) and you know the rest.

### Step 2
Once you've booted into the OS then you need to temporarly aquire git as it is not installed by default. 

This is done through the following command: 
```
nix-shell -p git
```

In case this has not already been done, you also need to label the root partition as follows: 
```
sudo e2label /dev<root_partition> root
```

### Step 3
Clone this repository 
```
git clone https://github.com/Yejashi/nixOS-Configuration.git
```

Checkout the `gnome` branch.

### Step 4
The next order of things is to get any submodules contained within this repository. This can be done by:
```
git submodule update --init --recursive
```

### Step 5
Please `cd` into wherever you have the repository installed.

Now generate the hardware configuration:
```
nixos-generate-config --show-hardware-config > system/hardware-configuration.nix
```

Then generate the system:
```
sudo nixos-rebuild switch -I nixos-config=./system/configuration.nix
```

This will install the system configurations.

### Step 6
Now, its time to install any necessary packages and dot files using the home-manager.

First, let's home-manager to the nix channels: 
```
nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager
```

Now update the channels: 
```
nix-channel --update
```

Now, log out and log back in.

Finally install: 
```
nix-shell '<home-manager>' -A install
```

### Step 7
Now, let's begin the installation: 
```
home-manager switch -f users/yejashi/home.nix
```

***

### Steps i haven't been able to add into the nixOS config yet.

Add flathub repository:
```
sudo flatpak remote-add flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```
