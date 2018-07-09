# Copyright dunnhumby Germany GmbH 2018.
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE.txt or copy at
# http://www.boost.org/LICENSE_1_0.txt)
#
# This Dockerfile is just for testing
FROM sociomantictsunami/dlang:v2
RUN touch /BUILT-img1-Dockerfile
COPY img1/build /BUILT-img1-Dockerfile-COPY
