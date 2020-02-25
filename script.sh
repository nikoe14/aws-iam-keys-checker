#!/bin/bash

calcage() {
  local user="$1"
  local today=$(date +%s)
  local CURRENT_KEY_ID=$(aws iam list-access-keys --user-name "$user" --output json | jq '.AccessKeyMetadata[] | select(.Status == "Active") | .CreateDate' | tr -d '"')
  local CREATED_ON=$(aws iam list-access-keys --user-name "$user" --output json | jq '.AccessKeyMetadata[] | select(.Status == "Active") | .CreateDate' | tr -d '"')
  ACCESS_KEY=$(aws iam list-access-keys --user-name "$user" --output json | jq '.AccessKeyMetadata[] | select(.Status == "Active") | .AccessKeyId' | tr -d '"')

  for dates in $CURRENT_KEY_ID;
  do
    d2=$(date -d "$dates" +%s)
    keyageinsec=$(expr $today - $d2)
    age=$(expr $keyageinsec / 86400)
    return $age
  done
}

notify () {
  local destination="$1"
  local user="$2"
  local age="$3"
  local aws_console_url="$4" 
  

  sendemail -q \
    -f "$support_email" \
    -u 'AWS API Key rotation' \
    -t "$destination" \
    -s 'smtp.gmail.com:587' \
    -o 'tls=yes' \
    -o "username=$support_email" \
    -o "password=$support_email_password" \
    -m "The (stage) API KEY for $user is $age days old and must be rotated.\n$aws_console_url"
}

account_alias=$(aws --output text iam list-account-aliases --query 'AccountAliases[0]')
aws_console_url="https://${account_alias}.signin.aws.amazon.com/console"

for user in $(aws iam list-users --output json | jq -r ".Users[].UserName");
do
  calcage "$user"
  if [[ -n "$ACCESS_KEY" && $age -ge $age_limit ]]; then
    email=$(aws iam list-user-tags --user-name $user --output json | jq '.Tags[] | select(.Key=="email") | .Value' | tr -d '"')
    echo "Sending email to $user at $email"
    notify "$email" "$user" "$age" "$aws_console_url"
    #2> /dev/null
  else
    echo "$user is OK."
  fi
done