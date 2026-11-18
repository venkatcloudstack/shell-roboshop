#!/bin/bash

AMI_ID="ami-0055977a6e828a4f4"
ZONE_ID="Z1013544R9WOGN2CLNJ9"
DOMAIN_NAME="venkatcloudstack.shop"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#### validation ####
if [ $# -lt 2 ]; then
    echo -e "$R ERROR: atleast two args required $N"
    echo "USAGE: $0 [create/destroy] [instance1] [instance2]"
    exit 1
ficd
