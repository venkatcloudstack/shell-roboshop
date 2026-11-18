#!/bin/bash
LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR="$PWD"
MYSQL_HOST=mysql.venkatcloudstack.shop
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

dnf install maven -y  &>> $LOGS_FILE
VALIDATE $? "installing maven"
id roboshop         &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating systemuser"
else 
    echo -e "user roboshop is already created ...$Y SKIPPING $N"
fi
rm -rf /app  
VALIDATE $? "removing existing code"
rm -rf /tmp/shipping.zip  
VALIDATE $? "removing shipping zip"
mkdir -p /app 
VALIDATE $? "app directory created"

curl -o  /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip    &>> $LOGS_FILE
cd /app 
unzip /tmp/shipping.zip   &>> $LOGS_FILE
VALIDATE $? "downloaded and extracted code"

cd /app 
mvn clean package   &>> $LOGS_FILE
VALIDATE $? "downloading dependecies"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "created systemctl service"

dnf install mysql -y &>> $LOGS_FILE
VALIDATE $? "installing mysql"

mysql -h MySQL.venkatcloudstack.shop -u root -pRoboShop@1 -e "USE cities"
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
    VALIDATE $? "data loaded"
else
    echo  -e "data already loaded $Y SKIPPING $N"
fi

systemctl daemon-reload
systemctl enable shipping  &>> $LOGS_FILE
systemctl restart shipping &>> $LOGS_FILE
VALIDATE $? "restart shipping"






