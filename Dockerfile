
FROM amazonlinux:latest

COPY . .

RUN yum install -y \
  https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 


RUN yum install -y \
  unzip \
  jq \
  sendemail

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

ENTRYPOINT ["sh", "script.sh"]
