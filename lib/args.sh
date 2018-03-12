# Copyright sociomantic labs GmbH 2017.
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE.txt or copy at
# http://www.boost.org/LICENSE_1_0.txt)
#
# This is a sh utility to convert CLI arguments into beaver environment
# variables. Intention is to include this script in the beginning of all command
# scripts so that common arguments get exported as environment variables and
# don't need to be passes further via CLI
#
# Use:
#
# . lib/args.sh

while getopts t:D:E: arg
do
    case "$arg" in
        t) export BEAVER_DOCKER_IMG="$OPTARG" ;;
        e) export BEAVER_DOCKER_VARS="$BEAVER_DOCKER_VARS $OPTARG" ;;
    esac
done

shift $((OPTIND-1))

# no shifting so that calling script may also parse some own options
