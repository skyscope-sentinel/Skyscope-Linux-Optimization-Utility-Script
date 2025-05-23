echo rd.live.check quiet fips=1 lockdown=confidentiality modules_disabled=1 selinux=1 enforcing=1 noswap net.ifnames=0 ipv6.disable=1 noexec=on skew_tick=1 module_blacklist=usbhid,bluetooth,rds net.ipv4.icmp_echo_ignore_all=1 net.ipv4.icmp_echo_ignore_broadcasts=1 net.ipv4.conf.all.accept_redirects=0 net.ipv4.conf.all.send_redirects=0 net.ipv4.conf.all.accept_source_route=0 net.ipv6.conf.all.accept_source_route=0 net.ipv4.conf.all.rp_filter=1 net.ipv4.tcp_syncookies=1 randomize_kstack_offset=on slub_debug=FZ page_alloc.shuffle=1 vsyscall=none init_on_alloc=1 init_on_free=1 nosmt random.trust_cpu=0 kernel.randomize_va_space=2 net.ipv4.tcp_timestamps=0 net.ipv4.tcp_rfc1337=1 net.core.bpf_jit_harden=2 net.ipv4.conf.all.randomize_mac=1 pid_max=65536 vm.mmap_rnd_bits=32 vm.mmap_rnd_compat_bits=16 net.ipv4.conf.all.log_martians=1 net.ipv4.tcp_max_syn_backlog=4096 net.ipv4.tcp_fin_timeout=15 net.ipv4.conf.all.drop_gratuitous_arp=1 net.ipv4.conf.all.arp_ignore=2 net.ipv4.conf.all.arp_announce=2 net.ipv4.icmp_ratelimit=100 net.ipv4.tcp_sack=0

