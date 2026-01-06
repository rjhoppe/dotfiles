# ─────────────────────────────────────────────
# Detect if running inside an AI Agent Shell (Cursor or VSCode)
# ─────────────────────────────────────────────

# Reset mode just to be safe
unset ZSH_MINIMAL_AGENT

# Conservative AI agent detection - only trigger on specific indicators
if [[ "$TERM_PROGRAM" == "cursor" ]] || \
   [[ "$CURSOR_AGENT" == "1" ]] || \
   [[ "$TERM_PROGRAM" == "vscode" ]] || \
   [[ "$INSIDE_VSCODE" == "1" ]]; then
  export ZSH_MINIMAL_AGENT=1
  echo "🤖 AI Agent detected - Using minimal shell"
fi

# ─────────────────────────────────────────────
# Minimal shell for AI tools like Cursor/VSCode
# ─────────────────────────────────────────────
if [[ -n "$ZSH_MINIMAL_AGENT" ]]; then
  # Minimal prompt setup
  export PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '
  export RPROMPT=''

  # Disable interactive features
  export DEBIAN_FRONTEND=noninteractive
  export NONINTERACTIVE=1

  # Disable corrections and beeps
  unsetopt CORRECT
  unsetopt CORRECT_ALL
  setopt NO_BEEP
  setopt NO_HIST_BEEP
  setopt NO_LIST_BEEP

  # Force non-interactive aliases
  alias rm='rm -f'
  alias cp='cp -f'
  alias mv='mv -f'
  alias npm='npm --no-fund --no-audit'
  alias yarn='yarn --non-interactive'
  alias pip='pip --quiet'
  alias git='git -c advice.detachedHead=false'
  alias cl='claude'

  # Skip all heavy plugin loading
  # We'll only load essential history and path settings below

else
  # ─────────────────────────────────────────────
  # Full shell setup for human use (iTerm, etc.)
  # ─────────────────────────────────────────────

  echo "👤 Human terminal detected - Loading full shell"

  # Powerlevel10k Instant Prompt
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi

  # Zinit Setup (using your exact working configuration)
  if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
      print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
      command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
      command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
          print -P "%F{33} %F{34}Installation successful.%f%b" || \
          print -P "%F{160} The clone has failed.%f%b"
  fi

  source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
  autoload -Uz _zinit
  (( ${+_comps} )) && _comps[zinit]=_zinit

  # Install powerlevel10k
  zinit ice depth=1; zinit light romkatv/powerlevel10k
  # Install syntax highlighting
  zinit light zsh-users/zsh-syntax-highlighting
  # Install zsh completions
  zinit light zsh-users/zsh-completions
  # Install zsh autosuggestions
  zinit light zsh-users/zsh-autosuggestions
  # Tab fuzzy finding integration
  zinit light Aloxaf/fzf-tab

  # Add snippets
  zinit snippet OMZP::git
  zinit snippet OMZP::aws
  zinit snippet OMZP::azure
  zinit snippet OMZP::command-not-found
  zinit snippet OMZP::golang
  zinit snippet OMZP::colored-man-pages
  zinit snippet OMZP::jsontools

  # Load autocompletions
  autoload -U compinit && compinit

  # Used to replay all cached completions
  zinit cdreplay -q

  # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

  # Completion styling
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  zstyle ':completion:*' menu no
  zstyle ':fzf-tab:complete:cd*' fzf-preview 'ls --color $realpath'

  # Custom git command that pulls origin master/main everytime master/main is checked out
  gsm() {
    # Determine which primary branch is used: master or main
    if git rev-parse --verify master >/dev/null 2>&1; then
      primary_branch="master"
    elif git rev-parse --verify main >/dev/null 2>&1; then
      primary_branch="main"
    else
      echo "No master or main branch found."
      return 1
    fi

    # Check current branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Checkout primary branch only if not already on it
    if [[ "$current_branch" != "$primary_branch" ]]; then
      git checkout "$primary_branch" || return
    fi

    # Pull latest changes
    git pull origin "$primary_branch"
  }

fi

# ─────────────────────────────────────────────
# Common to all environments (agent + full)
# ─────────────────────────────────────────────

# PATH
export PATH=~/usr/bin:/bin:/usr/sbin:/sbin:$PATH

# History settings
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Editor and basic aliases
export EDITOR=/opt/homebrew/bin/nano
export VISUAL="$EDITOR"

alias ls='ls --color -a'
alias nvim='cd ~ && cd repos && ./nvim-macos-arm64/bin/nvim'
alias nvimc='cd ~/.config/nvim'

cb() {
  export CLAUDE_CODE_USE_BEDROCK=1
  export AWS_PROFILE=rhoppe
  export AWS_REGION=us-east-1
  command claude "$@"
}

# Shell integrations (only if not minimal)
if [[ -z "$ZSH_MINIMAL_AGENT" ]]; then
  eval "$(fzf --zsh)"
fi

# Development environment setup
# Java (Coursier) - only if not minimal or if java is needed
if [[ -z "$ZSH_MINIMAL_AGENT" ]] || [[ -n "$JAVA_REQUIRED" ]]; then
  if command -v cs &> /dev/null; then
    eval $("/Users/rhoppe/Library/Application Support/Coursier/bin/cs" java --jvm temurin:1.17 --env)
  fi
fi

# Work-specific flags
export LDFLAGS="-L/opt/homebrew/opt/freetds/lib -L/opt/homebrew/opt/openssl@3/lib"
export CFLAGS="-I/opt/homebrew/opt/freetds/include"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"

# Python version manager
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv &> /dev/null; then
  eval "$(pyenv init - zsh)"
fi

# Node version manager - only load if not minimal
if [[ -z "$ZSH_MINIMAL_AGENT" ]]; then
  export NVM_DIR="$HOME/.nvm"
  if [[ -f "$(brew --prefix nvm)/nvm.sh" ]]; then
    source $(brew --prefix nvm)/nvm.sh
  fi
fi

# Scala
export PATH="/opt/homebrew/opt/scala@2.12/bin:$PATH"

# Final status message
if [[ -n "$ZSH_MINIMAL_AGENT" ]]; then
  echo "✓ Minimal shell ready for AI agent"
else
  echo "✓ Full shell loaded for human use"
fi
export PATH="$HOME/.local/bin:$PATH"