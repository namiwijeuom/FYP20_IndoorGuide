################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Drivers/dwt_uwb_driver/platform/deca_mutex.c \
../Drivers/dwt_uwb_driver/platform/deca_probe_interface.c \
../Drivers/dwt_uwb_driver/platform/deca_sleep.c \
../Drivers/dwt_uwb_driver/platform/deca_spi.c \
../Drivers/dwt_uwb_driver/platform/port.c 

OBJS += \
./Drivers/dwt_uwb_driver/platform/deca_mutex.o \
./Drivers/dwt_uwb_driver/platform/deca_probe_interface.o \
./Drivers/dwt_uwb_driver/platform/deca_sleep.o \
./Drivers/dwt_uwb_driver/platform/deca_spi.o \
./Drivers/dwt_uwb_driver/platform/port.o 

C_DEPS += \
./Drivers/dwt_uwb_driver/platform/deca_mutex.d \
./Drivers/dwt_uwb_driver/platform/deca_probe_interface.d \
./Drivers/dwt_uwb_driver/platform/deca_sleep.d \
./Drivers/dwt_uwb_driver/platform/deca_spi.d \
./Drivers/dwt_uwb_driver/platform/port.d 


# Each subdirectory must supply rules for building sources it contributes
Drivers/dwt_uwb_driver/platform/%.o Drivers/dwt_uwb_driver/platform/%.su Drivers/dwt_uwb_driver/platform/%.cyclo: ../Drivers/dwt_uwb_driver/platform/%.c Drivers/dwt_uwb_driver/platform/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=c11 -g3 -DDEBUG '-D__weak=__attribute__((weak))' '-D__packed=__attribute__((__packed__))' -DUSE_HAL_DRIVER -DSTM32WB55xx -c -I../USB_Device/App -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Drivers/dwt_uwb_driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Core/Src/Configurations" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Core/Src/shared_data" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/USB_Device/App" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Core/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Drivers/STM32WBxx_HAL_Driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Drivers/STM32WBxx_HAL_Driver/Inc/Legacy" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Middlewares/ST/STM32_USB_Device_Library/Core/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Drivers/CMSIS/Device/ST/STM32WBxx/Include" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Drivers/CMSIS/Include" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Core/Src" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Drivers/dwt_uwb_driver/platform" -I../USB_Device/Target -I../Core/Inc -I../Drivers/STM32WBxx_HAL_Driver/Inc -I../Drivers/STM32WBxx_HAL_Driver/Inc/Legacy -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Drivers/CMSIS/Device/ST/STM32WBxx/Include -I../Drivers/CMSIS/Include -I../STM32_WPAN/App -I../Utilities/lpm/tiny_lpm -I../Middlewares/ST/STM32_WPAN -I../Middlewares/ST/STM32_WPAN/interface/patterns/ble_thread -I../Middlewares/ST/STM32_WPAN/interface/patterns/ble_thread/tl -I../Middlewares/ST/STM32_WPAN/interface/patterns/ble_thread/shci -I../Middlewares/ST/STM32_WPAN/utilities -I../Middlewares/ST/STM32_WPAN/ble/core -I../Middlewares/ST/STM32_WPAN/ble/core/auto -I../Middlewares/ST/STM32_WPAN/ble/core/template -I../Middlewares/ST/STM32_WPAN/ble/svc/Inc -I../Middlewares/ST/STM32_WPAN/ble/svc/Src -I../Utilities/sequencer -I../Middlewares/ST/STM32_WPAN/ble -O0 -ffunction-sections -Wall -Wextra -pedantic -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@"  -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -mthumb -o "$@"

clean: clean-Drivers-2f-dwt_uwb_driver-2f-platform

clean-Drivers-2f-dwt_uwb_driver-2f-platform:
	-$(RM) ./Drivers/dwt_uwb_driver/platform/deca_mutex.cyclo ./Drivers/dwt_uwb_driver/platform/deca_mutex.d ./Drivers/dwt_uwb_driver/platform/deca_mutex.o ./Drivers/dwt_uwb_driver/platform/deca_mutex.su ./Drivers/dwt_uwb_driver/platform/deca_probe_interface.cyclo ./Drivers/dwt_uwb_driver/platform/deca_probe_interface.d ./Drivers/dwt_uwb_driver/platform/deca_probe_interface.o ./Drivers/dwt_uwb_driver/platform/deca_probe_interface.su ./Drivers/dwt_uwb_driver/platform/deca_sleep.cyclo ./Drivers/dwt_uwb_driver/platform/deca_sleep.d ./Drivers/dwt_uwb_driver/platform/deca_sleep.o ./Drivers/dwt_uwb_driver/platform/deca_sleep.su ./Drivers/dwt_uwb_driver/platform/deca_spi.cyclo ./Drivers/dwt_uwb_driver/platform/deca_spi.d ./Drivers/dwt_uwb_driver/platform/deca_spi.o ./Drivers/dwt_uwb_driver/platform/deca_spi.su ./Drivers/dwt_uwb_driver/platform/port.cyclo ./Drivers/dwt_uwb_driver/platform/port.d ./Drivers/dwt_uwb_driver/platform/port.o ./Drivers/dwt_uwb_driver/platform/port.su

.PHONY: clean-Drivers-2f-dwt_uwb_driver-2f-platform

