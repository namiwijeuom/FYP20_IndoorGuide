################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include USB_DEVICE/Target/subdir.mk
-include USB_DEVICE/App/subdir.mk
-include Middlewares/ST/STM32_USB_Device_Library/Core/Src/subdir.mk
-include Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Src/subdir.mk
-include Drivers/dwt_uwb_driver/platform/subdir.mk
-include Drivers/STM32F3xx_HAL_Driver/Src/subdir.mk
-include Core/Startup/subdir.mk
-include Core/Src/shared_data/subdir.mk
-include Core/Src/UWB_tasks/ss_twr_resp/subdir.mk
-include Core/Src/UWB_tasks/ss_twr_init/subdir.mk
-include Core/Src/UWB_tasks/Listener/subdir.mk
-include Core/Src/UWB_tasks/Blink/subdir.mk
-include Core/Src/Math_utils/subdir.mk
-include Core/Src/Configurations/subdir.mk
-include Core/Src/Applications/Tag_app/subdir.mk
-include Core/Src/Applications/Anchor_app/subdir.mk
-include Core/Src/subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(S_DEPS)),)
-include $(S_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

OPTIONAL_TOOL_DEPS := \
$(wildcard ../makefile.defs) \
$(wildcard ../makefile.init) \
$(wildcard ../makefile.targets) \


BUILD_ARTIFACT_NAME := STM32_DISCOVERY_F303
BUILD_ARTIFACT_EXTENSION := elf
BUILD_ARTIFACT_PREFIX :=
BUILD_ARTIFACT := $(BUILD_ARTIFACT_PREFIX)$(BUILD_ARTIFACT_NAME)$(if $(BUILD_ARTIFACT_EXTENSION),.$(BUILD_ARTIFACT_EXTENSION),)

# Add inputs and outputs from these tool invocations to the build variables 
EXECUTABLES += \
STM32_DISCOVERY_F303.elf \

MAP_FILES += \
STM32_DISCOVERY_F303.map \

SIZE_OUTPUT += \
default.size.stdout \

OBJDUMP_LIST += \
STM32_DISCOVERY_F303.list \


# All Target
all: main-build

# Main-build Target
main-build: STM32_DISCOVERY_F303.elf secondary-outputs

# Tool invocations
STM32_DISCOVERY_F303.elf STM32_DISCOVERY_F303.map: $(OBJS) $(USER_OBJS) D:\Final_Year_Project_(FYP)\FYP20_IndoorGuide\indoorguide-dwm3000-firmwareV2.0\STM32_DISCOVERY_F303\STM32F303VCTX_FLASH.ld makefile objects.list $(OPTIONAL_TOOL_DEPS)
	arm-none-eabi-gcc -o "STM32_DISCOVERY_F303.elf" @"objects.list" $(USER_OBJS) $(LIBS) -mcpu=cortex-m4 -T"D:\Final_Year_Project_(FYP)\FYP20_IndoorGuide\indoorguide-dwm3000-firmwareV2.0\STM32_DISCOVERY_F303\STM32F303VCTX_FLASH.ld" -Wl,-Map="STM32_DISCOVERY_F303.map" -Wl,--gc-sections -static -L"D:\Final_Year_Project_(FYP)\FYP20_IndoorGuide\indoorguide-dwm3000-firmwareV2.0\STM32_DISCOVERY_F303\Drivers\dwt_uwb_driver\lib" -Wl,--whole-archive -ldwt_uwb_driver-m4-sfp-6.0.7 -Wl,--no-whole-archive  -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -mthumb -Wl,--start-group -lc -lm -Wl,--end-group
	@echo 'Finished building target: $@'
	@echo ' '

default.size.stdout: $(EXECUTABLES) makefile objects.list $(OPTIONAL_TOOL_DEPS)
	arm-none-eabi-size  $(EXECUTABLES)
	@echo 'Finished building: $@'
	@echo ' '

STM32_DISCOVERY_F303.list: $(EXECUTABLES) makefile objects.list $(OPTIONAL_TOOL_DEPS)
	arm-none-eabi-objdump -h -S $(EXECUTABLES) > "STM32_DISCOVERY_F303.list"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) STM32_DISCOVERY_F303.elf STM32_DISCOVERY_F303.list STM32_DISCOVERY_F303.map default.size.stdout
	-@echo ' '

secondary-outputs: $(SIZE_OUTPUT) $(OBJDUMP_LIST)

fail-specified-linker-script-missing:
	@echo 'Error: Cannot find the specified linker script. Check the linker settings in the build configuration.'
	@exit 2

warn-no-linker-script-specified:
	@echo 'Warning: No linker script specified. Check the linker settings in the build configuration.'

.PHONY: all clean dependents main-build fail-specified-linker-script-missing warn-no-linker-script-specified

-include ../makefile.targets
