alias ll='ls -l'
alias l='ls -F'
alias vm='vim'
alias LS='ls'
alias sl='ls'
alias vim='/usr/local/bin/vim'
alias gol='GOOS=linux GOARCH=amd64 go build'
alias goi='go build -i'
alias gbv='go build -mod=vendor'
alias gmv='go mod vendor'
alias python='/usr/local/bin/python3'
alias c='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'
alias cr='echo "--resolve cncdn18.92298.org:443:112.15.3.41"'
GOROOT=/usr/local/go/
export GOROOT
#export PATH=$PATH:/usr/local/mysql/bin
export LIBRARY_PATH="$LIBRARY_PATH:/usr/local/lib"
export SSLKEYLOGFILE=/tmp/sslkeylog.log
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH=$PATH:/Users/seanzhang/go/src/bin
alias date='date +"%Y-%m-%d %H:%M.%S"'
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/seanzhang/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/seanzhang/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/seanzhang/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/seanzhang/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup

export PATH=$PATH:/usr/local/mysql/bin
