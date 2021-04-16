#!/bin/bash
# shellcheck disable=SC2155

function hassos_pre_image() {
    local BOOT_DATA="$(path_boot_dir)"

    cp -t "${BOOT_DATA}" \
        "${BINARIES_DIR}/u-boot.bin" \
        "${BINARIES_DIR}/boot.scr"
    cp "${BINARIES_DIR}"/*.dtb "${BOOT_DATA}/"
    cp -r "${BINARIES_DIR}/rpi-firmware/"* "${BOOT_DATA}/"
    cp "${BOARD_DIR}/../boot-env.txt" "${BOOT_DATA}/config.txt"

    # EEPROM update for Raspberry Pi 4/Compute Module 4
    if grep -Eq "^BR2_PACKAGE_RPI_EEPROM=y$" "${BR2_CONFIG}"; then
        cp "${BINARIES_DIR}/rpi-eeprom/pieeprom.sig" "${BOOT_DATA}/pieeprom.sig"
        cp "${BINARIES_DIR}/rpi-eeprom/pieeprom.upd" "${BOOT_DATA}/pieeprom.upd"
    fi

    # Set cmd options
    echo "dwc_otg.lpm_enable=0 console=tty1" > "${BOOT_DATA}/cmdline.txt"

    # Enable 64bit support
    if [[ "${BOARD_ID}" =~ "64" ]]; then
        sed -i "s|#arm_64bit|arm_64bit|g" "${BOOT_DATA}/config.txt"
    fi

    # Here comes the tuning for the different CM3 boards/variants
    if [[ "${BOARD_ID}" =~ "B070WR" ]]; then

        #Copy dt-blob.bin in order to enable GPIO's during boot. This is a must!
        cp "${BOARD_DIR}/dt-blob.bin" "${BOOT_DATA}/"

        #Enable config.txt with all peripherals
        sed -i "s|#arm_64bit|arm_64bit|g" "${BOOT_DATA}/config.txt"
        sed -i "s|#hdmi_force_hotplug=1|hdmi_force_hotplug=1|g" "${BOOT_DATA}/config.txt"
        sed -i "/#hdmi_mode=1/a hdmi_group=2\nhdmi_mode=87\nhdmi_cvt 800 480 60 6 0 0 0" "${BOOT_DATA}/config.txt"
        sed -i "s|#dtparam=i2c_arm=on|dtparam=i2c_arm=on|g" "${BOOT_DATA}/config.txt"
        sed -i "/#dtparam=spi=on/a dtparam=i2c2_iknowwhatimdoing\ndtparam=uart0=on" "${BOOT_DATA}/config.txt"
        sed -i "/\/boot\/overlays\/README/a enable_uart=1\ndtoverlay=uart1,txd1_pin=32,rxd1_pin=33\ncore_freq=250\n#dtoverlay=i2c-gpio,i2c_gpio_sda=0,i2c_gpio_scl=1\ndtoverlay=pwm-2chan,pin=40,func=4,pin2=41,func2=4\ndtoverlay=i2c-rtc,ds3231" "${BOOT_DATA}/config.txt"
        sed -i "/dtparam=audio=on/a desired_osc_freq=3700000" "${BOOT_DATA}/config.txt"
        sed -i "s|#dtoverlay=vc4-fkms-v3d|dtoverlay=vc4-fkms-v3d|g" "${BOOT_DATA}/config.txt"

        echo "i2c_dev" > "${TARGET_DIR}/etc/modules-load.d/modules.conf"

        # Add serial console in cmd options
        sed -i "s|$| console=serial0,115200|g" "${BOOT_DATA}/cmdline.txt"

        # Add verbose output during early boot
        sed -i -e "s/BOOT_UART=0/BOOT_UART=1/" "${BOOT_DATA}/bootcode.bin"

    fi
}


function hassos_post_image() {
    convert_disk_image_xz
}

