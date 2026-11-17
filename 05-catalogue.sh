#!/bin/bash
LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD
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

dnf module disable nodejs -y    &>> $LOGS_FILE
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y  &>> $LOGS_FILE
VALIDATE $? "enabling nodejs"

dnf install nodejs -y           &>> $LOGS_FILE
VALIDATE $? "installing nodejs"

id roboshop         &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating systemuser"
else 
    echo -e "user roboshop is already created ...$Y SKIPPING $N"
fi

rm -rf /app  
VALIDATE $? "removing existing code"
rm -rf /tmp/catalogue.zip  
VALIDATE $? "removing catalogue zip"
mkdir -p /app 
VALIDATE $? "app directory created"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip   &>> $LOGS_FILE
cd /app 
unzip /tmp/catalogue.zip   &>> $LOGS_FILE
VALIDATE $? "downloaded and extracted code"

cd /app 
npm install  &>> $LOGS_FILE
VALIDATE $? "downloading dependecies"

cp $SCRIPT_DIR/catalogue.service  /etc/systemd/system/catalogue.service
VALIDATE $? "created systemctl service"

cp $SCRIPT_DIR/mongo.repo  /etc/yum.repos.d/mongo.repo
VALIDATE $? "added mongo repo"

dnf install mongodb-mongosh -y
VALIDATE $? "installing mongodb-client"
 


