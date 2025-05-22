#!/bin/bash

# Skyscope Sentinel Intelligence - System Optimization Utility Script
# Author: Skyscope Sentinel Intelligence
# Developer: Miss Casey Jay Topojani
# Date: May 23, 2025

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[+] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Function to apply sysctl parameter with error handling
apply_sysctl() {
    local param="$1"
    local value="$2"
    print_status "Applying $param=$value"
    if ! sysctl -w "$param=$value" 2>/dev/null; then
        print_error "Failed to apply $param=$value"
    fi
}

# Function to create or update a config file
update_config_file() {
    local file="$1"
    local content="$2"
    local dir=$(dirname "$file")
    if [ ! -d "$dir" ]; then
        print_status "Creating directory $dir"
        mkdir -p "$dir"
        chmod 755 "$dir"
        chown root:root "$dir"
    fi
    print_status "Updating $file"
    echo -e "$content" > "$file"
    chmod 644 "$file"
    chown root:root "$file"
}

# Ensure root privileges
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root. Use sudo."
    exit 1
fi

# Update and install necessary packages
print_status "Updating system and installing required packages"
apt update && apt upgrade -y
apt install -y procps sysstat htop iotop dstat numactl cpufrequtils irqbalance fio iperf3 ethtool stress-ng zram-tools tuned bpftrace linux-tools-common systemd-coredump mstflint blktrace

