# RT Container Test Framework
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)  
This project provides a test framework for executing repeated container-based tests (Docker or Podman) on a Real-Time (RT) Linux kernel environment.
The primary purpose is to validate runtime behavior and execution stability of containers under a PREEMPT_RT patched kernel.

## 1. Requirements
### 1.1 RT Kernel (Mandatory)
The system must be running a Linux kernel patched with PREEMPT_RT.

#### Verify RT Kernel
```
uname -a
```
#### Expected output should include:
```
PREEMPT_RT
```
If the RT flag is not present, real-time behavior validation will not be meaningful.  
For raspberry pi rt kernel, go to the github repository([ros-realtime](https://github.com/ros-realtime/ros-realtime-rpi4-image)).

#### CPU Isolation(cpu3) - Kernel parameter update
- Ubuntu
```
sudo vi /etc/default/grub
```
```
# ... change line below
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash threadirqs isolcpus=3 nohz_full=3 rcu_nocbs=3 irqaffinity=0-2 threadirqs"
# ...
```
- Raspberrypi  
1. Update Kernel parameter
```
sudo vi /boot/firmware/cmdline.txt
```
```
# ... change line as below
console=serial0,115200 dwc_otg.lpm_enable=0 console=tty1 root=LABEL=writable rootfstype=ext4 rootwait fixrtc quiet splash isolcpus=3 nohz_full=3 rcu_nocbs=3 irqaffinity=0-2 threadirqs
```
2. Set rt priority for user
```
sudo vi /etc/security/limits.d/20-ubuntu-rt.conf
```
```
# change context as below
*          -       rtprio          99
*          -       memlock         unlimited
```

### 1.2 Container Engine
At least one of the following must be installed:
- Docker
- Podman

Verify Installation
```
docker --version
```
or
```
podman --version
```

## 2. Project Structure
```
host (test realtime setup on host OS)
container
├── dockerfiles
│   └── rt_test
│       └── Dockerfile.rt_test
├── scripts
│   ├── env
│   │   └── env_build.sh
│   ├── run.sh
│   └── setup
│       ├── docker.sh  # install docker
│       └── podman.sh  # install podman
│   └── test
│       ├── entry
│       │   └── rt_test.sh
│       └── test.sh
└── test.sh
```

### File Descriptions

#### Top-Level
- `test.sh` :  Top-level entry point for multi-engine and repeated test execution.
---
#### Execution Layer
- `scripts/run.sh` :  Executes a single engine test (image build + container run).
- `scripts/test/test.sh` : Coordinates container execution and manages test workflow.
---
#### Container Entry
- `scripts/test/entry/rt_test.sh` : Actual test logic executed inside the container.
---
#### Build Layer
- `scripts/env/env_build.sh` : Builds the container image.
- `dockerfiles/rt_test/Dockerfile.rt_test` : Defines the container image used for RT testing.

## 3. Execution Flow

The test execution sequence is:  
1. Build container image (env_build.sh)
2. Launch container
3. Execute internal test script (rt_test.sh)
4. Repeat for the specified iteration count
5. Store results

## 4. How to Run
### 4.1 Multi-Engine Repeated Test
Use the top-level test.sh script.

Usage
```
./test.sh <test-count> <engine1> <engine2> ...
```
Example
```
./test.sh 3 docker podman
```
Meaning:  
- `3` → Run 3 iterations per engine
- `docker podman` → Execute tests for both engines

Internally, this calls:
```
./scripts/run.sh <engine> rt_test ./dockerfiles/rt_test <result-dir> 1000000 rt_test.sh
```
### 4.2 Direct Execution (Single Engine)
You may also execute run.sh directly.

Usage
```
./scripts/run.sh <engine> <image-name> <dockerfile-path> <result-path> <loop> <test_script>
```
Example
```
./scripts/run.sh docker rt_test ./dockerfiles/rt_test ~/rt/test/container/results/docker 1000000 rt_test.sh
```
Parameter Description
`engine` : docker or podman
`image-name` : Name of the image to build
`dockerfile-path` : Path to Dockerfile directory
`result-path` : Directory to store test results
`loop` : Number of internal test iterations
`test_script` : Script executed inside the container

## 5. Output
Test results are stored per engine in the following directories:
```
~/rt/test/container/results/docker/
~/rt/test/container/results/podman/
```
Ensure the directories exist and have write permissions before execution.

## 6. Important Notes
- Running without an RT kernel invalidates real-time performance evaluation.
- CPU core binding options (e.g., -cl 0 1 2 3) should be adjusted according to your system configuration.
- The internal loop count (1000000) may need tuning depending on system performance.
- Ensure sufficient system resources when running high iteration counts.

## 7. Example Scenario
To run 5 iterations for both Docker and Podman:
```
./test.sh 5 docker podman
```
Each iteration performs:
- Image build
- Container execution
- Internal RT test
- Result storage
- Next iteration
