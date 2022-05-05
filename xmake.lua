-- add_rules("mode.debug", "mode.release")
add_rules("mode.debug")
set_languages("c11", "cxx11")
--   配置 vscode 的 intellisense 自动提醒等功能 xmake project -k compile_commands
--[[
配置一下arm-none-eabi的路径
gcc-arm-none-eabi
├─arm-none-eabi
│─bin
│─include
│─lib
└─share

--]]

toolchain("arm-none-eabi")
    set_kind("standalone")
    set_sdkdir("D:/software/gcc-arm-none-eabi/install")
toolchain_end()

task("flash")
    on_run(function ()
            print("**********************以下开始写入stm32*******************")
            os.exec("st-info --probe")
            --虽然16进制文件不需要指定地址，但是好像默认是需要的，不过这个地址不影响
            os.exec("st-flash write ./build/output.hex 0x0800000")
            -- os.exec("st-flash write ./build/output.bin 0x0800000")
            print("******************如果上面没有error,则写入成功********************")
        end)

target("stm32f103")
    set_kind("binary")
    set_toolchains("arm-none-eabi")
    add_files(
		"./Core/Src/*.c",
        "./startup_stm32f103xb.s",
        "./Drivers/STM32F1xx_HAL_Driver/Src/*.c"
        )
    add_includedirs(
        "./Core/Inc",
        "./Drivers/CMSIS/Include",
        "./Drivers/CMSIS/Device/ST/STM32F1xx/Include",
        "./Drivers/STM32F1xx_HAL_Driver/Inc",
        "./Drivers/STM32F1xx_HAL_Driver/Inc/Legacy"
        )
    add_defines(
        "USE_HAL_DRIVER",
        "STM32F103xB"
    )
    
    add_cflags(
        "-Og",
        "-mcpu=cortex-m3",
        "-mthumb",
        "-Wall -fdata-sections -ffunction-sections",
        "-g -gdwarf-2",{force = true}
        )

    add_asflags(
        "-Og",
        "-mcpu=cortex-m3",
        "-mthumb",
        "-x assembler-with-cpp",
        "-Wall -fdata-sections -ffunction-sections",
        "-g -gdwarf-2",{force = true}
        )

    -- https://stackoverflow.com/questions/39664071/how-to-make-printf-work-on-stm32f103
    add_ldflags(
        "-Og",
        "-mcpu=cortex-m3",
        "-L./",
        "-TSTM32F103C8Tx_FLASH.ld",
        "-Wl,--gc-sections",
        "-lc -lm -specs=nosys.specs -lnosys -lrdimon -u _printf_float",{force = true}
        )

    set_targetdir("build")
    set_filename("output.elf")

    after_build(function(target)
        print("生成 HEX 和 BIN 文件")
        os.exec("arm-none-eabi-objcopy -O ihex ./build//output.elf ./build//output.hex")
        os.exec("arm-none-eabi-objcopy -O binary ./build//output.elf ./build//output.bin")
        print("生成已完成")
        import("core.project.task")
        -- task.run("flash")
        print("********************储存空间占用情况*****************************")
        os.exec("arm-none-eabi-size -Ax ./build/output.elf")
        os.exec("arm-none-eabi-size -Bx ./build/output.elf")
        os.exec("arm-none-eabi-size -Bd ./build/output.elf")
        print("heap-堆、stck-栈、.data-已初始化的变量全局/静态变量，bss-未初始化的data、.text-代码和常量")
    end)

