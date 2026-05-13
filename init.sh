#!/bin/sh
# Init script pour psa_car_controller - version QNAP ARM 32K

echo "psa_car_controller (QNAP ARM 32K) : loading..."
echo "MALLOC_CHECK_=$MALLOC_CHECK_"
echo "PSACC_CONFIG_DIR=$PSACC_CONFIG_DIR"

cd "$PSACC_CONFIG_DIR"

ARGS="-p $PSACC_PORT -l 0.0.0.0 -b $PSACC_BASE_PATH $PSACC_OPTIONS"
exec psa-car-controller $ARGS
