#!/bin/bash
LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR="$PWD"
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

dnf install python3 gcc python3-devel -y  &>> $LOGS_FILE
VALIDATE $? "installing python"

id roboshop         &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating systemuser"
else 
    echo -e "user roboshop is already created ...$Y SKIPPING $N"
fi
rm -rf /app  
VALIDATE $? "removing existing code"
rm -rf /tmp/payment.zip  
VALIDATE $? "removing payment zip"
mkdir -p /app 
VALIDATE $? "app directory created"

curl -o  /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip    &>> $LOGS_FILE
cd /app 
unzip /tmp/payment.zip   &>> $LOGS_FILE
VALIDATE $? "downloaded and extracted code"

cd /app 
pip3 install -r requirements.txt   &>> $LOGS_FILE
VALIDATE $? "downloading dependecies"


cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "created systemctl service"


systemctl daemon-reload
systemctl enable payment  &>> $LOGS_FILE
systemctl restart payment &>> $LOGS_FILE
VALIDATE $? "restart payment"






