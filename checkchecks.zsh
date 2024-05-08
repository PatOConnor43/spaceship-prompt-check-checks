#
# check-checks
#

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_CHECKCHECKS_ASYNC="${SPACESHIP_CHECKCHECKS_ASYNC=true}"
SPACESHIP_CHECKCHECKS_SHOW="${SPACESHIP_CHECKCHECKS_SHOW=true}"
SPACESHIP_CHECKCHECKS_PREFIX="${SPACESHIP_CHECKCHECKS_PREFIX="GHA: "}"
SPACESHIP_CHECKCHECKS_SUFFIX="${SPACESHIP_CHECKCHECKS_SUFFIX=""}"
SPACESHIP_CHECKCHECKS_SYMBOL="${SPACESHIP_CHECKCHECKS_SYMBOL="…"}"
SPACESHIP_CHECKCHECKS_SUCCESS_SYMBOL="${SPACESHIP_CHECKCHECKS_SUCCESS_SYMBOL="󰄬"}"
SPACESHIP_CHECKCHECKS_SUCCESS_COLOR="${SPACESHIP_CHECKCHECKS_SUCCESS_COLOR="green"}"
SPACESHIP_CHECKCHECKS_RUNNING_SYMBOL="${SPACESHIP_CHECKCHECKS_RUNNING_SYMBOL="󰉁"}"
SPACESHIP_CHECKCHECKS_RUNNING_COLOR="${SPACESHIP_CHECKCHECKS_RUNNING_COLOR="yellow"}"
SPACESHIP_CHECKCHECKS_FAILED_SYMBOL="${SPACESHIP_CHECKCHECKS_FAILED_SYMBOL="󰀨"}"
SPACESHIP_CHECKCHECKS_FAILED_COLOR="${SPACESHIP_CHECKCHECKS_FAILED_COLOR="red"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Shows if there are any spaceship async jobs active
spaceship_checkchecks() {
  # Return if Spaceship works syncronosly
  spaceship::is_prompt_async || return

  # Return if this section is hidden
  [[ "$SPACESHIP_CHECKCHECKS_SHOW" == false ]] && return

  local is_git_repo="$(spaceship::upsearch .git)"
  [[ -z "$is_git_repo" ]] && return

  local cache_json=`cat /tmp/checkchecks`
  local json=""

  # Try to find json in the cache
  if [[ "$cache_json" != "" ]]; then
    local timestamp=`echo $cache_json | jq -r '.timestamp'`
    # Create a unix timestamp 10 seconds in the future
    local time_now=`date +%s`

    local cached_commit=`echo $cache_json | jq -r '.commit'`
    local now_commit=`git rev-parse HEAD`
    if [[ $(($timestamp + 10)) -gt $time_now ]] && [[ "$now_commit" == "$cached_commit" ]]; then
      local json="$cache_json"
      local cache_hit=1
    fi
  fi

  # If we haven't set json, fetch it
  if [[ "$json" == "" ]]; then
    local json=`gh check-checks`
    if [[ $? -ne 0 ]]; then
      return
    fi
    local appended_json=`echo $json | jq '. + {"timestamp": now | floor}'`
    echo $appended_json > /tmp/checkchecks
  fi

  local running=`echo $json | jq -r '.runningCount'`
  if [[ $running -gt 0 ]]; then
    spaceship::section \
      --color "$SPACESHIP_CHECKCHECKS_RUNNING_COLOR" \
      --prefix "$SPACESHIP_CHECKCHECKS_PREFIX" \
      --suffix "$SPACESHIP_CHECKCHECKS_SUFFIX" \
      --symbol "$SPACESHIP_CHECKCHECKS_RUNNING_SYMBOL " \
      "$running"
    return
  fi

  local failed=`echo $json | jq -r '.failedCount'`
  if [[ $failed -gt 0 ]]; then
    spaceship::section \
      --color "$SPACESHIP_CHECKCHECKS_FAILED_COLOR" \
      --prefix "$SPACESHIP_CHECKCHECKS_PREFIX" \
      --suffix "$SPACESHIP_CHECKCHECKS_SUFFIX" \
      --symbol "$SPACESHIP_CHECKCHECKS_FAILED_SYMBOL " \
      "$failed"
    return
  fi

  spaceship::section \
    --color "$SPACESHIP_CHECKCHECKS_SUCCESS_COLOR" \
    --prefix "$SPACESHIP_CHECKCHECKS_PREFIX" \
    --suffix "$SPACESHIP_CHECKCHECKS_SUFFIX" \
    --symbol "$SPACESHIP_CHECKCHECKS_SUCCESS_SYMBOL " \
    ""
}