# Optimize kernel parameters via sysctl
print_status "Configuring sysctl parameters for maximum performance"
SYSCTL_CONF="/etc/sysctl.d/99-performance.conf"
SYSCTL_CONTENT=$(cat << 'EOF'
# Network Throughput Optimizations
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.ipv4.udp_rmem_min=16384
net.ipv4.udp_wmem_min=16384
net.core.optmem_max=25165824
net.ipv4.tcp_congestion_control=cubic
net.ipv4.tcp_available_congestion_control=cubic reno
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_no_metrics_save=0
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_low_latency=0
net.ipv4.tcp_ecn=1
net.ipv4.tcp_ecn_fallback=1
net.ipv4.tcp_frto=2
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_max_tw_buckets=1440000
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_syncookies=1
net.core.netdev_max_backlog=65536
net.core.somaxconn=65535
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_max_orphans=262144
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_dsack=1
net.ipv4.tcp_reordering=3
net.ipv4.tcp_mem=262144 524288 1048576
net.ipv4.udp_mem=262144 524288 1048576
net.core.netdev_budget=600
net.core.netdev_budget_usecs=8000
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_base_mss=1024
net.ipv4.tcp_min_snd_mss=512
net.ipv4.tcp_probe_interval=10
net.ipv4.tcp_probe_threshold=8
net.ipv4.tcp_fastopen=3
net.ipv4.ip_no_pmtu_disc=0
net.ipv4.ip_forward=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.log_martians=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.tcp_early_retrans=2
net.ipv4.tcp_retrans_collapse=1
net.ipv4.tcp_max_reordering=300
net.ipv4.tcp_app_win=31
net.ipv4.tcp_limit_output_bytes=131072
net.ipv4.tcp_challenge_ack_limit=1000
net.ipv4.tcp_invalid_ratelimit=500
net.ipv4.tcp_pacing_ss_ratio=200
net.ipv4.tcp_pacing_ca_ratio=120
net.ipv4.tcp_autocorking=1
net.ipv6.conf.all.disable_ipv6=0
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.all.autoconf=0
net.ipv6.conf.all.forwarding=0
net.ipv6.conf.all.mtu=1500
net.ipv6.conf.all.dad_transmits=1
net.ipv6.conf.all.hop_limit=64
net.ipv6.conf.all.router_solicitations=0
net.ipv6.conf.all.use_tempaddr=2
net.core.dev_weight=64
net.core.message_cost=0
net.core.message_burst=10
net.core.netdev_tstamp_prequeue=1
net.core.netdev_rss_key_fill=1
net.core.netdev_rss_hash_bits=16
net.core.netdev_rss_hash_func=toeplitz
net.core.netdev_rss_indir_table_size=128
net.core.netdev_rss_spread=4
net.ipv4.tcp_thin_linear_timeouts=1
net.ipv4.tcp_thin_dupack=1
net.ipv4.tcp_orphan_retries=0
net.ipv4.tcp_workaround_signed_windows=1
net.ipv4.tcp_moderate_rcvbuf=1
net.ipv4.tcp_rmem_max=134217728
net.ipv4.tcp_wmem_max=134217728
net.ipv4.tcp_tso_win_divisor=3
net.ipv4.tcp_mtu_probe_floor=1024
net.ipv4.tcp_early_demux=1
net.ipv4.tcp_max_txqueuelen=65536
net.ipv4.tcp_notsent_lowat=16384
net.ipv4.tcp_use_userconfig=0
net.ipv4.tcp_delack_seg=10
net.ipv4.tcp_delack_min=5
net.ipv4.tcp_delack_max=100
net.ipv4.tcp_bic=1
net.ipv4.tcp_bic_low_window=14
net.ipv4.tcp_bic_fast_convergence=1
net.ipv4.tcp_vegas_cong_avoid=1
net.ipv4.tcp_vegas_alpha=2
net.ipv4.tcp_vegas_beta=6
net.ipv4.tcp_vegas_gamma=2
net.ipv4.tcp_westwood=1
net.ipv4.tcp_hybla=1
net.ipv4.tcp_illinois=1
net.ipv4.tcp_scalable=1
net.ipv4.tcp_max_syn_backlog=32768
net.ipv4.tcp_syn_retries=4
net.ipv4.tcp_abort_on_overflow=1
net.ipv4.tcp_max_tw_buckets=4000000
net.ipv4.tcp_max_orphans=1048576
net.ipv4.tcp_orphan_retries=1
net.ipv4.tcp_reordering=10
net.ipv4.tcp_early_retrans=4
net.ipv4.tcp_min_tso_segs=4
net.ipv4.tcp_max_txqueuelen=131072

# CPU and Memory Performance
kernel.sched_autogroup_enabled=1
kernel.sched_cfs_bandwidth_slice_us=5000
kernel.sched_child_runs_first=1
kernel.sched_deadline_period_max_us=1000000
kernel.sched_deadline_period_min_us=1000
kernel.sched_latency_ns=20000000
kernel.sched_migration_cost_ns=5000000
kernel.sched_min_granularity_ns=2000000
kernel.sched_nr_migrate=128
kernel.sched_rr_timeslice_ms=25
kernel.sched_energy_aware=1
kernel.sched_tunable_scaling=1
kernel.sched_wakeup_granularity_ns=2500000
kernel.sched_util_clamp_max=1024
kernel.sched_util_clamp_min=0
kernel.cpu_idle=1
kernel.hung_task_timeout_secs=120
kernel.panic=10
kernel.panic_on_oops=1
kernel.perf_cpu_time_max_percent=25
vm.dirty_background_ratio=5
vm.dirty_ratio=10
vm.dirty_expire_centisecs=3000
vm.dirty_writeback_centisecs=500
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.overcommit_memory=0
vm.overcommit_ratio=50
vm.max_map_count=1048576
vm.min_free_kbytes=524288
vm.nr_hugepages=2048
vm.nr_overcommit_hugepages=1024
vm.hugetlb_shm_group=0
vm.hugepages_treat_as_movable=1
vm.nr_hugepages_mempolicy=0
vm.drop_caches=0
vm.zone_reclaim_mode=0
vm.oom_kill_allocating_task=1
vm.oom_dump_tasks=1
vm.panic_on_oom=0
vm.compact_unevictable_allowed=1
vm.compaction_proactiveness=20
vm.page_lock_unfairness=5
vm.percpu_pagelist_fraction=0
vm.memory_failure_early_kill=1
vm.memory_failure_recovery=1
vm.lowmem_reserve_ratio=32 32 32 32
vm.stat_interval=1
vm.mmap_min_addr=65536
vm.mmap_rnd_bits=32
vm.legacy_va_layout=0
vm.unprivileged_userfaultfd=1
vm.swap_token_timeout_secs=300
vm.page_cluster=3
vm.reap_mem_on_sigkill=1
vm.transparent_hugepage=always
vm.thp_enabled=1
vm.thp_defrag=1
vm.thp_shmem_enabled=1
vm.thp_khugepaged_deflater=1

# SSD/NVMe Performance
fs.file-max=2097152
fs.nr_open=2097152
fs.inotify.max_user_instances=1024
fs.inotify.max_user_watches=524288
fs.aio-max-nr=1048576
fs.pipe-max-size=4194304
fs.mqueue.msg_max=1024
fs.mqueue.msgsize_max=16384
fs.mqueue.queues_max=1024
fs.lease-break-time=10
vm.block_dump=0
vm.laptop_mode=0
vm.dirty_background_bytes=0
vm.dirty_bytes=0
vm.highmem_is_dirtyable=1
vm.pagecache_limit_mb=0
vm.pagecache_limit_ignore_dirty=1
vm.scan_unevictable_pages=0
vm.writeback_throttling=1

# Operating System and Inter-Device Communication
kernel.core_uses_pid=1
kernel.core_pattern=/var/log/core.%e.%p
kernel.sysrq=1
kernel.msgmni=32768
kernel.msgmax=65536
kernel.msgmnb=131072
kernel.sem=250 32000 100 1024
kernel.shmmax=68719476736
kernel.shmall=16777216
kernel.shmmni=4096
kernel.numa_balancing=1
kernel.numa_balancing_rate_limit_mbps=1024
kernel.numa_balancing_scan_delay_ms=1000
kernel.numa_balancing_scan_period_max_ms=60000
kernel.numa_balancing_scan_period_min_ms=1000
kernel.numa_balancing_scan_size_mb=256
kernel.numa_balancing_settle_count=4
kernel.numa_balancing_hot_threshold_ms=1000
kernel.numa_balancing_migrate_deferred=1
kernel.numa_balancing_promote_rate_limit=1024
kernel.irq_affinity=0
kernel.timer_migration=1
kernel.hrtimer_granularity_ns=1000
kernel.watchdog=1
kernel.watchdog_thresh=10
kernel.softlockup_panic=1
kernel.hardlockup_panic=1
kernel.unknown_nmi_panic=1
kernel.nmi_watchdog=1
kernel.perf_event_paranoid=0
kernel.randomize_va_space=2
kernel.kptr_restrict=1
kernel.dmesg_restrict=1
kernel.printk=4 4 1 7
kernel.printk_delay=0
kernel.printk_ratelimit=5
kernel.printk_ratelimit_burst=10
kernel.pid_max=4194304
kernel.threads-max=2097152
kernel.stack_canary=1

# Additional Network Tweaks
net.ipv4.tcp_bic_fast_convergence=1
net.ipv4.tcp_bic_low_window=14
net.ipv4.tcp_vegas_cong_avoid=1
net.ipv4.tcp_vegas_alpha=2
net.ipv4.tcp_vegas_beta=6
net.ipv4.tcp_vegas_gamma=2
net.ipv4.tcp_westwood=1
net.ipv4.tcp_hybla=1
net.ipv4.tcp_illinois=1
net.ipv4.tcp_scalable=1
net.ipv4.tcp_max_syn_backlog=32768
net.ipv4.tcp_syn_retries=4
net.ipv4.tcp_abort_on_overflow=1
net.ipv4.tcp_max_tw_buckets=4000000
net.ipv4.tcp_max_orphans=1048576
net.ipv4.tcp_orphan_retries=1
net.ipv4.tcp_reordering=10
net.ipv4.tcp_early_retrans=4
net.ipv4.tcp_min_tso_segs=4
net.ipv4.tcp_max_txqueuelen=131072

# Additional CPU Tweaks
kernel.sched_tunable_scaling=0
kernel.sched_min_granularity_ns=500000
kernel.sched_wakeup_granularity_ns=1000000
kernel.sched_cfs_bandwidth_slice_us=2000
kernel.sched_deadline_period_max_us=4000000
kernel.sched_deadline_period_min_us=250
kernel.sched_energy_aware=1
kernel.sched_util_clamp_max=4096
kernel.sched_util_clamp_min=256
kernel.perf_cpu_time_max_percent=75

# Additional Memory Tweaks
vm.dirty_background_ratio=1
vm.dirty_ratio=2
vm.dirty_expire_centisecs=1000
vm.dirty_writeback_centisecs=100
vm.swappiness=1
vm.vfs_cache_pressure=10
vm.overcommit_memory=1
vm.overcommit_ratio=90
vm.max_map_count=4194304
vm.min_free_kbytes=2097152

# Additional Disk Tweaks
fs.file-max=8388608
fs.nr_open=8388608
fs.inotify.max_user_instances=4096
fs.inotify.max_user_watches=2097152
fs.aio-max-nr=4194304
fs.pipe-max-size=16777216
fs.mqueue.msg_max=4096
fs.mqueue.msgsize_max=65536
fs.mqueue.queues_max=4096
fs.lease-break-time=1

# Additional Kernel Tweaks
kernel.core_uses_pid=0
kernel.core_pattern=/var/log/core.%e
kernel.sysrq=0
kernel.msgmni=131072
kernel.msgmax=262144
kernel.msgmnb=524288
kernel.sem=1000 128000 400 4096
kernel.shmmax=274877906944
kernel.shmall=67108864
kernel.shmmni=16384

# Additional NUMA Tweaks
kernel.numa_balancing=1
kernel.numa_balancing_rate_limit_mbps=4096
kernel.numa_balancing_scan_delay_ms=250
kernel.numa_balancing_scan_period_max_ms=240000
kernel.numa_balancing_scan_period_min_ms=250
kernel.numa_balancing_scan_size_mb=1024
kernel.numa_balancing_settle_count=16
kernel.numa_balancing_hot_threshold_ms=250
kernel.numa_balancing_migrate_deferred=1
kernel.numa_balancing_promote_rate_limit=4096

# Additional IRQ Tweaks
kernel.irq_affinity=0
kernel.timer_migration=1
kernel.hrtimer_granularity_ns=250
kernel.watchdog=1
kernel.watchdog_thresh=10
kernel.softlockup_panic=1
kernel.hardlockup_panic=1
kernel.unknown_nmi_panic=1
kernel.nmi_watchdog=1
kernel.perf_event_paranoid=0
EOF
)
update_config_file "$SYSCTL_CONF" "$SYSCTL_CONTENT"
sysctl -p "$SYSCTL_CONF"

