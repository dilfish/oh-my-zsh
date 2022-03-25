# Protect against non-zsh execution of Oh My Zsh (use POSIX syntax here)
[ -n "$ZSH_VERSION" ] || {
  # ANSI formatting function (\033[<code>m)
  # 0: reset, 1: bold, 4: underline, 22: no bold, 24: no underline, 31: red, 33: yellow
  omz_f() {
    [ $# -gt 0 ] || return
    IFS=";" printf "\033[%sm" $*
  }
  # If stdout is not a terminal ignore all formatting
  [ -t 1 ] || omz_f() { :; }

  omz_ptree() {
    # Get process tree of the current process
    pid=$$; pids="$pid"
    while [ ${pid-0} -ne 1 ] && ppid=$(ps -e -o pid,ppid | awk "\$1 == $pid { print \$2 }"); do
      pids="$pids $pid"; pid=$ppid
    done

    # Show process tree
    case "$(uname)" in
    Linux) ps -o ppid,pid,command -f -p $pids 2>/dev/null ;;
    Darwin|*) ps -o ppid,pid,command -p $pids 2>/dev/null ;;
    esac

    # If ps command failed, try Busybox ps
    [ $? -eq 0 ] || ps -o ppid,pid,comm | awk "NR == 1 || index(\"$pids\", \$2) != 0"
  }

  {
    shell=$(ps -o pid,comm | awk "\$1 == $$ { print \$2 }")
    printf "$(omz_f 1 31)Error:$(omz_f 22) Oh My Zsh can't be loaded from: $(omz_f 1)${shell}$(omz_f 22). "
    printf "You need to run $(omz_f 1)zsh$(omz_f 22) instead.$(omz_f 0)\n"
    printf "$(omz_f 33)Here's the process tree:$(omz_f 22)\n\n"
    omz_ptree
    printf "$(omz_f 0)\n"
  } >&2

  return 1
}

# If ZSH is not defined, use the current script's directory.
[[ -z "$ZSH" ]] && export ZSH="${${(%):-%x}:a:h}"

# Set ZSH_CACHE_DIR to the path where cache files should be created
# or else we will use the default cache/
if [[ -z "$ZSH_CACHE_DIR" ]]; then
  ZSH_CACHE_DIR="$ZSH/cache"
fi

# Make sure $ZSH_CACHE_DIR is writable, otherwise use a directory in $HOME
if [[ ! -w "$ZSH_CACHE_DIR" ]]; then
  ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
fi

# Create cache and completions dir and add to $fpath
mkdir -p "$ZSH_CACHE_DIR/completions"
(( ${fpath[(Ie)"$ZSH_CACHE_DIR/completions"]} )) || fpath=("$ZSH_CACHE_DIR/completions" $fpath)

# Check for updates on initial load...
if [ "$DISABLE_AUTO_UPDATE" != "true" ]; then
  source $ZSH/tools/check_for_upgrade.sh
fi

# Initializes Oh My Zsh

# add a function path
fpath=($ZSH/functions $ZSH/completions $fpath)

# Load all stock functions (from $fpath files) called below.
autoload -U compaudit compinit

# Set ZSH_CUSTOM to the path where your custom config files
# and plugins exists, or else we will use the default custom/
if [[ -z "$ZSH_CUSTOM" ]]; then
    ZSH_CUSTOM="$ZSH/custom"
fi


is_plugin() {
  local base_dir=$1
  local name=$2
  builtin test -f $base_dir/plugins/$name/$name.plugin.zsh \
    || builtin test -f $base_dir/plugins/$name/_$name
}

# Add all defined plugins to fpath. This must be done
# before running compinit.
for plugin ($plugins); do
  if is_plugin $ZSH_CUSTOM $plugin; then
    fpath=($ZSH_CUSTOM/plugins/$plugin $fpath)
  elif is_plugin $ZSH $plugin; then
    fpath=($ZSH/plugins/$plugin $fpath)
  else
    echo "[oh-my-zsh] plugin '$plugin' not found"
  fi
done

# Figure out the SHORT hostname
if [[ "$OSTYPE" = darwin* ]]; then
  # macOS's $HOST changes with dhcp, etc. Use ComputerName if possible.
  SHORT_HOST=$(scutil --get ComputerName 2>/dev/null) || SHORT_HOST=${HOST/.*/}
else
  SHORT_HOST=${HOST/.*/}
fi

# Save the location of the current completion dump file.
if [ -z "$ZSH_COMPDUMP" ]; then
  ZSH_COMPDUMP="${ZDOTDIR:-${HOME}}/.zcompdump-${SHORT_HOST}-${ZSH_VERSION}"
fi

# Construct zcompdump OMZ metadata
zcompdump_revision="#omz revision: $(builtin cd -q "$ZSH"; git rev-parse HEAD 2>/dev/null)"
zcompdump_fpath="#omz fpath: $fpath"

# Delete the zcompdump file if OMZ zcompdump metadata changed
if ! command grep -q -Fx "$zcompdump_revision" "$ZSH_COMPDUMP" 2>/dev/null \
   || ! command grep -q -Fx "$zcompdump_fpath" "$ZSH_COMPDUMP" 2>/dev/null; then
  command rm -f "$ZSH_COMPDUMP"
  zcompdump_refresh=1
fi

if [[ $ZSH_DISABLE_COMPFIX != true ]]; then
  source $ZSH/lib/compfix.zsh
  # If completion insecurities exist, warn the user
  handle_completion_insecurities
  # Load only from secure directories
  compinit -i -C -d "${ZSH_COMPDUMP}"
