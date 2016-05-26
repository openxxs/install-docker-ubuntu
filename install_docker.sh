#!/bin/bash

# install docker in Ubuntu server 12.04, 14.04, 15.10 and 16.04
# xiaoshengxu@sohu-inc.com
# 2016-05-25

command_exists() {
  command -v "$@" > /dev/null 2>&1
}
docker_list_file="/etc/apt/sources.list.d/docker.list"
docker_repo_url="https://apt.dockerproject.org/repo"

# STEP 01: check system kernel version
echo -e "\033[36m[INFO] STEP 01: Check system kernel...\033[0m"
kernel_version=`uname -r`
if [ -z "$kernel_version" ]; then
  echo -e "\033[31m[ERROR] get kernel version error, kernel must be 3.10.0 at minimum\033[0m"
  exit 1
fi
kernel_parts_tmp=(${kernel_version//-/ })
kernel_parts=(${kernel_parts_tmp[0]//./ })
ubuntu_release=`lsb_release -a | grep "Release" | awk '{print $2}'`
ubuntu_codename=`lsb_release -a | grep "Codename" | awk '{print $2}'`
if [ "$ubuntu_release" == "12.04" ]; then
  if [ ${kernel_parts[0]} -lt 3 ]; then
    echo -e "\033[31m[ERROR] For Ubuntu Precise, Docker requires 3.13 kernel version at minimum, current version is ${kernel_parts_tmp[0]}\033[0m"
    exit 1
  fi
  if [ ${kernel_parts[0]} -eq 3 ] && [ ${kernel_parts[1]} -lt 13 ]; then
    echo -e "\033[31m[ERROR] For Ubuntu Precise, Docker requires 3.13 kernel version at minimum, current version is ${kernel_parts_tmp[0]}\033[0m"
    exit 1
  fi
elif [ "$ubuntu_release" == "14.04" ]||[ "$ubuntu_release" == "15.10" ]||[ "$ubuntu_release" == "16.04" ]; then
  if [ ${kernel_parts[0]} -lt 3 ]; then
    echo -e "\033[31m[ERROR] For Ubuntu $ubuntu_codename, Docker requires 3.10 kernel version at minimum, current version is ${kernel_parts_tmp[0]}\033[0m"
    exit 1
  fi
  if [ ${kernel_parts[0]} -eq 3 ] && [ ${kernel_parts[1]} -lt 10 ]; then
    echo -e "\033[31m[ERROR] For Ubuntu $ubuntu_codename, Docker requires 3.10 kernel version at minimum, current version is ${kernel_parts_tmp[0]}\033[0m"
    exit 1
  fi
else
  echo -e "\033[31m[ERROR] This installation script only supports Ubuntu 12.04, 14.04, 15.10 and 16.04, current ubuntu version is $ubuntu_release, you need to install docker by yourself\033[0m"
  exit 1
fi
echo -e "\033[32m[OK] Check kernel OK, current kernel version is ${kernel_parts_tmp[0]}\033[0m"

# STEP 02: check current docker
echo -e "\033[36m[INFO] STEP 02: Check current docker...\033[0m"
if command_exists docker ; then
  docker_version=(`docker version | grep Version | awk '{print $2}'`)
    if [ -z "$docker_version" ]; then
    echo -e "\033[31m[ERROR] Get docker version error, your docker must be 1.8.2 at minimum\033[0m"
    exit 1
  fi
  docker_version_invalid="false"
  for i in ${docker_version[@]}; do
    version_parts=(${i//./ })
    if [ ${version_parts[0]} -lt 1 ]; then
      docker_version_invalid="true"
      break
    fi
    if [ ${version_parts[0]} -eq 1 ] && [ ${version_parts[1]} -lt 8 ]; then
      docker_version_invalid="true"
      break
    fi
    if [ ${version_parts[0]} -eq 1 ] && [ ${version_parts[1]} -eq 8 ] && [ ${version_parts[2]} -lt 2 ]; then
      docker_version_invalid="true"
      break
    fi
  done
  if [ $docker_version_invalid == "true" ]; then
    echo -e "\033[31m[ERROR] Docker server and client version must be 1.8.2 at minimum, current version is $i\033[0m"
    exit 1
  fi
  echo -e "\033[32m[OK] Current docker server and client version is ${docker_version[0]}\033[0m"
else
  echo -e "\033[36m[INFO] Install Docker...\033[0m"
  set +e
  apt-get update
  apt-get install -y apt-transport-https ca-certificates
  if [ "$ubuntu_release" == "14.04" ]||[ "$ubuntu_release" == "15.10" ]||[ "$ubuntu_release" == "16.04" ]; then
    apt-get install -y linux-image-extra-$kernel_version
  fi
  if [ "$ubuntu_release" == "12.04" ]||[ "$ubuntu_release" == "14.04" ]; then
    apt-get install -y apparmor
  fi
  apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  if [ -f "$docker_list_file" ]; then
    rm -f $docker_list_file
  fi
  touch $docker_list_file
  echo "deb $docker_repo_url ubuntu-$ubuntu_codename main" > $docker_list_file
  apt-get update
  apt-get purge lxc-docker
  apt-cache policy docker-engine
  apt-get update
  apt-get install -y docker-engine
  set -e
  docker_version=(`docker version | grep Version | awk '{print $2}'`)
  echo -e "\033[32m[OK] Docker has been installed, version ${docker_version[0]}\033[0m"
fi
