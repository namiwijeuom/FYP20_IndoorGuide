################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Core/Src/ds_twr_initiator.c \
../Core/Src/ds_twr_responder.c \
../Core/Src/main.c \
../Core/Src/simple_rx.c \
../Core/Src/simple_tx.c \
../Core/Src/ss_twr_initiator.c \
../Core/Src/ss_twr_responder.c \
../Core/Src/stm32f4xx_hal_msp.c \
../Core/Src/stm32f4xx_it.c \
../Core/Src/syscalls.c \
../Core/Src/sysmem.c \
../Core/Src/system_stm32f4xx.c 

OBJS += \
./Core/Src/ds_twr_initiator.o \
./Core/Src/ds_twr_responder.o \
./Core/Src/main.o \
./Core/Src/simple_rx.o \
./Core/Src/simple_tx.o \
./Core/Src/ss_twr_initiator.o \
./Core/Src/ss_twr_responder.o \
./Core/Src/stm32f4xx_hal_msp.o \
./Core/Src/stm32f4xx_it.o \
./Core/Src/syscalls.o \
./Core/Src/sysmem.o \
./Core/Src/system_stm32f4xx.o 

C_DEPS += \
./Core/Src/ds_twr_initiator.d \
./Core/Src/ds_twr_responder.d \
./Core/Src/main.d \
./Core/Src/simple_rx.d \
./Core/Src/simple_tx.d \
./Core/Src/ss_twr_initiator.d \
./Core/Src/ss_twr_responder.d \
./Core/Src/stm32f4xx_hal_msp.d \
./Core/Src/stm32f4xx_it.d \
./Core/Src/syscalls.d \
./Core/Src/sysmem.d \
./Core/Src/system_stm32f4xx.d 


# Each subdirectory must supply rules for building sources it contributes
Core/Src/%.o Core/Src/%.su Core/Src/%.cyclo: ../Core/Src/%.c Core/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=c11 -g3 -DDEBUG '-D__weak=__attribute__((weak))' '-D__packed=__attribute__((__packed__))' -DUSE_HAL_DRIVER -DSTM32F446xx -c -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Drivers/dwt_uwb_driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Core/Src/Configurations" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Core/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Core/Src" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Core/Src/shared_data" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Drivers/STM32F4xx_HAL_Driver/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Drivers/STM32F4xx_HAL_Driver/Inc/Legacy" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Drivers/CMSIS/Device/ST/STM32F4xx/Include" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Drivers/CMSIS/Include" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/USB_DEVICE/App" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/USB_DEVICE/Target" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Middlewares/ST/STM32_USB_Device_Library/Core/Inc" -I"D:/Final_Year_Project_(FYP)/FYP20_IndoorGuide/indoorguide-dwm3000-firmwareV1.0/STM_Nucleo_F446/Drivers/dwt_uwb_driver/platform" -I../Core/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/CMSIS/Include -I../USB_DEVICE/App -I../USB_DEVICE/Target -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -O0 -ffunction-sections -Wall -Wextra -pedantic -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@"  -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -mthumb -o "$@"

clean: clean-Core-2f-Src

clean-Core-2f-Src:
	-$(RM) ./Core/Src/ds_twr_initiator.cyclo ./Core/Src/ds_twr_initiator.d ./Core/Src/ds_twr_initiator.o ./Core/Src/ds_twr_initiator.su ./Core/Src/ds_twr_responder.cyclo ./Core/Src/ds_twr_responder.d ./Core/Src/ds_twr_responder.o ./Core/Src/ds_twr_responder.su ./Core/Src/main.cyclo ./Core/Src/main.d ./Core/Src/main.o ./Core/Src/main.su ./Core/Src/simple_rx.cyclo ./Core/Src/simple_rx.d ./Core/Src/simple_rx.o ./Core/Src/simple_rx.su ./Core/Src/simple_tx.cyclo ./Core/Src/simple_tx.d ./Core/Src/simple_tx.o ./Core/Src/simple_tx.su ./Core/Src/ss_twr_initiator.cyclo ./Core/Src/ss_twr_initiator.d ./Core/Src/ss_twr_initiator.o ./Core/Src/ss_twr_initiator.su ./Core/Src/ss_twr_responder.cyclo ./Core/Src/ss_twr_responder.d ./Core/Src/ss_twr_responder.o ./Core/Src/ss_twr_responder.su ./Core/Src/stm32f4xx_hal_msp.cyclo ./Core/Src/stm32f4xx_hal_msp.d ./Core/Src/stm32f4xx_hal_msp.o ./Core/Src/stm32f4xx_hal_msp.su ./Core/Src/stm32f4xx_it.cyclo ./Core/Src/stm32f4xx_it.d ./Core/Src/stm32f4xx_it.o ./Core/Src/stm32f4xx_it.su ./Core/Src/syscalls.cyclo ./Core/Src/syscalls.d ./Core/Src/syscalls.o ./Core/Src/syscalls.su ./Core/Src/sysmem.cyclo ./Core/Src/sysmem.d ./Core/Src/sysmem.o ./Core/Src/sysmem.su ./Core/Src/system_stm32f4xx.cyclo ./Core/Src/system_stm32f4xx.d ./Core/Src/system_stm32f4xx.o ./Core/Src/system_stm32f4xx.su

.PHONY: clean-Core-2f-Src

