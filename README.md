
# Neverwinter Nights 2 server playbook

This playbook installs the NWN2 server running in a Windows virtual machine (with KVM acceleration), hosted on Ubuntu Server.

It was mainly designed for _La Colère d'Aurile_, a French persistent/action RPG server. The roles `lcda-*` are specific to this server, but you can use them as they rely on free software, but be aware that they are likely to not work with your own module/server configuration.


# Ansible setup
You need to define two host groups:
- `ubuntu`: hosts running Ubuntu server, that will run the windows virtual machine and other services
- `windows`: Virtual machines running windows + nwn2server. Those machines will need a SSH tunnel as they do not publicly expose the WinRM port. See [Windows guest access](#Windows-guest-access)


Copy the files in `templates/` to tune your desired configuration and remove the `.example` part in their name.


# Windows guest preparation

This playbook assume you have setup a ready-to-use Windows Server 2012 R2 on the remote virtual machine.

These steps explains how to setup the VM on the server, but you are likely to prefer doing this on your local machine and send the resulting disk image by ssh. See [qemu.yml](roles/nwn2server/tasks/qemu.yml) for how to allocate the disk image and launch the vm.

> Note: you need to install the `pywinrm` python2 module on your dev machine

- Connect to the remote host
- Ensure `nwn2server@....service` is not running
- Download [virtio windows drivers](https://fedoraproject.org/wiki/Windows_Virtio_Drivers#Direct_download) (`virtio-win.iso`)
- Start VM: 
    + `/srv/nwn2server/bin/launch -boot d -drive file="PathToTheWindowsInstallDisk",media=cdrom -drive file=virtio-win.iso,media=cdrom`
- You can connect to the windows vm using the SPICE protocol on port 3389, through a SSH tunnel.
- Install Windows
    + When needed manually search for drivers in virtio-win.iso (`X:\`)
    + Administrator password: `#lcda0`
- Execute the following commands in powershell:
```ps
Invoke-WebRequest -Uri https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 -OutFile ConfigureRemotingForAnsible.ps1

.\ConfigureRemotingForAnsible.ps1 -EnableCredSSP

winrm set winrm/config/service '@{AllowUnencrypted="true"}'
```

- Optionnaly:
    + Update windows
    + Clean windows updates:
        * `Dism.exe /online /Cleanup-Image /StartComponentCleanup`
        * `Dism.exe /online /Cleanup-Image /SPSuperseded`
    + Defragment & fill empty files with 0 using `sdelete.exe -z C:`



# Windows guest access
<span id="#Windows-guest-access"></span>
- Start a SSH tunnel between your dev machine to the server hosting the VM
    + `ssh -NL 5985:127.0.0.1:5985 user@yourserver.com`
- Configure ansible to connect to the windows server:
    + `/etc/ansible/hosts`
        ```ini
        [windows]
        127.0.0.1
        ```
    + `/etc/ansible/group_vars/windows.yml`
        ```yml
        ansible_user: Administrator
        ansible_password: "#lcda0"
        ansible_port: 5985
        ansible_connection: winrm
        ansible_winrm_server_cert_validation: ignore
        ```


