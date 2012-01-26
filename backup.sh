#! /bin/bash

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#   Script to:
#     * Mount device
#     * rsync all files
#     * compare directories
#     * unmount device
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-

export EXIT=0

menu () {
    clear
    echo -e "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n"
    echo -e "  P1 Backup Menu Options:\n\n"
    x=1
    UPPER=$#
    while (( $x <= $UPPER )); do
      echo "  $x. $1"
      arr[$x]=$1
      shift
      ((x+=1))
    done
    echo -e "\nOPTION[1..$x]> \c"
    read OPTION
    echo $OPTION
    if (( OPTION > 0 )); then
      FUNC `echo ${arr[$OPTION]}|sed 's/_/ /g'`
    else
      echo "WRONG!"
      sleep 1
    fi
}

FUNC () {
  case $1 in
    QUIT)
      export EXIT=1
      exit 0
      ;;
    MOUNT)
      if [[ $2 = "" ]]; then
        menu `for i in $(ls /dev/sd[a-z]); do echo "MOUNT_$i";done`
      else
        cryptsetup luksDump ${2}1
        echo -e "CONTINUE[YN]? \c"
        read yesno
        case $yesno in
          y|Y|yes|YES)
            cryptsetup luksOpen ${2}1 backup_drive
            [[ $? != 0 ]] && echo "BUM!" && exit 2
            mount -o noatime /dev/mapper/backup_drive /mnt
            df -h /mnt
            sleep 2
            ;;
          *)
            echo "FOKAY!"
            sleep 1
            ;;
        esac
      fi
      ;;
    UNMOUNT)
      filesys=`df -hP |grep backup_drive |awk '{print $NF}'`
      umount $filesys
      [[ $? != 0 ]] && echo "BUMMMMM!" && exit 5
      cryptsetup luksClose /dev/mapper/backup_drive
      echo -e "\n\nPLEASE DO A MANUAL EJECT!!\n\n"
      sleep 5
      EXIT=2
      exit 0
      ;;
    RSYNC)
      echo "starting: ..."
      echo "ETC"
      rsync -aAXh --delete /etc/* /mnt/etc/
      echo "HOME"
      rsync -aAXh --delete /home/* /mnt/home/
      echo "SERVER"
      rsync -aAXh --delete /server/* /mnt/server/
      echo "PACKAGELIST"
      rpm -qa > /mnt/packages.list
      ;;
  esac
}

while [[ $EXIT = 0 ]]; do
  menu MOUNT UNMOUNT RSYNC QUIT
done

