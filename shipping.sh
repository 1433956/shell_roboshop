#!/bin/bash
Start_time=$(date +%s)

userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
Log_Folder="/var/logs/shipping-logs"
Script_Name=$(echo $0 | cut -d "." -f1)
Log_File="$Log_Folder/$Script_Name.log"
SYS_DIR=$PWD


echo -e "$Y script is started at=$(date) $N" | tee -a $Log_File

mkdir -p $Log_Folder

if [ $userid -ne 0 ]
then 
    echo -e "$R please log as a root user $N" &>>$Log_File
    exit 1
else
    echo -e "$G logged as a root user $N" &>>$Log_File
fi 
echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

VALIDATE() {
    if [ $1 -eq 0 ]
    then
        echo -e "$2.. $G success $N" | tee -a $Log_File
    else
        echo -e "$2.. $R failed $N" | tee -a $Log_File
        exit 1
    fi
}

dnf install maven -y &>> $Log_File
VALIDATE $? "installing maven"

#create system user 
 id roboshop

if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "creating system user for catalogue service" roboshop
    echo -e "$R system user is not created...$N"&>>$Log_File
    echo -e "$G  create system user .. $N"&>>$Log_File
    
 else
    echo -e "$G system user is already created $"&>>$Log_File
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$Log_File
VALIDATE $? "Downloading shipping"

rm -rf /app/*
cd /app &>>$Log_File

unzip /tmp/shipping.zip &>>$Log_File
VALIDATE $? "unzipping shipping"
 mvn clean package &>>$Log_File

mv target/shipping-1.0.jar shipping.jar  &>>$Log_File
VALIDATE $? "Moving and renaming Jar file"

cp $SYS_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "creating new service"

systemctl daemon-reload &>>$Log_File
VALIDATE $? " reloading service"

systemctl enable shipping  &>>$Log_File
VALIDATE $? "Enabling Shipping"

systemctl start shipping &>>$Log_File
VALIDATE $? "Starting Shipping 
#mysql 

mysql -V

if [ $? -ne 0]
then 
    dnf install mysql -y &>>$Log_File
else
     echo -e "$G mysql is already installed $N" &>>$Log_File
fi

mysql -h mysql.devops73.site -uroot -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$Log_File

if [ $? -ne 0 ]
then 
    mysql -h mysql.devops73.site -uroot -p$MYSQL_ROOT_PASS < /app/db/schema.sql &>>$Log_File
    mysql -h mysql.devops73.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$Log_File
    mysql -h mysql.devops73.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$Log_File
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi


systemctl restart shipping &>>$Log_File
VALIDATE $? "Restart shipping"
end_time=$(date +%s)
TOTAL_TIME=$(( $end_time - $Start_time ))
echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $Log_File