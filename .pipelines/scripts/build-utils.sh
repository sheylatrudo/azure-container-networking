#!/bin/bash

aquarius::internal::qpushd()  {
    command pushd "$@" >/dev/null
}

aquarius::internal::qpopd()  {
    command popd "$@" >/dev/null
}

aquarius::internal::unset_errexit()  {
  if [ -o errexit ]; then
    set +e
  fi
  return 0
}

aquarius::internal::set_errexit()  {
  if ! [ -o errexit ]; then
    set -e
  fi
  return 0
}

aquarius::internal::unset_xtrace()  {
  AQUARIUS_TOOLS_unsetxtrace_called=1
  if [ -o xtrace ]; then
    AQUARIUS_TOOLS_xtrace_isset=1
    set +x
  else
    AQUARIUS_TOOLS_xtrace_isset=0
  fi
  return 0
}

aquarius::internal::reset_xtrace()  {
  AQUARIUS_TOOLS_unsetxtrace_called=${AQUARIUS_TOOLS_unsetxtrace_called:-0}
  if [[ $AQUARIUS_TOOLS_unsetxtrace_called == 1 ]] && [[ $AQUARIUS_TOOLS_xtrace_isset == 1 ]]; then
    AQUARIUS_TOOLS_unsetxtrace_called=0
    set -x
  fi
  return 0
}

aquarius::internal::stacktrace()  {
  local i=1 line file func
  while read -r line func file < <(caller $i); do
    file=$(realpath $file)
    echo >&2 "[$i] $file:$line $func():"
    echo -e >&2 "\t>>>$(sed -n ${line}p $file)"
    #awk 'NR>L-4 && NR<L+4 { printf "%-5d%3s%s\n",NR,(NR==L?">>>":""),$0 }' L=${line} ${file} >&2 # expanded err info
    ((i++))
  done
}

aquarius::internal::err_trap_handler()  {
  aquarius::internal::stacktrace
}

aquarius::internal::print_subprocess()  {
  local cmd="${@}"

  eval "${cmd}" >&2
  return "$?"
}

aquarius::internal::array_contains()  {
  local value="${1}"
  local arr="${@:2}"
  [[ "${arr[@]}" =~ (^|[[:space:]])"${value}"($|[[:space:]]) ]] && return 0 || return 1
}

aquarius::internal::verify_say_type()  {
  local value="${1}"
  local logging_opts="group endgroup section info debug warning error command"
  if ! $(aquarius::internal::array_contains "${value}" "${logging_opts}"); then
    aquarius::tools::say error "The selected logging option (${value}) is invalid. Please choose one of: ${logging_opts[@]}"
    return 1
  fi
  return 0
}

aquarius::tools::say()  {
  local say_type
  local what

  aquarius::internal::set_errexit
  say_type="${1}"
  aquarius::internal::verify_say_type "$say_type"
  shift

  # Unset x as per:
  # https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=bash#logging-command-format
  trap 'aquarius::internal::reset_xtrace' ERR RETURN
  aquarius::internal::unset_xtrace

  what="$@"
  echo "##[$say_type]$what" >&2
}

aquarius::tools::act()  {
  local cmd
  local exit

  aquarius::internal::set_errexit
  cmd="${@}"
  aquarius::internal::unset_errexit

  aquarius::tools::say command "${cmd}"
  aquarius::internal::print_subprocess "${cmd}"
  exit="${?}"
  return "${exit}"
}

aquarius::tools::var()  {
  local length
  local varname
  local optone
  local opttwo
  local setopts

  aquarius::internal::set_errexit
  length="${#@}"
  varname="${1}"
  optone="${@:2}"
  opttwo="${@:3}"

  setopts="variable=${varname};"
  if [ "${length}" -gt 2 ] && [[ "${optone}" =~ "secret" ]]; then
    setopts+="issecret=true;"
    shift
    if [ "${length}" -gt 3 ] && [[ "${opttwo}" =~ "output" ]]; then
      setopts+="isoutput=true;"
      shift
    fi
  elif [ "${length}" -gt 2 ] && [[ "${optone}" =~ "output" ]]; then
    setopts+="isoutput=true;"
    shift
    if [ "${length}" -gt 3 ] && [[ "${opttwo}" =~ "secret" ]]; then
      setopts+="issecret=true;"
      shift
    fi
  fi
  # shifting for var name
  shift

  aquarius::internal::unset_xtrace

  aquarius::tools::say debug "Adding ${varname} to build environment"

  local var="${@}"
  # Escaping build weirdness when it tries to see this as a directive
  # when written out.
  local esc="#"
  local vesc="vso"
  aquarius::tools::say debug "[${setopts}]=${var}"
  echo "#${esc}${vesc}[task.setvariable ${setopts}]${var}" >&2
  return 0
}