#!/bin/bash
#
echo " Skyscope Sentinel Intelligence - RedHat Enterprise Linux Auto Enhancement Script" 
echo " Starting Installation... "
# Comprehensive utility script to secure and optimize RHEL 10 with post-quantum cryptography,
# performance tweaks, and software installations for Intel i7-12700, 32GB DDR4, Gigabyte B760M-H-DDR4.

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mThis script must be run as root. Use sudo.\e[0m"
    exit 1
fi

# Display title and developer credit in specified format
echo -e "\e[1;32mSkyscope Sentinel Intelligence - Script Initial V1.1 2025 MIT\e[0m"
echo -e "\e[32mDeveloper Miss Casey Jay Topojani\e[0m"
echo -e "\e[32mStarting Skyscope Secure Configuration for RHEL 10...\e[0m"

# Update system and install essential tools
echo "Updating system and installing essential tools..."
dnf update -y
dnf install -y wget curl git nano gedit

# Enable required repositories
echo "Enabling CodeReady Builder Beta and Snapd repositories..."
subscription-manager repos --enable codeready-builder-beta-for-rhel-10-$(arch)-rpms \
    --enable rhel-10-server-optional-rpms \
    --enable rhel-10-server-extras-rpms
dnf update -y

# Install EPEL for RHEL 10
echo "Installing EPEL release for RHEL 10..."
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm

# Enable RPMFusion repositories
echo "Enabling RPMFusion repositories..."
dnf install -y https://mirrors.rpmfusion.org/free/el/releases/10/Everything/x86_64/os/Packages/r/rpmfusion-free-release-10-1.noarch.rpm
dnf install -y https://mirrors.rpmfusion.org/nonfree/el/releases/10/Everything/x86_64/os/Packages/r/rpmfusion-nonfree-release-10-1.noarch.rpm
dnf config-manager --enable rpmfusion-free rpmfusion-nonfree

# Install Flatpak and enable Flathub
echo "Installing Flatpak and enabling Flathub..."
dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Ollama using official script
echo "Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# Install Rust using official script
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Install Homebrew
echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Add Homebrew to PATH
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /root/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install AppImageLauncher from GitHub releases
echo "Installing AppImageLauncher from GitHub releases..."
APPIMAGELAUNCHER_VERSION="2.2.0" # Update to latest version if needed
wget https://github.com/TheAssassin/AppImageLauncher/releases/download/v${APPIMAGELAUNCHER_VERSION}/appimagelauncher-${APPIMAGELAUNCHER_VERSION}-trunk.el8.x86_64.rpm -O /tmp/appimagelauncher.rpm
dnf install -y /tmp/appimagelauncher.rpm
rm /tmp/appimagelauncher.rpm

# Install Snapd and Snap Store
echo "Installing Snapd and Snap Store..."
dnf install -y snapd
systemctl enable --now snapd.socket
ln -s /var/lib/snapd/snap /snap
snap install snap-store
echo "Snapd and Snap Store installed. Log out/in or reboot to update paths."

# Attempt to install dnfdragora
echo "Attempting to install dnfdragora..."
dnf install -y dnfdragora || {
    echo "dnfdragora not found in repositories. Attempting to install from source..."
    dnf install -y python3-dnf python3-qt5 rpm-build rpmdevtools
    git clone https://github.com/manatools/dnfdragora.git /tmp/dnfdragora
    cd /tmp/dnfdragora
    make rpm
    dnf install -y ./rpm-build/*.rpm
    cd -
    rm -rf /tmp/dnfdragora
}

# Install remaining software packages
echo "Installing requested software packages..."
dnf install -y \
    protobuf protobuf-compiler \
    clang \
    git git-lfs \
    python3 python3-pip \
    ffmpeg ffmpeg-libs \
    net-tools \
    waydroid \
    qemu-system-x86_64 \
    libvirt virt-install \
    npm yarn \
    pulseaudio-libs alsa-lib alsa-utils

# Install Nvidia CUDA and proprietary drivers (not Nouveau)
echo "Installing Nvidia CUDA and proprietary drivers..."
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
dnf install -y nvidia-driver cuda-driver cuda
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist-nouveau.conf
dracut -f

# Install Flatpak applications
echo "Installing Flatpak applications..."
flatpak install -y flathub com.yandex.Browser
flatpak install -y flathub org.getmonero.Monero
flatpak install -y flathub com.google.Chrome
flatpak install -y flathub com.stremio.Stremio
flatpak install -y flathub com.github.tchx84.Flatseal # Orion equivalent unavailable
flatpak install -y flathub com.yubico.yubioath

# Install pipx for isolated Python environments
echo "Installing pipx..."
python3 -m pip install --user pipx
python3 -m pipx ensurepath

# Install AIDE for file integrity monitoring
echo "Installing and configuring AIDE..."
dnf install -y aide
aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
systemctl enable aidecheck.timer
systemctl start aidecheck.timer
echo "AIDE initialized and scheduled for daily checks."

# Install and configure OpenSCAP with CIS benchmark
echo "Installing OpenSCAP and SCAP Security Guide..."
dnf install -y openscap-scanner scap-security-guide
oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis \
    --results-arf /tmp/openscap-results.xml \
    --report /tmp/openscap-report.html \
    /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml
oscap xccdf generate fix --profile xccdf_org.ssgproject.content_profile_cis \
    --output /tmp/cis-remediation.yml /tmp/openscap-results.xml
ansible-playbook /tmp/cis-remediation.yml
echo "OpenSCAP scan and remediation completed. Report saved to /tmp/openscap-report.html."

# Enable SELinux enforcing mode
echo "Enabling SELinux enforcing mode..."
setenforce 1
sed -i 's/^SELINUX=.*$/SELINUX=enforcing/' /etc/selinux/config

# Configure FIPS and post-quantum cryptography
echo "Configuring FIPS and post-quantum cryptography..."
fips-mode-setup --enable
dnf install -y crypto-policies-pq-preview crypto-policies-scripts
update-crypto-policies --set DEFAULT:TEST-PQ
echo "FIPS and PQC configured."

# Configure authentication with authselect
echo "Configuring authentication with authselect..."
authselect select sssd with-faillock with-pamaccess --force
authselect enable-feature with-pamaccess
echo "auth required pam_tally2.so deny=3 unlock_time=600" >> /etc/pam.d/system-auth
echo "Authentication hardened with faillock and pamaccess."

# Configure GRUB with secure parameters
echo "Configuring GRUB with secure parameters..."
GRUB_PARAMS="fips=1 lockdown=confidentiality modules_disabled=1 selinux=1 enforcing=1 noswap net.ifnames=0 ipv6.disable=1 noexec=on skew_tick=1 module_blacklist=usbhid,bluetooth,rds net.ipv4.icmp_echo_ignore_all=1 net.ipv4.icmp_echo_ignore_broadcasts=1 net.ipv4.conf.all.accept_redirects=0 net.ipv4.conf.all.send_redirects=0 net.ipv4.conf.all.accept_source_route=0 net.ipv6.conf.all.accept_source_route=0 net.ipv4.conf.all.rp_filter=1 net.ipv4.tcp_syncookies=1 randomize_kstack_offset=on slub_debug=FZ page_alloc.shuffle=1 vsyscall=none init_on_alloc=1 init_on_free=1 nosmt random.trust_cpu=0 kernel.randomize_va_space=2 net.ipv4.tcp_timestamps=0 net.ipv4.tcp_rfc1337=1 net.core.bpf_jit_harden=2 net.ipv4.conf.all.randomize_mac=1 pid_max=65536 vm.mmap_rnd_bits=32 vm.mmap_rnd_compat_bits=16 net.ipv4.conf.all.log_martians=1 net.ipv4.tcp_max_syn_backlog=4096 net.ipv4.tcp_fin_timeout=15 net.ipv4.conf.all.drop_gratuitous_arp=1 net.ipv4.conf.all.arp_ignore=2 net.ipv4.conf.all.arp_announce=2 net.ipv4.icmp_ratelimit=100 net.ipv4.tcp_sack=0"
sed -i "/^GRUB_CMDLINE_LINUX=/ s/\".*\"/\"$GRUB_PARAMS\"/" /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
echo "GRUB configuration updated."

# Configure sysctl for security and performance
echo "Configuring sysctl for security and performance..."
cat << EOF > /etc/sysctl.d/99-skyscope-secure.conf
# Security enhancements
kernel.randomize_va_space=2
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.sysrq=0
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
net.ipv4.icmp_echo_ignore_all=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0
net.ipv4.conf.all.rp_filter=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_rfc1337=1
net.ipv4.conf.all.log_martians=1
net.ipv4.tcp_max_syn_backlog=4096
net.ipv4.tcp_fin_timeout=15
net.ipv4.conf.all.drop_gratuitous_arp=1
net.ipv4.conf.all.arp_ignore=2
net.ipv4.conf.all.arp_announce=2
net.ipv4.icmp_ratelimit=100
net.ipv4.tcp_sack=0

# Performance optimizations for Intel i7-12700 and 32GB DDR4 3200 MHz
vm.swappiness=10
vm.vfs_cache_pressure=50
kernel.sched_autogroup_enabled=1
kernel.sched_migration_cost_ns=500000
kernel.sched_latency_ns=6000000
kernel.sched_min_granularity_ns=2000000
vm.dirty_ratio=20
vm.dirty_background_ratio=10
net.core.netdev_max_backlog=3000
net.core.somaxconn=65535
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=fq_codel
net.ipv4.tcp_low_latency=1
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_fastopen=3
net.core.rmem_max=16777216
net.core.wmem_max=16777216
fs.file-max=2097152
fs.nr_open=1048576
EOF
sysctl -p /etc/sysctl.d/99-skyscope-secure.conf
echo "sysctl configuration applied."

# Configure CPU governor for performance
echo "Configuring CPU governor for maximum performance..."
dnf install -y kernel-tools
cpupower frequency-set -g performance
echo "performance" > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo "CPU governor set to performance."

# Enable KVM for virtualization
echo "Enabling KVM for virtualization..."
modprobe kvm_intel
echo "kvm_intel" >> /etc/modules-load.d/kvm.conf
systemctl enable --now libvirtd
echo "KVM and libvirtd enabled."

# Configure firewalld
echo "Configuring firewalld for strict network security..."
systemctl enable --now firewalld
firewall-cmd --set-default-zone=drop
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="0.0.0.0/0" port port="22" protocol="tcp" limit value="5/m" accept'
firewall-cmd --reload
echo "firewalld configured with drop zone and SSH rate-limiting."

# Finalize and reboot
echo -e "\e[1;32mSkyscope Sentinel Intelligence 2025 MIT Configuration Complete!\e[0m"
echo -e "\e[32mAll security, performance, and software configurations applied.\e[0m"
echo -e "\e[32mRebooting in 10 seconds... Press Ctrl+C to cancel.\e[0m"
sleep 10
echo " Skyscope Sentinel Intelligence - RedHat Enterprise Linux Auto Enhancement configurations setup is now complete. Please reboot your system at your earliest convenience for changes to immediately take effect..."
