FROM debian:jessie-backports
MAINTAINER Tim Cooper <tim.cooper@everydayhero.com>

ENV PATH=$PATH:/buildkite/bin \
    BUILDKITE_BOOTSTRAP_SCRIPT_PATH=/buildkite/bootstrap.sh \
    BUILDKITE_BUILD_PATH=/buildkite/builds \
    BUILDKITE_HOOKS_PATH=/buildkite/hooks

ADD ./plain /var/plain
ADD ./plain-gun /usr/local/bin/
ADD ./build /build
RUN /build/build.sh

ENTRYPOINT ["buildkite-agent"]
CMD ["start"]
