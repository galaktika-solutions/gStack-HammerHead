#!/bin/bash
set -e

. /src/docker/main/utils.sh

check_secert_file() {
  if ! [ -f ".secret.env" ]; then
    touch .secret.env
  fi
  chmod 600 .secret.env
}

wrapped_createsecret() {
  check_secert_file

  read -p "What is the name of the secret? " secret

  replace=''
  if readsecret "$secret" > /dev/null; then
    answer="$(ask_user "The secret already exists. Would you like to replace it?" no yes)"
    if [ "$answer" = 'yes' ]; then
      replace=1
    else
      return 0
    fi
  fi

  typ="$(ask_user "What is the source of the secret?" \
    "file in the .files directory" \
    "random string" \
    "input in the terminal" \
  )"

  mode=''
  case ${typ:0:1} in
    f)
      mode='-f'
      array=()
      while IFS=  read -r -d $'\0'; do
        array+=("$REPLY")
      done < <(find .files -type f -printf "%P\0")
      param=".files/$(ask_user "Choose the file:" "${array[@]}")"
      ;;
    r)
      mode='-r'
      while true; do
        read -p "Enter the length of the string (1-999): " param
        if [[ "$param" =~ ^([1-9]|[1-9][0-9]|[1-9][0-9][0-9])$ ]]; then
          break
        fi
      done
      ;;
    i)
      read -p "Enter the secret value: " param
      ;;
  esac
  createsecret $mode "$secret" "$param" $replace
}

wrapped_readsecret() {
  check_secert_file
  array=()
  while read; do
    array+=("$REPLY")
  done < <(sed -rn 's/^([^#=]+).*$/\1/p' .secret.env | sort)

  readsecret "$(ask_user "Select a secret:" "${array[@]}")"
}
