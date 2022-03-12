#!/usr/bin/env bash
################################################################################

# Disable alias expansions for function definitions when in source-mode
# aliases will still be resolved, though. Could maybe inject a debug hook.
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && shopt -u expand_aliases

main() {
    # parseargs -- if we want to add cmd-global opts, do it here
    # ... if you parse args in a fxn, then you'll have to predeclare
    # ... an array var and access that, instead of $@.
    processSubCommands "$@"
}
processSubCommands() {
    subcmd="$1"
    case "$subcmd" in
        install)
            die "ERROR: CASE ($subcmd) NOT YET IMPLEMENTED"
            bucketname=${2?need bucketname}
            ensure-current-dir-is-dotgit
            create-bucket-if-it-does-not-already-exist $bucketname
            git config filter.sync-s3.clean "git-sync-s3 clean $bucketname -- %f"
            git config filter.sync-s3.smudge "git sync-s3 smudge $bucketname -- %f"
            git config filter.sync-s3.required true
            git config git-sync-s3.bucketname $bucketname
            # git config git-sync-s3.accountid $something
        ;;
        uninstall)
            die "ERROR: CASE ($subcmd) NOT YET IMPLEMENTED"
            remove-filter-lines
        ;;
        track)
            die >&2 "ERROR: CASE ($subcmd) NOT YET IMPLEMENTED"
        ;;
        smudge)
            die "ERROR: CASE ($subcmd) NOT YET IMPLEMENTED"
            suck-up-stdin-and-parse-s3id-and-download
        ;;
        clean)
            die "ERROR: CASE ($subcmd) NOT YET IMPLEMENTED"
            suck-up-stdin-as-file-and-calc-hash-and-upload-to-s3
        ;;
        help)
            show_help
            exit 0
        ;;
        ls)
            ls-files
        ;;
        *)
            die "unknown subcmd: $subcmd"
            show_usage
        ;;
    esac
}

printred() {
    c_red="\x1b[38;5;1m"
    nc="\033[0m"
    printf "${c_red}%s${nc}\n" "$*" >&2
}

die() {
    printred "$@" >&2
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        exit ${1-1}
    else
        return ${1-1}
    fi
}

# If executed as a script, instead of sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
    main "$@"
else
    echo "${BASH_SOURCE[0]}" sourced >&2
  shopt -s expand_aliases # reset from source-harnessing
fi

