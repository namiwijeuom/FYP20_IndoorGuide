################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../USB_Device/App/usb_device.c \
../USB_Device/App/usbd_cdc_if.c \
../USB_Device/App/usbd_desc.c 

OBJS += \
./USB_Device/App/usb_device.o \
./USB_Device/App/usbd_cdc_if.o \
./USB_Device/App/usbd_desc.o 

C_DEPS += \
./USB_Device/App/usb_device.d \
./USB_Device/App/usbd_cdc_if.d \
./USB_Device/App/usbd_desc.d 


# Each subdirectory must supply rules for building sources it contributes
USB_Device/App/%.o USB_Device/App/%.su USB_Device/App/%.cyclo: ../USB_Device/App/%.c USB_Device/App/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=c11 -g3 -DDEBUG '-D__weak=__attribute__((weak))' '-D__packed=__attribute__((__packed__))' -DUSE_HAL_DRIVER -DSTM32WB55xx -c -I../USB_Device/App -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Drivers/dwt_uwb_driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Core/Src/Configurations" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Core/Src/shared_data" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/USB_Device/App" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Core/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Drivers/STM32WBxx_HAL_Driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Drivers/STM32WBxx_HAL_Driver/Inc/Legacy" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Middlewares/ST/STM32_USB_Device_Library/Core/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Drivers/CMSIS/Device/ST/STM32WBxx/Include" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Drivers/CMSIS/Include" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Core/Src" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Drivers/dwt_uwb_driver/platform" -I../USB_Device/Target -I../Core/Inc -I../Drivers/STM32WBxx_HAL_Driver/Inc -I../Drivers/STM32WBxx_HAL_Driver/Inc/Legacy -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Drivers/CMSIS/Device/ST/STM32WBxx/Include -I../Drivers/CMSIS/Include -O0 -ffunction-sections -Wall -Wextra -pedantic -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@"  -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -mthumb -o "$@"

clean: clean-USB_Device-2f-App

clean-USB_Device-2f-App:
	-$(RM) ./USB_Device/App/usb_device.cyclo ./USB_Device/App/usb_device.d ./USB_Device/App/usb_device.o ./USB_Device/App/usb_device.su ./USB_Device/App/usbd_cdc_if.cyclo ./USB_Device/App/usbd_cdc_if.d ./USB_Device/App/usbd_cdc_if.o ./USB_Device/App/usbd_cdc_if.su ./USB_Device/App/usbd_desc.cyclo ./USB_Device/App/usbd_desc.d ./USB_Device/App/usbd_desc.o ./USB_Device/App/usbd_desc.su

.PHONY: clean-USB_Device-2f-App

