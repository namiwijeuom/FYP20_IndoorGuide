################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Core/Src/Math_utils/ARKFLocalization.c \
../Core/Src/Math_utils/EKFLocalization.c \
../Core/Src/Math_utils/PFLocalization.c \
../Core/Src/Math_utils/multilateration.c 

OBJS += \
./Core/Src/Math_utils/ARKFLocalization.o \
./Core/Src/Math_utils/EKFLocalization.o \
./Core/Src/Math_utils/PFLocalization.o \
./Core/Src/Math_utils/multilateration.o 

C_DEPS += \
./Core/Src/Math_utils/ARKFLocalization.d \
./Core/Src/Math_utils/EKFLocalization.d \
./Core/Src/Math_utils/PFLocalization.d \
./Core/Src/Math_utils/multilateration.d 


# Each subdirectory must supply rules for building sources it contributes
Core/Src/Math_utils/%.o Core/Src/Math_utils/%.su Core/Src/Math_utils/%.cyclo: ../Core/Src/Math_utils/%.c Core/Src/Math_utils/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=c11 -g3 -DDEBUG '-D__weak=__attribute__((weak))' '-D__packed=__attribute__((__packed__))' -DUSE_HAL_DRIVER -DSTM32WB55xx -c -I../USB_Device/App -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Drivers/dwt_uwb_driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Core/Src/Configurations" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Core/Src/shared_data" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/USB_Device/App" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Core/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Drivers/STM32WBxx_HAL_Driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Drivers/STM32WBxx_HAL_Driver/Inc/Legacy" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Middlewares/ST/STM32_USB_Device_Library/Core/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Drivers/CMSIS/Device/ST/STM32WBxx/Include" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Drivers/CMSIS/Include" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Core/Src" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV2.0/STM32_WB55RG/Drivers/dwt_uwb_driver/platform" -I../USB_Device/Target -I../Core/Inc -I../Drivers/STM32WBxx_HAL_Driver/Inc -I../Drivers/STM32WBxx_HAL_Driver/Inc/Legacy -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Drivers/CMSIS/Device/ST/STM32WBxx/Include -I../Drivers/CMSIS/Include -O0 -ffunction-sections -Wall -Wextra -pedantic -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@"  -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -mthumb -o "$@"

clean: clean-Core-2f-Src-2f-Math_utils

clean-Core-2f-Src-2f-Math_utils:
	-$(RM) ./Core/Src/Math_utils/ARKFLocalization.cyclo ./Core/Src/Math_utils/ARKFLocalization.d ./Core/Src/Math_utils/ARKFLocalization.o ./Core/Src/Math_utils/ARKFLocalization.su ./Core/Src/Math_utils/EKFLocalization.cyclo ./Core/Src/Math_utils/EKFLocalization.d ./Core/Src/Math_utils/EKFLocalization.o ./Core/Src/Math_utils/EKFLocalization.su ./Core/Src/Math_utils/PFLocalization.cyclo ./Core/Src/Math_utils/PFLocalization.d ./Core/Src/Math_utils/PFLocalization.o ./Core/Src/Math_utils/PFLocalization.su ./Core/Src/Math_utils/multilateration.cyclo ./Core/Src/Math_utils/multilateration.d ./Core/Src/Math_utils/multilateration.o ./Core/Src/Math_utils/multilateration.su

.PHONY: clean-Core-2f-Src-2f-Math_utils

