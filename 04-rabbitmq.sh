#!/bin/bash
LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%Y-%m-%d %H-%M-%S")
USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $R please run this script with root access $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE () {

    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $2 is ...$R FAILED $N " | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $2 is ...$G SUCCESS $N" | tee -a $LOGS_FILE
    fi    
}

# cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> $LOGS_FILE
# VALIDATE $? "adding rabbitmq repo"

# dnf install rabbitmq-server -y  &>> $LOGS_FILE
# VALIDATE $? "installing rabbitmq"

# systemctl enable rabbitmq-server &>> $LOGS_FILE
# systemctl start rabbitmq-server  &>> $LOGS_FILE
# VALIDATE $? "enabling starting rabbitmq-server"

# rabbitmqctl add_user roboshop roboshop123
# rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
# VALIDATE $? "user and password setup"



#!/bin/bash

# Copy RabbitMQ repository
cp rabbitmq.repo  /etc/yum.repos.d/rabbitmq.repo &>> "$LOGS_FILE"
VALIDATE $? "Adding RabbitMQ repository"

# Install RabbitMQ
dnf install rabbitmq-server -y
VALIDATE $? "install rabbitmq"

# Enable RabbitMQ service
systemctl enable rabbitmq-server &>> "$LOGS_FILE"
VALIDATE $? "Enabling RabbitMQ service"

# Start RabbitMQ service
systemctl start rabbitmq-server &>> "$LOGS_FILE"
VALIDATE $? "Starting RabbitMQ service"

# Create RabbitMQ user
rabbitmqctl add_user roboshop roboshop123 &>> "$LOGS_FILE"
VALIDATE $? "Creating RabbitMQ user"

# Set RabbitMQ permissions
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> "$LOGS_FILE"
VALIDATE $? "Setting RabbitMQ permissions"


sudo rpm --import https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc

sudo rpm --import https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key

sudo rpm --import https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key


sudo dnf clean all

sudo dnf makecache

sudo dnf install -y logrotate

sudo dnf install -y erlang rabbitmq-server


sudo systemctl enable rabbitmq-server

sudo systemctl start rabbitmq-server

sudo systemctl status rabbitmq-server

sudo rabbitmqctl version

