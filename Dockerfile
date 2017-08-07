# Copyright sociomantic labs GmbH 2017.
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE.txt or copy at
# http://www.boost.org/LICENSE_1_0.txt)
#
# This Dockerfile is just for testing
FROM sociomantictsunami/dlang
ARG DMD_PKG
ENV DMD_PKG="$DMD_PKG"
RUN apt-get update && apt-get -y install $DMD_PKG
