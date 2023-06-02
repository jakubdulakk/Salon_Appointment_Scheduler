#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ My Salon ~~~~~\n"

MAIN_MENU() {

  if [[ $1 ]]
  then
  echo -e "\n$1"
  fi

  # get available services
  AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")

  # display available services
  echo -e "\nWelcome to My Salon, how can I help you?"

  echo "$AVAILABLE_SERVICES" | while IFS='|' read -r SERVICE_ID NAME
  do
    trimmed_service_id=$(echo "$SERVICE_ID" | tr -d ' ')
    trimmed_name=$(echo "$NAME" | sed 's/  */ /g')
    printf "%s) %s\n" "$trimmed_service_id" "$trimmed_name"
  done

  # Prompt for service selection
  while true
  do
    read SERVICE_ID_SELECTED

    # Check if input is a number
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
      echo -e "\nInvalid input. Please enter a valid service number."
      continue
    fi

    # Validate if the selected service exists
    exists=$($PSQL "SELECT EXISTS(SELECT 1 FROM services WHERE service_id = $SERVICE_ID_SELECTED)")
    exists=$(echo $exists | tr -d ' ')  # Remove leading/trailing whitespace

    if [ "$exists" = "f" ]
    then
      echo -e "\nI could not find that service. Please enter a valid service number."
      continue
    fi

    break
  done

  # get customer info
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  # if customer doesn't exist
  if [[ -z $CUSTOMER_NAME ]]
  then
    # get new customer name
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME

    # insert new customer
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")

    # retrieve the newly inserted customer's ID
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE name = '$CUSTOMER_NAME'")
  else
    # retrieve the existing customer's ID
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  fi

  # get appointment time
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
  echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME

  # insert appointment time into the appointment table
  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

  # confirm appointment
  echo -e "\nI have scheduled you for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
}

MAIN_MENU
