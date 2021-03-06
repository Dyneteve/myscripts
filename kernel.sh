 #
 # Script For Building Android arm64 Kernel
 #
 # Copyright (c) 2018-2019 Panchajanya1999 <rsk52959@gmail.com>
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #      http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 #

#! /bin/sh

#Kernel building script

KERNEL_DIR=$PWD
ARG1=$1 #It is the devicename [generally codename]
ARG2=$2 #It is the make arguments, whether clean / dirty / def_regs [regenerates defconfig]
ARG3=$3 #Build should be pushed or not [PUSH / NOPUSH]
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
export ZIPNAME="azure" #Specifies the name of kernel
#We should fetch the latest clang build from android_googlesource
export CLANG_URL=https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/0d3a06b3f58c9093ec5b4fb9ebb3ad0ab2d2e489/clang-r370808.tar.gz

##----------------------------------------------------##

# START : Arguments Check
if [ $# -lt 3 ] # 3 arguments is must
  then
        echo -e "\nToo less Arguments..!! Provided - $# , Required - 3\nCheck README"
        return
  #Get outta
elif [ $# == 3 ]
  then
# START : Argument 1 [ARG1] Check
case "$ARG1" in
  "violet" ) # Execute violet function / scripts
      export DEVICE="Redmi Note 7 Pro [violet]"
      DEFCONFIG=vendor/violet-perf_defconfig
      CHATID="-1001408028770"
  ;;
  * ) echo -e "\nError..!! Unknown device. Please add device details to script and re-execute\n"
      return
  ;;
esac # END : Argument 1 [ARG2] Check

##----------------------------------------------------##

# START : Argument 2 [ARG1] Check
case "$ARG2" in
  "clean" ) # Execute Clean build function
      alias MAKE="make clean && make mrproper && rm -rf out"
  ;;
  "dirty" ) # Do not CLEAN
      
  ;;
  "def_reg" ) # Regenerate defconfig
      export ARCH=arm64
      export SUBARCH=arm64
      make O=out $DEFCONFIG
      mv out/.config $DEFCONFIG
      echo "Defconfig Regenerated"
      exit 1;
  ;;
  * ) echo -e "\nError..!! Unknown Build Command.\n"
      return
  ;;
esac # END : Argument 2 [ARG2] Check

##---------------------------------------------------##

#START : Argument 3 [ARG3] Check
case "$ARG3" in
  "PUSH" ) # Push build to TG Channel
      build_push=true
  ;;
  "NOPUSH" ) # Do not push
      build_push=false
  ;;
  * ) echo -e "\nError..!! Unknown command. Please refer README.\n"
      return
  ;;
esac # END : Argument 3 [ARG3] Check

##-----------------------------------------------------##

else
  echo -e "\nToo many Arguments..!! Provided - $# , Required - 3\nCheck README"
  return
#Get outta
fi

##------------------------------------------------------##

#Now Its time for other stuffs like cloning, exporting, etc

function clone {
	echo " "
	echo "★★Cloning GCC Toolchain from Android GoogleSource .."
	git clone --progress -j32 --depth 1 --no-single-branch https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -q > /dev/null 2>&1
	git clone --progress -j32 --depth 1 --no-single-branch https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -q > /dev/null 2>&1

	echo "★★GCC cloning done"
	echo ""
	echo "★★Cloning Clang 8 sources"
	curl -sLo clang-r370808.tar.gz $CLANG_URL
	mkdir clang-llvm
	tar -C clang-llvm -xvf clang*.tar.gz > /dev/null 2>&1
	rm -rf clang*.tar.gz
	echo "★★Cloning Kinda Done..!!!"
}

##------------------------------------------------------##

function exports {
	export KBUILD_BUILD_USER="Dyneteve"
	export KBUILD_BUILD_HOST="MemeDrone"
	export ARCH=arm64
	export SUBARCH=arm64
	export KBUILD_COMPILER_STRING=$($KERNEL_DIR/clang-llvm/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
	LD_LIBRARY_PATH=$KERNEL_DIR/clang-llvm/lib:$KERNEL_DIR/clang-llvm/lib64:$LD_LIBRARY_PATH
	export LD_LIBRARY_PATH
	PATH=$KERNEL_DIR/clang-llvm/bin/:$KERNEL_DIR/aarch64-linux-android-4.9/bin/:$PATH
	export PATH
	export BOT_MSG_URL="https://api.telegram.org/bot$token/sendMessage"
	export BOT_BUILD_URL="https://api.telegram.org/bot$token/sendDocument"
	env_exports
	export PROCS=$(nproc --all)
}

##---------------------------------------------------------##

function tg_post_msg {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$2" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}

##----------------------------------------------------------------##

function tg_post_build {
	curl --progress-bar -F document=@"$1" $BOT_BUILD_URL \
	-F chat_id="$2"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$3"  
}

##----------------------------------------------------------##

function env_exports {
	export CROSS_COMPILE=$KERNEL_DIR/aarch64-linux-android-4.9/bin/aarch64-linux-android-
	export CROSS_COMPILE_ARM32=$KERNEL_DIR/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
	export CC=$KERNEL_DIR/clang-llvm/bin/clang
	export AR=$KERNEL_DIR/clang-llvm/bin/llvm-ar
	export NM=$KERNEL_DIR/clang-llvm/bin/llvm-nm
	export OBJCOPY=$KERNEL_DIR/clang-llvm/bin/llvm-objcopy
	export OBJDUMP=$KERNEL_DIR/clang-llvm/bin/llvm-objdump
	export STRIP=$KERNEL_DIR/clang-llvm/bin/llvm-strip
}

##----------------------------------------------------------##

function build_kernel {
	if [ "$build_push" = true ]; then
		tg_post_msg "<b>$CIRCLE_BUILD_NUM CI Build Triggered</b>%0A<b>Date : </b><code>$(TZ=Asia/Jakarta date)</code>%0A<b>Device : </b><code>$DEVICE</code>%0A<b>Pipeline Host : </b><code>CircleCI</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0a<b>Branch : </b><code>$CIRCLE_BRANCH</code>%0A<b>Status : </b>#Nightly" "$CHATID"
	fi
	make O=out $DEFCONFIG
	BUILD_START=$(date +"%s")
	make -j$PROCS O=out \
		CROSS_COMPILE=$CROSS_COMPILE \
		CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
		CC=$CC \
		AR=$AR \
		NM=$NM \
		OBJCOPY=$OBJCOPY \
		OBJDUMP=$OBJDUMP \
		STRIP=$STRIP \
		CLANG_TRIPLE=aarch64-linux-gnu- 2>&1 | tee error.log
	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))
}

clone
exports
build_kernel

##----------------*****-----------------------------##
