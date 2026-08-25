# ─────────────────────────────────────────────────────────────────────────────
#  🇳🇵  NEPAL — Powerlevel10k theme
#  Palette: Crimson #DC143C · Blue #003893 · White #FFFFFF
#  Layout:  [flag] ── dir ── git ── ❯          ⏱ time on the right
# ─────────────────────────────────────────────────────────────────────────────

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # ── Nepal palette ─────────────────────────────────────────────────────────
  local NP_RED='#DC143C'      # crimson field
  local NP_BLUE='#003893'     # border blue
  local NP_WHITE='#FFFFFF'    # sun & moon
  local NP_SNOW='#F4F4F5'

  # ── Segments ──────────────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    nepal_flag              # 🇳🇵  the flag
    dir                     # current directory
    vcs                     # git branch + status
    prompt_char             # ❯  where you type
  )

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status                  # ✘ exit code of last command
    command_execution_time  # ⏱ how long it took
    background_jobs         # ⚙ running jobs
    direnv                  # 󰙪 direnv
    virtualenv              # 󰌠 python venv
    node_version            # 󰎙 node
    go_version              #  go
    java_version            #  java
    kubecontext             # 󱃾 k8s (only for kubectl/k9s/helm)
    time                    # 🕐 clock
  )

  typeset -g POWERLEVEL9K_MODE=nerdfont-v3
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate

  # ── Powerline separators ──────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=$''
  typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=$''
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=$''
  typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR=$''
  typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=$''
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=$''
  typeset -g POWERLEVEL9K_EMPTY_LINE_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''

  # ── Breathing room: blank line between every command ──────────────────────
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR=' '

  # ── 🇳🇵 flag segment ───────────────────────────────────────────────────────
  function prompt_nepal_flag() {
    p10k segment -b '#003893' -f '#FFFFFF' -t '🇳🇵'
  }
  function instant_prompt_nepal_flag() { prompt_nepal_flag }

  # ── Directory ─────────────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_DIR_BACKGROUND=$NP_RED
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND='#FFC4CE'
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=50
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT=50
  typeset -g POWERLEVEL9K_DIR_HYPERLINK=true
  typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=v3
  typeset -g POWERLEVEL9K_HOME_ICON='󰋜'
  typeset -g POWERLEVEL9K_HOME_SUB_ICON='󰉋'
  typeset -g POWERLEVEL9K_FOLDER_ICON='󰉋'
  typeset -g POWERLEVEL9K_ETC_ICON=''
  typeset -g POWERLEVEL9K_LOCK_ICON='󰌾'
  # Per-directory icons (DIR_CLASSES fully drives the icon once it is set)
  typeset -g POWERLEVEL9K_DIR_CLASSES=(
    '~/Android(|/*)'  ANDROID   ''
    '~/.kube(|/*)'    KUBE      ''
    '/etc(|/*)'       ETC       ''
    '~'               HOME      ''
    '~/*'             HOME_SUB  ''
    '*'               DEFAULT   ''
  )
  typeset -g POWERLEVEL9K_DIR_ANDROID_VISUAL_IDENTIFIER_EXPANSION='󰀲'
  typeset -g POWERLEVEL9K_DIR_KUBE_VISUAL_IDENTIFIER_EXPANSION='󱃾'
  typeset -g POWERLEVEL9K_DIR_ETC_VISUAL_IDENTIFIER_EXPANSION=''
  typeset -g POWERLEVEL9K_DIR_HOME_VISUAL_IDENTIFIER_EXPANSION='󰋜'
  typeset -g POWERLEVEL9K_DIR_HOME_SUB_VISUAL_IDENTIFIER_EXPANSION='󰉋'
  typeset -g POWERLEVEL9K_DIR_DEFAULT_VISUAL_IDENTIFIER_EXPANSION='󰉋'

  # ── Git (white segment — the sun & moon of the flag) ──────────────────────
  typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND=$NP_SNOW
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=$NP_BLUE
  typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=$NP_SNOW
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=$NP_RED
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND=$NP_SNOW
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=$NP_BLUE
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_BACKGROUND=$NP_RED
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_VCS_LOADING_BACKGROUND=$NP_SNOW
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND='#8A8A8A'

  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=' '
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON=' '
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
  typeset -g POWERLEVEL9K_VCS_UNSTAGED_ICON='●'
  typeset -g POWERLEVEL9K_VCS_STAGED_ICON='✚'
  typeset -g POWERLEVEL9K_VCS_STASH_ICON='󰆓'
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='󰇚'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='󰕒'
  typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'
  typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)

  function my_git_formatter() {
    emulate -L zsh
    if [[ -n $P9K_CONTENT ]]; then
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi
    local       meta='%f'
    local      clean='%2F'
    local   modified='%3F'
    local  untracked='%4F'
    local conflicted='%1F'

    local res
    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      local branch=${(V)VCS_STATUS_LOCAL_BRANCH}
      (( ${#branch} > 32 )) && branch[13,-13]="…"
      res+="%B${branch//\%/%%}%b"
    fi
    [[ -n $VCS_STATUS_TAG && -z $VCS_STATUS_LOCAL_BRANCH ]] && res+="${meta}#${(V)VCS_STATUS_TAG//\%/%%}"
    [[ -z $VCS_STATUS_LOCAL_BRANCH && -z $VCS_STATUS_TAG ]] && res+="${meta}@${VCS_STATUS_COMMIT[1,8]}"

    (( VCS_STATUS_COMMITS_BEHIND )) && res+=" ${meta}󰇚${VCS_STATUS_COMMITS_BEHIND}"
    (( VCS_STATUS_COMMITS_AHEAD  )) && res+=" ${meta}󰕒${VCS_STATUS_COMMITS_AHEAD}"
    (( VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" ${meta}⇠${VCS_STATUS_PUSH_COMMITS_BEHIND}"
    (( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && res+=" ${meta}⇢${VCS_STATUS_PUSH_COMMITS_AHEAD}"
    (( VCS_STATUS_STASHES        )) && res+=" ${meta}󰆓${VCS_STATUS_STASHES}"
    (( VCS_STATUS_NUM_CONFLICTED )) && res+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
    (( VCS_STATUS_NUM_STAGED     )) && res+=" ${meta}✚${VCS_STATUS_NUM_STAGED}"
    (( VCS_STATUS_NUM_UNSTAGED   )) && res+=" ${meta}●${VCS_STATUS_NUM_UNSTAGED}"
    (( VCS_STATUS_NUM_UNTRACKED  )) && res+=" ${meta}?${VCS_STATUS_NUM_UNTRACKED}"
    (( VCS_STATUS_HAS_UNSTAGED == -1 )) && res+=" ${meta}─"
    (( VCS_STATUS_NUM_CONFLICTED + VCS_STATUS_NUM_STAGED + VCS_STATUS_NUM_UNSTAGED + VCS_STATUS_NUM_UNTRACKED == 0 )) && res+=" ${meta}✔"

    typeset -g my_git_format=$res
  }
  functions -M my_git_formatter 2>/dev/null
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((my_git_formatter()))+${my_git_format}}'

  # ── Prompt character ❯ (right end of the prompt, where you type) ──────────
  typeset -g POWERLEVEL9K_PROMPT_CHAR_BACKGROUND=
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$NP_RED
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='#FF4D6D'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='V'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='▶'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_LEFT_WHITESPACE=' '
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_RIGHT_WHITESPACE=''
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''

  # ── Status (only complains when something failed) ─────────────────────────
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_BACKGROUND=$NP_RED
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_BACKGROUND=$NP_RED
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_VISUAL_IDENTIFIER_EXPANSION='󰚌'
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_BACKGROUND=$NP_RED
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_VISUAL_IDENTIFIER_EXPANSION='✘'

  # ── Command duration ──────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=2
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=1
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT=compact
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=$NP_SNOW
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$NP_RED
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION='󱎫'

  # ── Background jobs ───────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=$NP_BLUE
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=true
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION='󰑮'

  # ── Toolchain segments (blue, shown only when relevant) ───────────────────
  typeset -g POWERLEVEL9K_DIRENV_BACKGROUND=$NP_BLUE
  typeset -g POWERLEVEL9K_DIRENV_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_DIRENV_VISUAL_IDENTIFIER_EXPANSION='󰙪'

  typeset -g POWERLEVEL9K_VIRTUALENV_BACKGROUND=$NP_BLUE
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=''
  typeset -g POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION='󰌠'

  typeset -g POWERLEVEL9K_NODE_VERSION_BACKGROUND=$NP_BLUE
  typeset -g POWERLEVEL9K_NODE_VERSION_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY=true
  typeset -g POWERLEVEL9K_NODE_VERSION_VISUAL_IDENTIFIER_EXPANSION='󰎙'

  typeset -g POWERLEVEL9K_GO_VERSION_BACKGROUND=$NP_BLUE
  typeset -g POWERLEVEL9K_GO_VERSION_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_GO_VERSION_PROJECT_ONLY=true
  typeset -g POWERLEVEL9K_GO_VERSION_VISUAL_IDENTIFIER_EXPANSION=''

  typeset -g POWERLEVEL9K_JAVA_VERSION_BACKGROUND=$NP_BLUE
  typeset -g POWERLEVEL9K_JAVA_VERSION_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_JAVA_VERSION_PROJECT_ONLY=true
  typeset -g POWERLEVEL9K_JAVA_VERSION_FULL=false
  typeset -g POWERLEVEL9K_JAVA_VERSION_VISUAL_IDENTIFIER_EXPANSION=''

  # ── Kubernetes: only surfaces for k8s commands (you live in k9s) ──────────
  typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|kubens|kubectx|k9s|oc|istioctl|kogito|stern|flux|argocd'
  typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_BACKGROUND=$NP_BLUE
  typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_VISUAL_IDENTIFIER_EXPANSION='󱃾'
  typeset -g POWERLEVEL9K_KUBECONTEXT_CLASSES=(
    '*prod*'  PROD
    '*'       DEFAULT
  )
  typeset -g POWERLEVEL9K_KUBECONTEXT_PROD_BACKGROUND=$NP_RED
  typeset -g POWERLEVEL9K_KUBECONTEXT_PROD_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_KUBECONTEXT_PROD_VISUAL_IDENTIFIER_EXPANSION='󱃾'
  typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_CONTENT_EXPANSION='${P9K_KUBECONTEXT_CLOUD_CLUSTER:-${P9K_KUBECONTEXT_NAME}}${${:-/$P9K_KUBECONTEXT_NAMESPACE}:#/default}'
  typeset -g POWERLEVEL9K_KUBECONTEXT_PROD_CONTENT_EXPANSION=$POWERLEVEL9K_KUBECONTEXT_DEFAULT_CONTENT_EXPANSION

  # ── Clock (far right, crimson) ────────────────────────────────────────────
  typeset -g POWERLEVEL9K_TIME_BACKGROUND=$NP_RED
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=$NP_WHITE
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%-I:%M:%S %p}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false
  typeset -g POWERLEVEL9K_TIME_VISUAL_IDENTIFIER_EXPANSION='󰥔'

  # ── Icons lead their values on the right prompt too ───────────────────────
  typeset -g POWERLEVEL9K_STATUS_ERROR_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_DIRENV_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_VIRTUALENV_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_NODE_VERSION_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_GO_VERSION_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_JAVA_VERSION_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_KUBECONTEXT_PROD_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_TIME_ICON_BEFORE_CONTENT=true

  # ── Behaviour ─────────────────────────────────────────────────────────────
  # Keep the full flag prompt on every past command instead of collapsing it
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  (( ! $+functions[p10k] )) || p10k reload
}

typeset -g 'POWERLEVEL9K_CONFIG_FILE'=${${(%):-%x}:a}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