else
  # If the user wants it, load from all found directories
  compinit -u -C -d "${ZSH_COMPDUMP}"
fi

# Append zcompdump metadata if missing
if (( $zcompdump_refresh )); then
  # Use `tee` in case the $ZSH_COMPDUMP filename is invalid, to silence the error
  # See https://github.com/ohmyzsh/ohmyzsh/commit/dd1a7269#commitcomment-39003489
  tee -a "$ZSH_COMPDUMP" &>/dev/null <<EOF

$zcompdump_revision
$zcompdump_fpath
EOF
fi

unset zcompdump_revision zcompdump_fpath zcompdump_refresh


# Load all of the config files in ~/oh-my-zsh that end in .zsh
# TIP: Add files you don't want in git to .gitignore
for config_file ($ZSH/lib/*.zsh); do
  custom_config_file="${ZSH_CUSTOM}/lib/${config_file:t}"
  [ -f "${custom_config_file}" ] && config_file=${custom_config_file}
  source $config_file
done

# Load all of the plugins that were defined in ~/.zshrc
for plugin ($plugins); do
  if [ -f $ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh ]; then
    source $ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh
  elif [ -f $ZSH/plugins/$plugin/$plugin.plugin.zsh ]; then
    source $ZSH/plugins/$plugin/$plugin.plugin.zsh
  fi
done

# Load all of your custom configurations from custom/
for config_file ($ZSH_CUSTOM/*.zsh(N)); do
  source $config_file
done
unset config_file

# Load the theme
# ZSH_THEME='random'
if [ ! "$ZSH_THEME" = ""  ]; then
  if [ -f "$ZSH_CUSTOM/$ZSH_THEME.zsh-theme" ]; then
    source "$ZSH_CUSTOM/$ZSH_THEME.zsh-theme"
  elif [ -f "$ZSH_CUSTOM/themes/$ZSH_THEME.zsh-theme" ]; then
    source "$ZSH_CUSTOM/themes/$ZSH_THEME.zsh-theme"
  else
    source "$ZSH/themes/$ZSH_THEME.zsh-theme"
  fi
fi




#Bash Insulter
if [ -f /etc/bash.command-not-found ]; then
    source /etc/bash.command-not-found
fi

#export GODEBUG=http2debug=2
export GOROOT=/usr/local/go
alias cm="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias pj="python -m json.tool"
export PATH=$PATH:/usr/local/mysql/bin/
export PATH=$PATH:/usr/local/mongodb-macos-x86_64-4.4.2/bin
alias python='/usr/local/bin/python3'
export GO111MODULE=on
alias 'python'='python3'
alias gol='export GOOS=linux GOARCH=amd64; go build; export GOOS="" GOARCH=""'
alias dcs='docker container stop'
alias dcr='docker container rm'
alias dcl='docker container ls -a'
alias dil='docker image ls -a'
alias curls='echo "curl https://dilfish.dev --resolve dilfish.dev:443:119.28.7.122"'
alias gpum='git pull upstream master'
alias gpud='git pull upstream develop'
alias ls9="ls -la | awk '{print \$9}'"
alias curl2="/usr/bin/curl"
alias curl3="/usr/local/Cellar/curl/7.80.0/bin/curl"
alias runm="mongod --config /usr/local/etc/mongod.conf"
alias gb="go build"
alias gi="go install"
alias gt="go test"
alias emoji="curl https://dilfish.icu/emoji"
alias exifmod='exiftool -GPSDateStamp="1970:01:02" -GPSDateStamp=0 -GPSLongitude=180 -GPSLatitude=90 -GPSAltitude=8848.86 -software="Windows 1.1.330(2QEMT35U3X1)" -model="Isaac Newton" -DateTime="1970:01:01 00:00:03" -DateTimeDigital="1970:01:01 00:00:04" -DateTimeOriginal="1970:01:01 00:00:07" -CreateDate="1970:01:01 00:00:05" -ModifyDate="1970:01:01 00:00:06" -Make="Albert Einstein" -Manufacturer="James Clerk Maxwell" -HostComputer="Richard Feynman" -ContentIdentifier="Galileo Galilei" -ProfileCopyright="CarlFGauss" -DateCreated="1970:01:01 00:00:07"'
function ggb() {
    go build
    export GOROOT="/usr/local/go"
}

function gmi() {
    go mod init github.com/dilfish/$1
    go mod tidy
}

function randstr() {
    cat /dev/urandom | base64 | fold -w $1 | head
}

function limaenv() {
    export DOCKER_HOST=$(limactl list docker --format 'unix://{{.Dir}}/sock/docker.sock')
    unset DOCKER_TLS_VERIFY
}

export PATH=$PATH:/usr/local/go/bin/
export PATH=$PATH:/usr/local/nginx/sbin/

# for linux
if [[ "$OSTYPE" = linux-gnu ]]; then
    export PATH=$PATH:/root/go/bin/
# for mac
else
    export PATH=$PATH:/Users/dilfish/go/bin
    export SSLKEYLOGFILE=/Users/dilfish/sslkeylogfile
fi

export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/Applications/Julia-1.6.app/Contents/Resources/julia/bin
export GOPROXY=https://goproxy.cn
#source /usr/local/opt/resty/share/resty/resty
export QBOXROOT=/Users/dilfish/qiniu
export PATH=$PATH:/usr/local/Cellar/rabbitmq/3.8.16/sbin
#source ~/.iterm2_shell_integration.zsh
#
export GITHUB_TOKEN=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
export PATH=$PATH:/Users/dilfish/.cargo/bin/
export DOCKER_HOST='unix:///Users/dilfish/.lima/docker/sock/docker.sock'
