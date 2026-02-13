# RT Container Test Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The **RT Container Test Framework** is designed to validate **runtime stability and deterministic execution behavior** of containers running on a **Linux PREEMPT_RT patched kernel**.

This framework enables:

- Validation of container runtime behavior in RT environments  
- Repeated execution stability testing  
- Comparative testing between Docker and Podman  

---

# 1. System Requirements

## 1.1 PREEMPT_RT Kernel (Mandatory)

A Linux kernel patched with **PREEMPT_RT** is required for meaningful real-time performance validation.

### Verify RT Kernel

```bash
uname -a
```

Expected output should include:

```bash
PREEMPT_RT
```

If the RT flag is not present, the real-time test results will not be valid.

### Raspberry Pi RT Kernel

If you need an RT kernel image for Raspberry Pi, refer to:

https://github.com/ros-realtime/ros-realtime-rpi4-image

---

## 1.2 CPU Isolation (Recommended)

CPU isolation improves test reliability by reducing interference from system processes.

### Ubuntu

Edit GRUB configuration:

```bash
sudo vi /etc/default/grub
```

Modify the following line:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash threadirqs isolcpus=3 nohz_full=3 rcu_nocbs=3 irqaffinity=0-2"
```

Apply changes:

```bash
sudo update-grub
sudo reboot
```

---

### Raspberry Pi

#### 1️⃣ Update Kernel Parameters

```bash
sudo vi /boot/firmware/cmdline.txt
```

```bash
console=serial0,115200 dwc_otg.lpm_enable=0 console=tty1 root=LABEL=writable rootfstype=ext4 rootwait fixrtc quiet splash isolcpus=3 nohz_full=3 rcu_nocbs=3 irqaffinity=0-2 threadirqs
```

#### 2️⃣ Configure RT Priority

```bash
sudo vi /etc/security/limits.d/20-ubuntu-rt.conf
```

```bash
*  -  rtprio  99
*  -  memlock unlimited
```

---

## 1.3 Container Engine

At least one container engine must be installed:

- Docker
- Podman

Verify installation:

```bash
docker --version
```

or

```bash
podman --version
```

---

# 2. Project Structure

```
host
container
├── dockerfiles
│   └── rt_test
│       └── Dockerfile.rt_test
├── scripts
│   ├── env
│   │   └── env_build.sh
│   ├── run.sh
│   ├── setup
│   │   ├── docker.sh
│   │   └── podman.sh
│   └── test
│       ├── entry
│       │   └── rt_test.sh
│       └── test.sh
└── test.sh
```

---

# 3. Usage

## 3.1 Multi-Engine Repeated Test (Recommended)

```bash
./test.sh <test-count> <engine1> <engine2> ...
```

### Example

```bash
./test.sh 3 docker podman
```

Meaning:

- Run 3 iterations per engine  
- Execute tests for Docker and Podman  

---

## Internal Command Execution

```bash
./scripts/run.sh <engine> rt_test ./dockerfiles/rt_test <result-dir> <cyclic-test-loop-count> rt_test.sh [cpu-list]
```

---

### Parameters

| Parameter | Description |
|------------|------------|
| engine | docker or podman |
| image-name | Container image name |
| dockerfile-path | Path to Dockerfile directory |
| result-path | Directory for storing results |
| loop | Number of internal RT test iterations |
| test_script | Script executed inside the container |

---

# 4. Output

Test results are stored per engine:

```
~/rt/test/container/results/docker/
~/rt/test/container/results/podman/
```
