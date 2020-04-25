#!/bin/bash -eux

# Remove Ansible and its dependencies.
yum -y remove ansible

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync
