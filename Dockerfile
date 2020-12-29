# You can override this `--build-arg BASE_IMAGE=...` to use different
# version of Rust or OpenSSL.
ARG BASE_IMAGE=ekidd/rust-musl-builder:latest

# ------------------------------------------------------------------------------
# Build Queuey
# ------------------------------------------------------------------------------

FROM ${BASE_IMAGE} AS builder-queuey

ADD --chown=rust:rust . ./

RUN cd queuey && cargo build --release

# ------------------------------------------------------------------------------
# Build Worky
# ------------------------------------------------------------------------------

FROM ${BASE_IMAGE} AS builder-worky

ADD --chown=rust:rust . ./

RUN cd worky && cargo build --release
# ------------------------------------------------------------------------------
# Final Stage
# ------------------------------------------------------------------------------

FROM alpine:latest AS first-binary

RUN apk --no-cache add ca-certificates

# TODO fix these user perms
RUN adduser -D donovand && addgroup donovand donovand
USER donovand

COPY --from=builder-queuey \
    /home/rust/src/queuey/target/x86_64-unknown-linux-musl/release/queuey \
    /usr/local/bin/

COPY --from=builder-worky \
    /home/rust/src/worky/target/x86_64-unknown-linux-musl/release/worky \
    /usr/local/bin/

# TODO determine from environment
# Default to worky for now
CMD /usr/local/bin/worky