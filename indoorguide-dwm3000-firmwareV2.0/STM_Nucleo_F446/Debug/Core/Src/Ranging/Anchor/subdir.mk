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
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=c11 -g3 -DDEBUG '-D__weak=__attribute__((weak))' '-D__packed=__attribute__((__packed__))' -DUSE_HAL_DRIVER -DSTM32F446xx -c -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Drivers/dwt_uwb_driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Core/Src/Configurations" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Core/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Core/Src" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Core/Src/shared_data" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Drivers/STM32F4xx_HAL_Driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Drivers/STM32F4xx_HAL_Driver/Inc/Legacy" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Drivers/CMSIS/Device/ST/STM32F4xx/Include" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Drivers/CMSIS/Include" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/USB_DEVICE/App" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/USB_DEVICE/Target" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Middlewares/ST/STM32_USB_Device_Library/Core/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Drivers/dwt_uwb_driver/platform" -I../Core/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -I../USB_DEVICE/App -I../USB_DEVICE/Target -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -O0 -ffunction-sections -Wall -Wextra -pedantic -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@"  -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -mthumb -o "$@"

clean: clean-Core-2f-Src-2f-Ranging-2f-Anchor

clean-Core-2f-Src-2f-Ranging-2f-Anchor:
	-$(RM) ./Core/Src/Ranging/Anchor/anchor.cyclo ./Core/Src/Ranging/Anchor/anchor.d ./Core/Src/Ranging/Anchor/anchor.o ./Core/Src/Ranging/Anchor/anchor.su

.PHONY: clean-Core-2f-Src-2f-Ranging-2f-Anchor

