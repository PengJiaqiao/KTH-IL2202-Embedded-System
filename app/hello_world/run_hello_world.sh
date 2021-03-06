# File: run_hello_world.sh

# This script
#   - creates a board support package for the hardware platform
#   - compiles the application and generates an executable 
#   - downloads the hardware to the board
#   - starts a terminal window
#   - downloads the software and starts the application
# 
# Start the script with sh ./run_hello_world.sh

#!/bin/bash

APP=hello_world_small
BSP_DIR=../../bsp
BSP=mpsoc_hello_world
CORE_DIR=../../hardware/de2_nios2_mpsoc
SOPCINFO=nios2_mpsoc
SOF=de2_nios2_mpsoc
CPU=cpu_0

if [[ `md5sum $CORE_DIR/$SOPCINFO.*` == `cat $CORE_DIR/.update.md5` ]] && [[ `md5sum $(basename $0)` == `cat .run.md5` ]]; then 
	echo "SOPCINFO file was not modified during this session. Will not rebuild the bsp files."
	REMAKE_BSP=false
else
	echo "SOPCINFO file was modified. Will remake the BSP files."
	REMAKE_BSP=true
	md5sum $CORE_DIR/$SOPCINFO.* > $CORE_DIR/.update.md5
	md5sum $(basename $0) > .run.md5
fi


# Create BSP-Package
if [ ! -d $BSP_DIR/${BSP}_$i ] || [ "$REMAKE_BSP" = true ]; then
nios2-bsp hal $BSP_DIR/${BSP} $CORE_DIR/$SOPCINFO.sopcinfo \
      --set hal.make.bsp_cflags_debug -g \
      --set hal.make.bsp_cflags_optimization '-Os' \
      --set hal.enable_sopc_sysid_check true \
      --set hal.enable_reduced_device_drivers true \
      --cpu-name $CPU \
      --default_sections_mapping sram \
      --set hal.enable_small_c_library true \
      --set hal.sys_clk_timer none \
      --set hal.timestamp_timer none \
      --set hal.enable_exit false \
      --set hal.enable_c_plus_plus false \
      --set hal.enable_lightweight_device_driver_api true \
      --set hal.enable_clean_exit false \
      --set hal.max_file_descriptors 4 \
      --set hal.enable_sim_optimize false
echo " "
echo "BSP package creation finished"
echo " "
fi

# Create Application

nios2-app-generate-makefile --bsp-dir $BSP_DIR/$BSP --elf-name $APP.elf --src-dir src/ --set APP_CFLAGS_OPTIMIZATION -Os

echo "" >> log.txt
echo "[Compiling code for ${CPU}0]" > log.txt
echo "" >> log.txt

# Create ELF-file
make 3>&1 1>>log.txt 2>&1

# Download Hardware to Board

echo ""
echo "***********************************************"
echo "Download hardware to board"
echo "***********************************************"
echo ""

nios2-configure-sof $CORE_DIR/$SOF.sof

# Start Nios II Terminal

echo ""
echo "Start NiosII terminal ..."

xterm -e "nios2-terminal -i 0" &

echo ""
echo "***********************************************"
echo "Download software to board"
echo "***********************************************"
echo ""

nios2-download -g $APP.elf --cpu_name $CPU --jdi $CORE_DIR/$SOF.jdi

echo ""
echo "Statistics"
nios2-elf-size $APP.elf


echo ""
echo "Code compilation errors are logged in 'log.txt'"
