@echo off
:: 设置窗口标题
TITLE LA32R CPU Simulation Automation

:: ============================================================================
:: LA32R 单周期 CPU 自动化仿真脚本 (适配Vivado项目结构)
::
:: 功能:
:: 1. 定义项目文件路径。
:: 2. 在正确的仿真目录下清理、执行所有步骤。
:: 3. 运行 Python 汇编器生成 program.hex (已修正工作目录)。
:: 4. 编译、链接并运行仿真 (已修正脚本提前退出的问题)。
::
:: 使用方法:
:: - 将此脚本放在项目的根目录下。
:: - 确保 Vivado 的 bin 目录已添加到系统的 PATH 环境变量中。
:: - 直接双击运行此脚本。
:: ============================================================================

:: --- 步骤 0: 定义项目路径 ---
:: %~dp0 会获取脚本所在的目录，作为我们的项目根目录
set "PROJECT_ROOT=%~dp0"
set "SOFTWARE_DIR=%PROJECT_ROOT%Software"
set "DESIGN_SRC_DIR=%PROJECT_ROOT%Hardware\LA32R.srcs\sources_1\new"
set "SIM_SRC_DIR=%PROJECT_ROOT%Hardware\LA32R.srcs\sim_1\new"
set "SIM_RUN_DIR=%PROJECT_ROOT%Hardware\LA32R.sim\sim_1\behav\xsim"

echo Project Root: %PROJECT_ROOT%
echo Simulation Run Directory: %SIM_RUN_DIR%
echo.

:: --- 准备工作：切换到仿真运行目录 ---
:: 创建目录（如果不存在）并进入
if not exist "%SIM_RUN_DIR%" ( mkdir "%SIM_RUN_DIR%" )
cd /d "%SIM_RUN_DIR%"

:: --- 步骤 1: 清理环境 ---
echo [STEP 1] Cleaning up previous simulation files...
if exist xsim.dir ( rd /s /q xsim.dir )
if exist *.log ( del *.log )
if exist *.jou ( del *.jou )
if exist verilog_files.f ( del verilog_files.f )
if exist webtalk*.xml ( del webtalk*.xml )
if exist webtalk*.tcl ( del webtalk*.tcl )
echo.

:: --- 步骤 2: 运行Python汇编器 ---
echo [STEP 2] Assembling test program...
:: [FIX] 使用 pushd/popd 临时切换目录以保证python脚本的工作目录正确
pushd "%SOFTWARE_DIR%"
python assembler.py
popd

:: 检查 program.hex 是否成功生成
if not exist "%SOFTWARE_DIR%\program.hex" (
    echo [ERROR] Failed to generate program.hex. Halting script.
    goto end
)
:: [FIX] 移除文件复制步骤，因为Verilog已配置为使用相对路径
echo Assembly complete. Verilog will read program.hex from its relative path.
echo.

:: --- 步骤 3: 创建文件列表并编译Verilog ---
echo [STEP 3] Creating file list and compiling Verilog sources...
:: 创建一个文件列表，包含所有设计和仿真源文件的绝对路径
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

:: [FIX] 添加 'call' 命令确保执行后控制权返回脚本
call xvlog -sv --work xil_defaultlib -f verilog_files.f
if %errorlevel% neq 0 (
    echo [ERROR] Verilog compilation failed. Check xvlog.log for details.
    goto end
)
echo Verilog compilation successful.
echo.

:: --- 步骤 4: 链接和构建仿真快照 ---
echo [STEP 4] Elaborating the design with xelab...
:: [FIX] 添加 'call' 命令
call xelab --debug typical --snapshot cpu_tb_snapshot xil_defaultlib.cpu_tb -log elaborate.log
if %errorlevel% neq 0 (
    echo [ERROR] Design elaboration failed. Check elaborate.log for details.
    goto end
)
echo Design elaboration successful.
echo.

:: --- 步骤 5: 运行仿真 ---
echo [STEP 5] Running simulation with xsim...
echo ======================= SIMULATION OUTPUT START =======================
:: [FIX] 添加 'call' 命令
call xsim cpu_tb_snapshot --runall --log ..\..\..\..\..\simulation.log
echo ======================== SIMULATION OUTPUT END ========================
echo.

:end
echo Script finished. Press any key to exit.
pause > nul