# Optimize CPU performance
print_status "Optimizing CPU performance for i7-12700"
cpufreq-set -r -g performance
echo 1 > /sys/devices/system/cpu/intel_pstate/turbo
echo 4900 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo 0 > /sys/module/intel_idle/parameters/max_cstate
echo "performance" > /sys/module/pcie_aspm/parameters/policy

# Enable hyperthreading and parallel computing
print_status "Maximizing hyperthreading and parallel computing"
for cpu in /sys/devices/system/cpu/cpu[0-19]; do
    echo "performance" > "$cpu/cpufreq/scaling_governor"
    echo 1 > "$cpu/online"
done

# Optimize memory
print_status "Optimizing memory performance"
echo "always" > /sys/kernel/mm/transparent_hugepage/enabled
echo "always" > /sys/kernel/mm/transparent_hugepage/defrag
echo 1 > /sys/kernel/mm/ksm/run
echo 1000 > /sys/kernel/mm/ksm/pages_to_scan
echo "* soft core unlimited" >> /etc/security/limits.conf
echo "* hard core unlimited" >> /etc/security/limits.conf

# Optimize SSD/NVMe performance
print_status "Optimizing SSD/NVMe performance"
for dev in /sys/block/nvme*; do
    echo "mq-deadline" > "$dev/queue/scheduler"
    echo 8192 > "$dev/queue/nr_requests"
    echo 16384 > "$dev/queue/read_ahead_kb"
    echo "write back" > "$dev/queue/write_cache"
