@echo off
:: 设置窗口标题
TITLE LA32R CPU Simulation Automation

:: ============================================================================
:: LA32R 单周期 CPU 自动化仿真脚本 (适配Vivado项目结构)
::
:: 功能:
:: 1. 自动定义项目相关的文件和目录路径。
:: 2. 切换到正确的仿真工作目录 (%PROJECT_ROOT%Hardware\LA32R.sim\sim_1\behav\xsim)。
:: 3. 清理上一次仿真生成的临时文件和目录。
:: 4. 调用Python汇编器 (assembler.py) 将 "program.asm" 编译为 "program.hex" 机器码文件。
::    (通过pushd/popd确保Python脚本在正确的Software目录下执行)
:: 5. 创建Verilog源文件列表 (verilog_files.f)。
:: 6. 调用Vivado的xvlog进行Verilog代码编译。
:: 7. 调用Vivado的xelab进行设计阐述和仿真快照构建。
:: 8. 调用Vivado的xsim运行仿真并执行到脚本结束或指定时间。
::
:: 使用方法:
:: - 将此脚本 (run.bat) 放置在项目的根目录下 (与Hardware和Software文件夹同级)。
:: - 确保系统中已安装Python，并且可以从命令行调用。
:: - 确保 Vivado (例如 Vivado 2018.1) 的 `bin` 目录已添加到系统的 PATH 环境变量中，
::   以便脚本可以找到 `xvlog`, `xelab`, `xsim` 等命令。
:: - 直接双击运行此脚本，或在命令行中导航到项目根目录并执行 `run.bat`。
:: ============================================================================

:: --- 步骤 0: 定义项目路径 ---
:: %~dp0 会自动获取当前脚本所在的目录路径，并将其设置为项目根目录
set "PROJECT_ROOT=%~dp0"
set "SOFTWARE_DIR=%PROJECT_ROOT%Software"
set "DESIGN_SRC_DIR=%PROJECT_ROOT%Hardware\LA32R.srcs\sources_1\new"
set "SIM_SRC_DIR=%PROJECT_ROOT%Hardware\LA32R.srcs\sim_1\new"
:: Vivado仿真运行的典型目录结构
set "SIM_RUN_DIR=%PROJECT_ROOT%Hardware\LA32R.sim\sim_1\behav\xsim"

echo 项目根目录: %PROJECT_ROOT%
echo 仿真运行目录: %SIM_RUN_DIR%
echo.

:: --- 准备工作：切换到仿真运行目录 ---
:: 如果仿真运行目录不存在，则创建它，然后切换到该目录
if not exist "%SIM_RUN_DIR%" ( mkdir "%SIM_RUN_DIR%" )
cd /d "%SIM_RUN_DIR%"

:: --- 步骤 1: 清理旧的仿真文件 ---
echo [步骤 1] 清理旧的仿真文件...
if exist xsim.dir ( rd /s /q xsim.dir )
if exist *.log ( del *.log )
if exist *.jou ( del *.jou )
if exist verilog_files.f ( del verilog_files.f )
if exist webtalk*.xml ( del webtalk*.xml )
if exist webtalk*.tcl ( del webtalk*.tcl )
echo 清理完成。
echo.

:: --- 步骤 2: 运行Python汇编器生成机器码 ---
echo [步骤 2] 汇编测试程序 (assembler.py)...
:: 使用 pushd/popd 命令临时切换到Software目录执行Python脚本,
:: 以确保脚本内部的相对路径 (如 "program.asm") 能正确解析, 然后自动切回当前目录。
pushd "%SOFTWARE_DIR%"
python assembler.py
popd

:: 检查 "program.hex" 是否成功生成在Software目录下
if not exist "%SOFTWARE_DIR%\program.hex" (
    echo [错误] 生成 program.hex 文件失败。脚本将中止。
    goto end
)
:: Verilog的 instruction_memory 模块配置为从相对路径读取 program.hex,
:: 因此不再需要将 program.hex 复制到仿真运行目录。
echo 汇编完成。Verilog将从其预设的相对路径读取 program.hex。
echo.

:: --- 步骤 3: 创建文件列表并编译Verilog源文件 ---
echo [步骤 3] 创建文件列表 (verilog_files.f) 并编译Verilog源文件...
:: 创建一个名为 "verilog_files.f" 的文件列表，其中包含所有设计源文件和仿真源文件的绝对路径。
:: Vivado的xvlog命令将使用此文件列表进行编译。
(
    echo "%DESIGN_SRC_DIR%\data_memory.v"
    echo "%DESIGN_SRC_DIR%\instruction_memory.v"
    echo "%DESIGN_SRC_DIR%\alu.v"
    echo "%DESIGN_SRC_DIR%\pc.v"
    echo "%DESIGN_SRC_DIR%\imm_extender.v"
    echo "%DESIGN_SRC_DIR%\register_file.v"
    echo "%DESIGN_SRC_DIR%\control_unit.v"
    echo "%DESIGN_SRC_DIR%\cpu_top.v"
    echo "%SIM_SRC_DIR%\cpu_tb.v"
) > verilog_files.f

:: 使用 'call' 命令执行xvlog, 确保xvlog执行完毕后控制权返回到此批处理脚本。
:: -sv 表示支持SystemVerilog特性 (尽管这些文件主要是Verilog)。
:: --work xil_defaultlib 指定工作库。
:: -f verilog_files.f 指定包含文件列表的文件。
call xvlog -sv --work xil_defaultlib -f verilog_files.f
if %errorlevel% neq 0 (
    echo [错误] Verilog编译失败。请检查 xvlog.log 文件获取详细错误信息。
    goto end
)
echo Verilog编译成功。
echo.

:: --- 步骤 4: 设计阐述和构建仿真快照 ---
echo [步骤 4] 使用 xelab 进行设计阐述和构建仿真快照...
:: 使用 'call' 命令执行xelab。
:: --debug typical 启用典型调试功能。
:: --snapshot cpu_tb_snapshot 指定生成的仿真快照名称。
:: xil_defaultlib.cpu_tb 指定顶层测试平台模块。
:: -log elaborate.log 指定阐述过程的日志文件。
call xelab --debug typical --snapshot cpu_tb_snapshot xil_defaultlib.cpu_tb -log elaborate.log
if %errorlevel% neq 0 (
    echo [错误] 设计阐述失败。请检查 elaborate.log 文件获取详细错误信息。
    goto end
)
echo 设计阐述成功。
echo.

:: --- 步骤 5: 运行仿真 ---
echo [步骤 5] 使用 xsim 运行仿真...
echo ======================= 仿真输出开始 =======================
:: 使用 'call' 命令执行xsim。
:: cpu_tb_snapshot 是上一步生成的快照名称。
:: --runall 表示运行仿真直到 $finish 被调用或达到仿真时间限制。
:: --log 指定仿真日志文件的输出路径，这里将其保存到项目根目录下的 simulation.log。
call xsim cpu_tb_snapshot --runall --log ..\..\..\..\..\simulation.log
echo ======================== 仿真输出结束 ========================
echo 仿真运行结束。
echo.

:end
echo 脚本执行完毕。按任意键退出。
pause > nul
