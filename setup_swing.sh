#!/bin/bash

# Setup
if [[ ! -d $HOME/.swing ]]; then
  root_dir="$HOME/.swing"
  mkdir -p $root_dir

  touch $root_dir/paths
  touch $root_dir/names
  touch $root_dir/dir_to_cd

  unset root_dir
fi

# Completion
function __swing_completion() {
  local cur prev opts

  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts=$(awk -F'=' '{print $2}' $HOME/.swing/names | tr "\n" " ")

  if [[ ${prev} == "s" ]] ; then
    COMPREPLY=( $(compgen -W "${opts}" ${cur}) )
    return 0
  fi
}
complete -F __swing_completion s


function s() {
  # The swing function
  # This is sourced to perform "cd" in the current shell session

  (
    FOLDER_PREFIX="__dir_"
    action=$1
    root_dir="$HOME/.swing"
    paths_file="$root_dir/paths"
    names_file="$root_dir/names"
    cd_path="$root_dir/dir_to_cd"

    function __swing_get_folder_id() {
      local folder_name folder_slug folder_id

      folder_name=$1
      folder_slug=$(echo $folder_name | xargs | tr " .-" "_" | tr A-Z a-z)
      folder_id="$FOLDER_PREFIX$folder_slug"

      echo $folder_id
    }

    function __swing_get_folder_path() {
      local folder_id folder_path

      source $paths_file

      folder_id=$1
      folder_path="${!folder_id}"
      echo $folder_path
    }

    function __swing_init() {
      local folder_path folder_name folder_id old_path

      input_name=$1
      folder_path=$(pwd)
      folder_name=$([[ ! -z $input_name ]] && echo $input_name || basename $folder_path)
      folder_id=$(__swing_get_folder_id $folder_name)
      old_path=$(__swing_get_folder_path $folder_id)

      echo "$folder_id=$folder_path" >> $paths_file
      echo "$folder_id=$folder_name" >> $names_file
      echo "Created \"$folder_name\" for path [$folder_path]"
    }

    function __swing_write_to_cd() {
      local folder_name folder_id folder_path

      folder_name=$1
      folder_id=$(__swing_get_folder_id $folder_name)
      folder_path=$(__swing_get_folder_path $folder_id)

      echo "$folder_path" > $cd_path
    }

    if [[ $action == "init" ]]; then
      __swing_init $2
    else
      __swing_write_to_cd $action
    fi
  )

  if [[ ! $1 == "init" ]]; then
    dir_to_cd=$(cat $HOME/.swing/dir_to_cd)
    test ! -z $dir_to_cd && cd $dir_to_cd
    unset dir_to_cd
  fi
}
