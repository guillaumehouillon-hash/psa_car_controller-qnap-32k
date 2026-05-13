#!/bin/bash
# Script de build pour psa_car_controller QNAP ARM 32K
# Nécessite : docker, docker buildx

set -e

# Version à build
VERSION="${1:-3.6.3}"
DOCKER_USER="${2:-guillaumehouillon-hash}"
IMAGE_NAME="psa_car_controller_gh"

echo "==========================================="
echo "Build psa_car_controller pour QNAP ARM 32K"
echo "Version: $VERSION"
echo "Image:   ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}"
echo "==========================================="

# Créer un builder si inexistant (requis pour multi-arch)
docker buildx inspect qnap-builder > /dev/null 2>&1 || \
    docker buildx create --name qnap-builder --use

echo ""
echo "-> Build pour linux/arm/v7 (QNAP ARM 32K)..."

# Build et chargement local
docker buildx build \
    --platform linux/arm/v7 \
    --build-arg PSACC_VERSION=${VERSION} \
    -t ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} \
    -t ${DOCKER_USER}/${IMAGE_NAME}:latest \
    --load \
    .

echo ""
echo "==========================================="
echo "Build terminé avec succès!"
echo "==========================================="
echo "Image locale:"
docker images | grep ${IMAGE_NAME}
echo ""
echo "Pour lancer en test local:"
echo "  docker-compose up -d"
echo ""
echo "Pour push vers Docker Hub:"
echo "  docker login"
echo "  docker push ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}"
echo "  docker push ${DOCKER_USER}/${IMAGE_NAME}:latest"
echo ""
echo "Pour un push multi-platform depuis buildx:"
echo "  docker buildx build --platform linux/arm/v7 \\"
echo "    -t ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} \\"
echo "    -t ${DOCKER_USER}/${IMAGE_NAME}:latest \\"
echo "    --push ."
