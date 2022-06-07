FROM ubuntu:latest

RUN apt-get update

# Install Python, curl.
RUN apt-get -y install python3-dev curl build-essential

# Install Rust.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain none
RUN . $HOME/.cargo/env && rustup default nightly

# Build.
# Mount /giza and /winterfell.
# ADD ./giza /app/giza
# ADD ./winterfell /app/winterfell

# RUN cargo +nightly build