FROM python:3.12-slim-bookworm AS stage-1
ARG TARGETARCH

ARG HUGGINGFACE_MODEL=fish-speech-1.4
ARG HF_ENDPOINT=https://huggingface.co

WORKDIR /opt/fish-speech

# Clone the fish-speech repository
RUN set -ex \
    && apt-get update \
    && apt-get -y install --no-install-recommends git \
    && git clone https://github.com/procrastinando/fish-speech-srt-to-audio.git . \
    && apt-get -y purge git \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/*

# Download Hugging Face model
RUN set -ex \
    && pip install huggingface_hub \
    && HF_ENDPOINT=${HF_ENDPOINT} huggingface-cli download --resume-download fishaudio/${HUGGINGFACE_MODEL} --local-dir checkpoints/${HUGGINGFACE_MODEL}

FROM python:3.12-slim-bookworm
ARG TARGETARCH

ARG DEPENDENCIES="  \
    ca-certificates \
    libsox-dev \
    build-essential \
    cmake \
    libasound-dev \
    portaudio19-dev \
    libportaudio2 \
    libportaudiocpp0 \
    ffmpeg"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -ex \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache \
    && apt-get update \
    && apt-get -y install --no-install-recommends ${DEPENDENCIES} \
    && echo "no" | dpkg-reconfigure dash

WORKDIR /opt/fish-speech

# Copy the repository from stage-1
COPY --from=stage-1 /opt/fish-speech /opt/fish-speech

# Install Python dependencies
RUN --mount=type=cache,target=/root/.cache,sharing=locked \
    set -ex \
    && pip install -e .[stable]

ENV GRADIO_SERVER_NAME="0.0.0.0"

EXPOSE 7860

CMD ["./entrypoint.sh"]
