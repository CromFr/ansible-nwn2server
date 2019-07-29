
# Neverwinter Nights 2 server playbook

This playbook installs the NWN2 server running in a Windows virtual machine (with KVM acceleration), hosted on Ubuntu Server.

It was mainly designed for _La Colère d'Aurile_, a French persistent/action RPG server.

> Note: You should run this on a dedicated server, as KVM nested virtualization can be buggy (I tested on an OVH vps server and got random dead locks related to KVM) 


# Features
- MySQL compatible server (MariaDB)
- UFW (firewall) configuration to allow nwn2server
- Qemu + KVM virtualization of a Windows guest
    + You __must__ provide your own disk image
    + Configuration of windows to run nwn2server
    + NWNX4 with the default plugins
    + Start nwn2server on boot
    + SPICE remote control with KVM guest tools
- NFS server to share files between the host & guest (more efficient than Samba for small files)
- The windows remote control & MySQL database are only accessible on localhost (ie you have to use a SSH tunnel to access those services)


# Available Ansible roles

- `nwn2server-common`
    + General setup for running one or more `nwn2server`
- `nwn2server`
    + The NWN2 server, with its associated nwnx4, module, haks, ... and windows virtual machine.
    + You can run multiple nwn2 servers in multiple virtual machines by adding this role with different `nwn2_path_root` values
- `windows-nwn2server`
    + Windows only
    + Setup required software to run the nwn2server & nwnx4 processes


# Preparation

## Configuration
Copy the files in `templates/` to tune your desired configuration and remove the `.example` part in their name.


## NWN2 server binaries
To populate the directory `staging/nwn2server` with the necessary game files to run the server on the windows virtual machine, run the following command:
```sh
./assemble-nwn2server.sh /path/to/nwn2/install/folder
```



## Host setup

- For Ubuntu server 18.04 64 bit
- Required packages:
    + `python`
- Add your SSH key to the root user

## Guest windows setup

- Tested on Windows Server 2012 R2 64 bit and Windows Server 2008 R2 64 bit
- Remote control is done using WinRM over a ssh tunnel
- Disk image must be compressed using the xz format
- To execute the ansible scripts for windows, you need to setup a SSH tunnel as WinRM port is only open for localhosts: `ssh -NL 5985:127.0.0.1:5985 root@yourserver.com`

> Note: you also need to install the `pywinrm` python2 module on your dev machine

### Qemu disk image creation

- Create the disk image
```sh
qemu-img create -f raw nwn2server-vmdisk.raw 15G
```

> Note: I had some issues with qcow2 format and nested KVM virtualization, so I used raw format for security. Qcow2 has many advantages, and you can give it a try by setting Ansible variable `qemu_disk_format: "qcow2"`

- Download [virtio windows drivers](https://fedoraproject.org/wiki/Windows_Virtio_Drivers#Direct_download)
```sh
wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

- Start the Qemu virtual machine on your host
```sh
# Replace PathToTheWindowsInstallDisk with the path to the Windows install disk
qemu-system-x86_64 \
  -name "NWN2Server" \
  -runas $USER \
  \
  -enable-kvm \
  -cpu host \
  -smp cores=1,threads=1,sockets=1 \
  -m 2.5G \
  \
  -drive file="./nwn2server-vmdisk.raw",format=raw,if=virtio \
  \
  -boot d \
  -drive file="PathToTheWindowsInstallDisk",media=cdrom \
  -drive file=virtio-win.iso,media=cdrom \
  \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostname=nwn2server \
  \
  -device piix3-usb-uhci \
  -device pvpanic \
  \
  -vga qxl \
  -spice addr=127.0.0.1,port=3389,disable-ticketing \
  -device usb-tablet \
  -device virtio-serial \
  -chardev spicevmc,id=vdagent,name=vdagent \
  -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
  \
  -monitor stdio
```
- Connect to the VM using a SPICE client (ex: [virt-viewer](https://virt-manager.org/download/)) on `127.0.0.1:5900`
- Configure your windows VM as needed
    + During OS install, you will need to add drivers located in the virtio-win disk `X:\viostor\2k12R2\amd64\`
    + Run the following commands in powershell to enable WinRM remote control:
      ```powershell
      Invoke-WebRequest -Uri https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 -OutFile ConfigureRemotingForAnsible.ps1

      .\ConfigureRemotingForAnsible.ps1 -EnableCredSSP

      winrm set winrm/config/service '@{AllowUnencrypted="true"}'
      ```
    + Optionally update the windows machine & clean windows updates:
        * `Dism.exe /online /Cleanup-Image /StartComponentCleanup`
        * `Dism.exe /online /Cleanup-Image /SPSuperseded`
    + Optionally defragment & fill empty files with 0 using `sdelete.exe -z C:` for better compression

- Shutdown the windows VM
- Compress the disk image using `xz -k -T0 nwn2server-vmdisk.raw`


# Ansible usage

Basically you need to write an inventory file:

```ini
[nwn2server_host]
your-server-address.com

[nwn2server_host:vars]
# Add any variables from roles/*/defaults you want to override
nwnx4_nwn2server_parameters="-moduledir MagicalWorld"
qemu_disk_download_url="./nwn2server-vmdisk.raw.xz"
qemu_disk_format=raw
mysql_password="SecretMySQLPassword"
servervault_ntfspart_size=3G

[nwn2server_winguest]
# SSH tunnel entry point, 127.0.0.1 unless you are doing strange things :)
127.0.0.1

[nwn2server_winguest:vars]
ansible_user=Administrator
ansible_password="YourWindowsPassword"
ansible_port=5985
ansible_connection=winrm
windows_version=win2012r2

# Add any variables from roles/windows-nwn2server/defaults you want to override
production=False
```

Then to execute the ansible-playbook:
- `ansible-playbook -i inventoryfile host.yml` To connect & setup the Ubuntu host system
- `ansible-playbook -i inventoryfile winguest.yml` To connect & setup the windows virtual machine (dont forget to start the SSH tunnel)


You can also create your own playbook file, to build your own custom server, running for example multiple nwn2server instances (untested).