aquarius::tools::add_to_path()  {
  local target
  aquarius::internal::set_errexit
  target="${@}"
  # Escaping build weirdness when it tries to see this as a directive
  # when written out.
  if [ -d "$target" ] && [[ ! $PATH =~ (^|:)$target(:|$) ]]; then
    local esc="#"
    local vesc="vso"

    aquarius::tools::say debug "PATH+=${target}"
    # Prepended path does not take effect until subsequent tasks.
    # Adding here for immediate effect in same task.
    PATH+=:$1
    echo "#${esc}${vesc}[task.prependpath]${target}" >&2
  fi
  return 0
}

aquarius::tools::fail()  {
  local message
  message="${@}"

  local esc="#"
  local vesc="vso"
  echo "#${esc}${vesc}[task.complete result=Failed]${message}" >&2
  return 1
}

aquarius::tools::retry()  {
  # From aks::devinfra::retry
  local retries
  local cmd

  aquarius::internal::set_errexit
  retries="${1}"
  shift
  cmd="${@}"
  aquarius::internal::unset_errexit

  local exit
  local count=0
  aquarius::tools::say "command" "${cmd}"
  until ${cmd}; do
    exit=$?
    let rand_extra=$(shuf -i 0-30 -n 1)
    let wait="(2 ** ${count}) + ${rand_extra}"
    let count="${count} + 1"
    if [ "${count}" -lt "${retries}" ]; then
      aquarius::tools::say warning "Retry ${count}/${retries} exited ${exit}, retrying in ${wait} seconds..."
      sleep "${wait}"
    else
      aquarius::tools::say error "Retry ${count}/${retries} exited ${exit}, no more retries left."
      return "${exit}"
    fi
  done
  return 0
}

aquarius::tools::get_branches()  {
  local git_root_dir

  aquarius::internal::set_errexit
  git_root_dir="${1}"

  local git_revision
  local result
  aquarius::internal::qpushd "${git_root_dir}"
    git_revision=$(git rev-parse HEAD)
    result=$(git log -1 --simplify-by-decoration --pretty=format:%D "${git_revision}" | sed 's/ //g' | sed 's/,/ /g' | sed 's/tag://g' | sed 's/origin\///g')
  aquarius::internal::qpopd
  printf "${result}"
}

aquarius::tools::get_tags()  {
  local git_root_dir

  aquarius::internal::set_errexit
  git_root_dir="${1}"

  local git_revision
  local result
  aquarius::internal::qpushd "${git_root_dir}"
    git_revision=$(git rev-parse HEAD)
    result=$(git tag --points-at "${git_revision}" | sed 's/ //g' | sed 's/,/ /g' | sed 's/tag://g')
  aquarius::internal::qpopd
  printf "${result}"
}

aquarius::internal::dedup()  {
  local input=("${@}")
  input=( "$(tr ' ' '\n' <<< "${input[@]}" | sort -u | tr '\n' ' ')" )
  printf "${input[@]}"
}

aquarius::tools::filter_head()  {
  local tag_list=("${@}")
  local result=()

  for tag in "${tag_list[@]}"; do
    if ! [[ "${tag}" =~ [H][E][A][D][-]['>'].* || "${tag}" =~ .*[/]?[H][E][A][D] ]]; then
      result+=( "${tag}" )
    fi
  done
  result=( "$(aquarius::internal::dedup ${result[@]})" )
  printf "${result[@]}"
}

aquarius::tools::enable_commits()  {
  aquarius::tools::act "git config --local user.name \"${BUILD_REQUESTEDFOR}\""
  aquarius::tools::act "git config --local user.email \"${BUILD_REQUESTEDFOREMAIL}\""
}

aquarius::tools::build_requested_for_alias()  {
  echo -n "${BUILD_REQUESTEDFOREMAIL%@*}"
}

aquarius::internal::init()  {
  #exec 3<> 3>&2
  echo "Loaded" >&2
}

if [[ "$_" != "$0" ]]; then
  aquarius::tools::say group "Loading Aquarius Pipelines Debug Tools Library"
  aquarius::internal::init
  aquarius::tools::say endgroup
fi
