#!/bin/bash

. $(dirname $0)/../global_definitions

ROOT_BLKDEV=${ROOT_BLKDEV-/dev/mmcblk0}
BOOT_RESIZER=$(dirname $0)/../stage4/init_resize
BOOT_RESIZER_DEPLOYED=/usr/local/sbin/init_resize


FSTYPE_REPLACE_TOKEN="__FSTYPE_REPLACE__"
BLKDEV_REPLACE_TOKEN="__BLKDEV_REPLACE__"
RESIZE_TARGET_REPLACE_TOKEN="__RESIZE_TARGET_REPLACE__"
REVERT_REPLACE_TOKEN="__REVERT_REPLACE__"

deployed=${ROOT_PATH}${BOOT_RESIZER_DEPLOYED}

cmdline=$(cat $BOOT_PATH/cmdline.txt)

case $FSTYPE in
    btrfs)
        resizeTarget="/";
        aptPackage="btrfs-progs"
        ;;
    ext2|ext3|ext4)
        resizeTarget=${ROOT_PART=/dev/mmcblk0p2}
        aptPackage="e2fsprogs"
        ;;
    f2fs)
        resizeTarget=${ROOT_PART=/dev/mmcblk0p2}
        aptPackage="f2fs-tools"
        ;;

    *)
        resizeTarget=${ROOT_PART=/dev/mmcblk0p2}
        ;;
esac

echo "Installing packages via APT..."
chroot $ROOT_PATH apt-get install -y parted $aptPackage

echo "Deploying boot resizer..."
cp $BOOT_RESIZER $deployed

sed -i "s/$FSTYPE_REPLACE_TOKEN/$FSTYPE/" $deployed
sed -i "s/$BLKDEV_REPLACE_TOKEN/$ROOT_BLKDEV/" $deployed
sed -i "s/$RESIZE_TARGET_REPLACE_TOKEN/$resizeTarget" $deployed
sed -i "s/$REVERT_REPLACE_TOKEN/init=$BOOT_RESIZER_DEPLOYED/" $deployed
chmod a+x ${ROOT_PATH}${BOOT_RESIZER_DEPLOYED}

echo "Updating $BOOT_PATH/cmdline.txt"
echo ${cmdline}" init=$BOOT_RESIZER_DEPLOYED" > $BOOT_PATH/cmdline.txt

echo "Done."