done
update_config_file "/etc/fstab" "$(cat /etc/fstab | sed 's/defaults/defaults,noatime,nodiratime,commit=60/g')"
systemctl enable fstrim.timer
systemctl start fstrim.timer

# Network performance tweaks
print_status "Optimizing network performance"
ethtool -K eth0 rx on tso on gso on gro on 2>/dev/null || true
ethtool -G eth0 rx 4096 tx 4096 2>/dev/null || true
ethtool -L eth0 combined 12 2>/dev/null || true
ethtool -C eth0 rx-usecs 50 tx-usecs 50 2>/dev/null || true
ip link set eth0 mtu 9000 2>/dev/null || true

# Ubuntu Questing Quokka specific tweaks
print_status "Applying Ubuntu 25.10 Questing Quokka specific tweaks"
GRUB_CONF="/etc/default/grub"
GRUB_CONTENT=$(cat << 'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=2
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_pstate=performance nosmt=off tsc=reliable"
GRUB_CMDLINE_LINUX=""
EOF
)
update_config_file "$GRUB_CONF" "$GRUB_CONTENT"
update-grub

# Optimize swap and zram
print_status "Optimizing swap and enabling zram"
swapoff -a
fallocate -l 8G /swapfile
mkswap /swapfile
swapon /swapfile
echo "zram" > /etc/modules-load.d/zram.conf
modprobe zram
echo "lzo" > /sys/block/zram0/comp_algorithm
echo $((8*1024*1024*1024)) > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon /dev/zram0

