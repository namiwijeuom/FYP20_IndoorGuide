################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Core/Src/Ranging/Anchor/anchor.c 

OBJS += \
./Core/Src/Ranging/Anchor/anchor.o 

C_DEPS += \
./Core/Src/Ranging/Anchor/anchor.d 


# Each subdirectory must supply rules for building sources it contributes
Core/Src/Ranging/Anchor/%.o Core/Src/Ranging/Anchor/%.su Core/Src/Ranging/Anchor/%.cyclo: ../Core/Src/Ranging/Anchor/%.c Core/Src/Ranging/Anchor/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=c11 -g3 -DDEBUG '-D__weak=__attribute__((weak))' '-D__packed=__attribute__((__packed__))' -DUSE_HAL_DRIVER -DSTM32WB55xx -c -I../USB_Device/App -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Drivers/dwt_uwb_driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Core/Src/Configurations" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Core/Src/shared_data" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/USB_Device/App" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Core/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Drivers/STM32WBxx_HAL_Driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Drivers/STM32WBxx_HAL_Driver/Inc/Legacy" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Middlewares/ST/STM32_USB_Device_Library/Core/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Drivers/CMSIS/Device/ST/STM32WBxx/Include" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Drivers/CMSIS/Include" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Core/Src" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_WB55RG/Drivers/dwt_uwb_driver/platform" -I../USB_Device/Target -I../Core/Inc -I../Drivers/STM32WBxx_HAL_Driver/Inc -I../Drivers/STM32WBxx_HAL_Driver/Inc/Legacy -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Drivers/CMSIS/Device/ST/STM32WBxx/Include -I../Drivers/CMSIS/Include -I../STM32_WPAN/App -I../Utilities/lpm/tiny_lpm -I../Middlewares/ST/STM32_WPAN -I../Middlewares/ST/STM32_WPAN/interface/patterns/ble_thread -I../Middlewares/ST/STM32_WPAN/interface/patterns/ble_thread/tl -I../Middlewares/ST/STM32_WPAN/interface/patterns/ble_thread/shci -I../Middlewares/ST/STM32_WPAN/utilities -I../Middlewares/ST/STM32_WPAN/ble/core -I../Middlewares/ST/STM32_WPAN/ble/core/auto -I../Middlewares/ST/STM32_WPAN/ble/core/template -I../Middlewares/ST/STM32_WPAN/ble/svc/Inc -I../Middlewares/ST/STM32_WPAN/ble/svc/Src -I../Utilities/sequencer -I../Middlewares/ST/STM32_WPAN/ble -O0 -ffunction-sections -Wall -Wextra -pedantic -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@"  -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -mthumb -o "$@"

clean: clean-Core-2f-Src-2f-Ranging-2f-Anchor

clean-Core-2f-Src-2f-Ranging-2f-Anchor:
	-$(RM) ./Core/Src/Ranging/Anchor/anchor.cyclo ./Core/Src/Ranging/Anchor/anchor.d ./Core/Src/Ranging/Anchor/anchor.o ./Core/Src/Ranging/Anchor/anchor.su

.PHONY: clean-Core-2f-Src-2f-Ranging-2f-Anchor

