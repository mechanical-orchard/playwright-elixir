#!/usr/bin/env sh

localcopy() {
  content="$1"

  if command -v pbcopy >/dev/null; then
    echo -n ${content} | pbcopy
  elif command -v xclip >/dev/null; then
    echo "$content" | xclip -selection clipboard
  else
    cecho -n --yellow "You're missing a suitable copy command; here's the content I tried to copy:"
    cecho -n --yellow "$content"
  fi
}

check() {
  description=$1
  command=$2
  remedy=$3

  cecho -n --green "•" --cyan "${description}"

  shell_flags=$-
  set +e

  eval "${command} > .doctor.out 2>&1"
  command_exit_status=$?

  if [[ $shell_flags =~ e ]]
  then set -e
  else set +e
  fi


  if [ $command_exit_status -eq 0 ]; then
    cecho --bold-green "OK"
    return 0
  else
    cecho --red "FAILED"
    cat .doctor.out
    cecho --cyan "Possible remedy: " --yellow "${remedy}"
    cecho --cyan "(it's in the clipboard)"
    localcopy "$remedy"
    exit 1
  fi
}

xcheck() {
  description=$1
  command=$2
  remedy=$3

  cecho -n --yellow "[checking] ${description}" --white "... "
  cecho --yellow "SKIPPED"
  return 0
}