# Systemd services with skyscope- prefix
print_status "Creating and enabling systemd services"
SKYSCOPE_SERVICES_DIR="/etc/systemd/system"
mkdir -p "$SKYSCOPE_SERVICES_DIR"

# Service: skyscope-cpu-optimization
CPU_SERVICE="$SKYSCOPE_SERVICES_DIR/skyscope-cpu-optimization.service"
CPU_SERVICE_CONTENT=$(cat << 'EOF'
[Unit]
Description=SkyScope CPU Optimization Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cpufreq-set -r -g performance
ExecStart=/bin/sh -c "echo 1 > /sys/devices/system/cpu/intel_pstate/turbo"
ExecStart=/bin/sh -c "echo 4900 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"
ExecStart=/bin/sh -c "echo 0 > /sys/module/intel_idle/parameters/max_cstate"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
)
update_config_file "$CPU_SERVICE" "$CPU_SERVICE_CONTENT"
systemctl daemon-reload
systemctl enable skyscope-cpu-optimization.service
systemctl start skyscope-cpu-optimization.service

# Service: skyscope-memory-optimization
MEMORY_SERVICE="$SKYSCOPE_SERVICES_DIR/skyscope-memory-optimization.service"
MEMORY_SERVICE_CONTENT=$(cat << 'EOF'
[Unit]
Description=SkyScope Memory Optimization Service
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo always > /sys/kernel/mm/transparent_hugepage/enabled"
ExecStart=/bin/sh -c "echo always > /sys/kernel/mm/transparent_hugepage/defrag"
ExecStart=/bin/sh -c "echo 1 > /sys/kernel/mm/ksm/run"
ExecStart=/bin/sh -c "echo 1000 > /sys/kernel/mm/ksm/pages_to_scan"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
)
update_config_file "$MEMORY_SERVICE" "$MEMORY_SERVICE_CONTENT"
systemctl daemon-reload
systemctl enable skyscope-memory-optimization.service
systemctl start skyscope-memory-optimization.service

# Service: skyscope-disk-optimization
DISK_SERVICE="$SKYSCOPE_SERVICES_DIR/skyscope-disk-optimization.service"
DISK_SERVICE_CONTENT=$(cat << 'EOF'
[Unit]
Description=SkyScope Disk Optimization Service
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "for dev in /sys/block/nvme*; do echo mq-deadline > \$dev/queue/scheduler; echo 8192 > \$dev/queue/nr_requests; echo 16384 > \$dev/queue/read_ahead_kb; echo write back > \$dev/queue/write_cache; done"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
)
update_config_file "$DISK_SERVICE" "$DISK_SERVICE_CONTENT"
systemctl daemon-reload
systemctl enable skyscope-disk-optimization.service
systemctl start skyscope-disk-optimization.service

# Service: skyscope-network-optimization
NETWORK_SERVICE="$SKYSCOPE_SERVICES_DIR/skyscope-network-optimization.service"
NETWORK_SERVICE_CONTENT=$(cat << 'EOF'
[Unit]
Description=SkyScope Network Optimization Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool -K eth0 rx on tso on gso on gro on
ExecStart=/usr/sbin/ethtool -G eth0 rx 4096 tx 4096
ExecStart=/usr/sbin/ethtool -L eth0 combined 12
ExecStart=/usr/sbin/ethtool -C eth0 rx-usecs 50 tx-usecs 50
ExecStart=/sbin/ip link set eth0 mtu 9000
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
)
update_config_file "$NETWORK_SERVICE" "$NETWORK_SERVICE_CONTENT"
systemctl daemon-reload
systemctl enable skyscope-network-optimization.service
systemctl start skyscope-network-optimization.service

# Service: skyscope-monitoring
MONITORING_SERVICE="$SKYSCOPE_SERVICES_DIR/skyscope-monitoring.service"
MONITORING_SERVICE_CONTENT=$(cat << 'EOF'
[Unit]
Description=SkyScope System Monitoring Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/dstat -cdngy
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
)
update_config_file "$MONITORING_SERVICE" "$MONITORING_SERVICE_CONTENT"
systemctl daemon-reload
systemctl enable skyscope-monitoring.service
systemctl start skyscope-monitoring.service

# Final reboot to apply all changes
print_status "Reboot system to apply all optimizations at your earliest convenience - System Optimization Utility Script brought to you by Skyscope Sentinel Intelligence ABN 11 287 984 779"
