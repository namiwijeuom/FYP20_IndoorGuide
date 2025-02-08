################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Core/Src/Applications/Tag_app/tag_app.c 

OBJS += \
./Core/Src/Applications/Tag_app/tag_app.o 

C_DEPS += \
./Core/Src/Applications/Tag_app/tag_app.d 


# Each subdirectory must supply rules for building sources it contributes
Core/Src/Applications/Tag_app/%.o Core/Src/Applications/Tag_app/%.su Core/Src/Applications/Tag_app/%.cyclo: ../Core/Src/Applications/Tag_app/%.c Core/Src/Applications/Tag_app/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=c11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32F303xC -c -I../USB_DEVICE/App -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_DISCOVERY_F303/Core/Src/Configurations" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_DISCOVERY_F303/Core/Src" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_DISCOVERY_F303/Drivers/dwt_uwb_driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_DISCOVERY_F303/Drivers/dwt_uwb_driver/platform" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM32_DISCOVERY_F303/Core/Src/shared_data" -I../USB_DEVICE/Target -I../Core/Inc -I../Drivers/STM32F3xx_HAL_Driver/Inc -I../Drivers/STM32F3xx_HAL_Driver/Inc/Legacy -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Drivers/CMSIS/Device/ST/STM32F3xx/Include -I../Drivers/CMSIS/Include -O0 -ffunction-sections -Wall -Wextra -pedantic -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@"  -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -mthumb -o "$@"

clean: clean-Core-2f-Src-2f-Applications-2f-Tag_app

clean-Core-2f-Src-2f-Applications-2f-Tag_app:
	-$(RM) ./Core/Src/Applications/Tag_app/tag_app.cyclo ./Core/Src/Applications/Tag_app/tag_app.d ./Core/Src/Applications/Tag_app/tag_app.o ./Core/Src/Applications/Tag_app/tag_app.su

.PHONY: clean-Core-2f-Src-2f-Applications-2f-Tag_app

