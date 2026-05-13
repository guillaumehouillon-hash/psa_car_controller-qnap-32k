# ============================================================
# Stage 1 : build de psa-car-controller sur Alpine 3.17 ARMv7
# ============================================================
FROM --platform=linux/arm/v7 alpine:3.17 AS builder

# Pour QNAP 32K, on reste en musl/Alpine 3.17 (testé OK sur TS-231P3) [web:115]
ENV PSACC_VERSION=${PSACC_VERSION:-3.6.3}
ENV PYTHONUNBUFFERED=1

RUN apk add --no-cache \
      python3 \
      python3-dev \
      py3-pip \
      build-base \
      linux-headers \
      git \
      openssl-dev \
      libffi-dev \
      musl-dev

# Upgrade pip + wheel
RUN python3 -m pip install --no-cache-dir --upgrade pip wheel setuptools

# Installation de psa-car-controller depuis PyPI
# (on laisse pip décider des wheels / builds adaptés à Alpine/musl) [web:43][web:26]
RUN python3 -m pip install --no-cache-dir \
      "psa-car-controller==${PSACC_VERSION}"

# ============================================================
# Stage 2 : image finale runtime Alpine 3.17 ARMv7
# ============================================================
FROM --platform=linux/arm/v7 alpine:3.17

ENV PSACC_VERSION=${PSACC_VERSION:-3.6.3}
ENV PYTHONUNBUFFERED=1

# Runtime minimal
RUN apk add --no-cache \
      python3 \
      py3-pip \
      tzdata \
      ca-certificates

# Copie de l’environnement Python construit dans le stage builder
COPY --from=builder /usr/lib/python3.10 /usr/lib/python3.10
COPY --from=builder /usr/bin/psa-car-controller /usr/bin/psa-car-controller
COPY --from=builder /usr/bin/python3 /usr/bin/python3
COPY --from=builder /usr/bin/pip3 /usr/bin/pip3

# Copie du script d’init
COPY init.sh /init.sh
RUN sed -i 's/\r$//' /init.sh && chmod +x /init.sh

WORKDIR /config

EXPOSE 5000

# Variables par défaut (surchageables via docker-compose) [web:26]
ENV PSACC_PORT=5000 \
    PSACC_BASE_PATH=/ \
    PSACC_OPTIONS="-c -r --web-conf" \
    PSACC_CONFIG_DIR=/config \
    MALLOC_CHECK_=0

ENTRYPOINT ["/init.sh"]
