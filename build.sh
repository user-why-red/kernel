#! /bin/bash

 # Script For Building Android arm64 Kernel
 #
 # Copyright (c) 2018-2020 Panchajanya1999 <rsk52959@gmail.com>
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

#Kernel building script

# Function to show an informational message
msg() {
    echo -e "\e[1;32m$*\e[0m"
}

err() {
    echo -e "\e[1;41m$*\e[0m"
    exit 1
}

##------------------------------------------------------##
##----------Basic Informations, COMPULSORY--------------##

# The defult directory where the kernel should be placed
KERNEL_DIR=$PWD

# Devices variable
ZIPNAME="Heh-4.19"
DEVICE="$1"
DEFCONFIG=vendor/bouquet_defconfig
FG_DEFCON=vendor/$1.config
CCACHE="$2"
KERNELSU="$3"

# EnvSetup
KBUILD_BUILD_USER="Nope"
KBUILD_BUILD_HOST=NotThisEither
export CHATID="-1001262484455"
export KBUILD_BUILD_HOST KBUILD_BUILD_USER

export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER
export CI_BRANCH=$DRONE_BRANCH

# Check Kernel Version
KERVER=$(make kernelversion)

# Set a commit head
COMMIT_HEAD=$(git log --oneline -1)

##-----------------------------------------------------##

clone() {
	echo " "
	msg "|| Cloning Clang ||"
	git clone https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone -b 16 clang-llvm --depth=1 --no-tags --single-branch

	msg "|| Cloning Binutils ||"
	git clone https://github.com/KudProject/prebuilts_gas_linux-x86.git gcc --depth=1 --single-branch --no-tags

	# Toolchain Directory defaults to clang-llvm
	TC_DIR=$KERNEL_DIR/clang-llvm
	GCC_DIR=$KERNEL_DIR/gcc
        if [ -n "$KERNELSU" ]; then
          git reset --hard
          curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
        fi   
}

##------------------------------------------------------##

exports() {
	export ARCH=arm64
	export SUBARCH=arm64

	KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
	PATH=$TC_DIR/bin/:$PATH
	export CROSS_COMPILE=$GCC_DIR/gcc/aarch64-linux-gnu-
	export CROSS_COMPILE_COMPAT=$GCC_DIR/gcc/arm-linux-gnueabi-
	export LD_LIBRARY_PATH=$TC_DIR/lib64:$LD_LIBRARY_PATH

	export PATH KBUILD_COMPILER_STRING
	PROCS=$(nproc --all)
	export PROCS
}

##---------------------------------------------------------##

build_kernel() {

	msg "|| Started Compilation ||"
        if [ -n "$CCACHE" ]; then
	  firebuild make O=out $DEFCONFIG $FG_DEFCON LLVM=1 LLVM_IAS=1
 	  firebuild make -j"$PROCS" O=out LLVM=1 LLVM_IAS=1 
	else
  	  firebuild make O=out $DEFCONFIG $FG_DEFCON LLVM=1 LLVM_IAS=1
 	  firebuild make -j"$PROCS" O=out LLVM=1 LLVM_IAS=1
	fi
	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))

		if [ -f "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb ]
	    then
	    	msg "|| Kernel successfully compiled ||"
		else
                echo "failed"
		fi

}

##--------------------------------------------------------------##

gen_zip() {
	msg "|| Zipping into a flashable zip ||"
	cp "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb AnyKernel3/Image.gz-dtb
	cd AnyKernel3 || exit
	zip -r9 San-Kernel.zip ./* -x .git README.md

	## Prepare a final zip variable
	ZIP_FINAL="$ZIPNAME-$DEVICE-$DRONE_BUILD_NUMBER.zip"
	curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/raphielscape/scripts/master/zipsigner-3.0.jar

	msg "|| Signing zip ||"
	java -jar zipsigner-3.0.jar San-Kernel.zip "$ZIP_FINAL"
	cd ..
	rm -rf AnyKernel3
}

clone
exports
build_kernel

##----------------*****-----------------------------##
