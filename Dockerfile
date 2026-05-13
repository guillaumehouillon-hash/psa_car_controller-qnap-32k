# psa_car_controller pour QNAP ARM 32K (ARMv7)
# Basé sur flobz/psa_car_controller master avec correctif page-size 32K
# Correctif clé : LDFLAGS=-Wl,-z,max-page-size=32768 + recompile from source

ARG PSACC_VERSION="3.6.3"
ARG DEBIAN_FRONTEND=noninteractive

# ============================================================================
# STAGE 1 : Builder - Compilation avec LDFLAGS 32K page-size
# ============================================================================
FROM --platform=linux/arm/v7 debian:bookworm-slim AS builder

ARG PSACC_VERSION

# CRITICAL : LDFLAGS pour forcer une page-size ELF de 32K
# C'est LE correctif clé pour QNAP ARM 32KB pagesize (segmentation fault fix)
ENV LDFLAGS="-Wl,-z,max-page-size=32768"

ARG PYTHON_DEP='python3 python3-wheel python3-typing-extensions python3-pandas python3-six python3-dateutil python3-brotli python3-pycryptodome libatlas3-base python3-cryptography python3-scipy androguard python3-flask python3-paho-mqtt python3-ruamel.yaml ca-certificates python3-numpy'

# Installation build-essentials et dépendances
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python3-pip \
    python3-setuptools \
    python3-dev \
    libblas-dev \
    liblapack-dev \
    gfortran \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    make \
    automake \
    gcc \
    g++ \
    subversion \
    ninja-build \
    $PYTHON_DEP && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip/wheel/setuptools
RUN pip3 install --break-system-packages --upgrade pip wheel setuptools

# Installation depuis PyPI en recompilant from source (LDFLAGS actif)
# --no-binary :all: force la recompilation des extensions C natives (numpy, scipy, pandas...)
RUN pip3 install --break-system-packages --no-cache-dir --no-binary :all: psa-car-controller==${PSACC_VERSION}

EXPOSE 5000
# ============================================================================
# STAGE 2 : Image finale minimale
# ============================================================================
FROM --platform=linux/arm/v7 debian:bookworm-slim

ARG PYTHON_DEP='python3 python3-wheel python3-typing-extensions python3-pandas python3-six python3-dateutil python3-brotli python3-pycryptodome libatlas3-base python3-cryptography python3-scipy androguard python3-flask python3-paho-mqtt python3-ruamel.yaml ca-certificates python3-numpy'

WORKDIR /config

ENV PSACC_BASE_PATH=/ \
    PSACC_PORT=5000 \
    PSACC_OPTIONS="-c -r --web-conf" \
    PSACC_CONFIG_DIR="/config" \
    PYTHONPATH="/app" \
    # Desactive jemalloc qui cause des segfault sur 32K
    MALLOC_CHECK_=0

# Copier depuis le builder les libs installées
COPY --from=builder /var/lib/apt /var/lib/apt
COPY --from=builder /var/cache/apt/ /var/cache/apt/
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# Installer les dépendances runtime
RUN apt-get update && \
    apt-get install -y --no-install-recommends $PYTHON_DEP curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Script init
COPY init.sh /init.sh
RUN chmod +x /init.sh

CMD ["/init.sh"]
