#!/bin/bash
#
echo " Skyscope Sentinel Intelligence - RedHat Enterprise Linux 10 Additional Enhancements Installation Script "
echo " Commencing Setup "
#
# Skyscope-RedHat-Podman-AI-Setup.sh
# Utility script to configure Podman for macOS container, install Pinokio, Anaconda3, and Nvidia CUDA/drivers on RHEL 10.

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mThis script must be run as root. Use sudo.\e[0m"
    exit 1
fi

# Display title and developer credit in specified format
echo -e "\e[1;32mSkyscope Sentinel Intelligence 2025 MIT\e[0m"
echo -e "\e[32mDeveloper Miss Casey Jay Topojani\e[0m"
echo -e "\e[32mStarting Skyscope Podman and AI Setup for RHEL 10...\e[0m"

# Update system and install essential tools
echo "Updating system and installing essential tools..."
dnf update -y
dnf install -y wget curl git podman

# Install dependencies for Podman and macOS container
echo "Installing dependencies for Podman and macOS container..."
dnf install -y qemu-system-x86_64 libvirt virt-install xorg-x11-server-Xorg x11vnc
# Ensure KVM is enabled
modprobe kvm_intel
echo "kvm_intel" >> /etc/modules-load.d/kvm.conf
systemctl enable --now libvirtd

# Configure Podman for rootless operation
echo "Configuring Podman for rootless operation..."
echo "kernel.unprivileged_userns_clone=1" >> /etc/sysctl.d/99-podman.conf
sysctl -p /etc/sysctl.d/99-podman.conf
# Enable linger for non-root user (assumes user 'user', replace with actual username if needed)
loginctl enable-linger user || echo "Run 'loginctl enable-linger <username>' for your user to enable rootless Podman persistence."

# Pull and run macOS container with Podman
echo "Running macOS container with Podman..."
# Adapted Docker command for Podman
podman run -it \
    --device /dev/kvm \
    -p 50922:10022 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -e GENERATE_UNIQUE=true \
    -e CPU='Haswell-noTSX' \
    -e CPUID_FLAGS='kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on' \
    -e MASTER_PLIST_URL='https://raw.githubusercontent.com/sickcodes/osx-serial-generator/master/config-custom-sonoma.plist' \
    -e SHORTNAME=sequoia \
    --name macos-sequoia \
    sickcodes/docker-osx:latest

# Note: Podman does not require 'docker build' as the image is pulled directly. If building is needed, provide a Dockerfile.
echo "macOS container started. Access via SSH on port 50922 or VNC."

# Install Pinokio
echo "Installing Pinokio..."
wget https://github.com/pinokiocomputer/pinokio/releases/download/3.8.0/Pinokio-3.8.0.x86_64.rpm -O /tmp/Pinokio-3.8.0.x86_64.rpm
dnf install -y /tmp/Pinokio-3.8.0.x86_64.rpm
rm /tmp/Pinokio-3.8.0.x86_64.rpm
echo "Pinokio installed."

# Install Anaconda3
echo "Installing Anaconda3..."
wget https://repo.anaconda.com/archive/Anaconda3-2024.10-1-Linux-x86_64.sh -O /tmp/Anaconda3-2024.10-1-Linux-x86_64.sh
bash /tmp/Anaconda3-2024.10-1-Linux-x86_64.sh -b -p /opt/anaconda3
echo 'export PATH="/opt/anaconda3/bin:$PATH"' >> /root/.bashrc
source /root/.bashrc
rm /tmp/Anaconda3-2024.10-1-Linux-x86_64.sh
echo "Anaconda3 installed in /opt/anaconda3."

# Install Nvidia CUDA and drivers
echo "Installing Nvidia CUDA and proprietary drivers..."
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
dnf clean all
dnf install -y cuda-toolkit-12-9 nvidia-driver:latest-dkms
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist-nouveau.conf
dracut -f
echo "Nvidia CUDA and drivers installed."

# Finalize
echo -e "\e[1;32mSkyscope Sentinel Intelligence 2025 MIT Configuration Complete!\e[0m"
echo -e "\e[32mPodman, macOS container, Pinokio, Anaconda3, and Nvidia CUDA/drivers configured.\e[0m"
echo -e "\e[32mReboot recommended to ensure Nvidia drivers and Podman settings are applied. Rebooting in 10 seconds... Press Ctrl+C to cancel.\e[0m"
sleep 10
#
echo ' Skyscope Sentinel Intelligence RedHat Enterprise Linux 10 Additional enhancements and application installation script completed successfully. Please reboot at your earliest convenience for full functionality of applications libraries and containers. "
