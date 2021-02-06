#! /usr/bin/bash


if [ ! -e $(ls /dev/md*) ]; then
  
  


        # Занулить суперблоки на дисках

                mdadm --zero-superblock --force /dev/sd{b,c,d,e,f,g,h} > /dev/null 2>&1

        # Удаляем старые метаданные и подпись на дисках

                wipefs --all --force /dev/sd{b,c,d,e,f,g,h} > /dev/null 2>&1

        # создание рейда 5-го уровня

                mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f} > /dev/null 2>&1


        # Создание файла mdadm.conf

                if [ ! -d "/etc/mdadm" ]; then

                        mkdir /etc/mdadm
                        echo "DEVICE partitions" > /etc/mdadm/mdadm.conf  
                        mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

                fi
else
        echo "Рейд существует"
        echo $(ls /dev/md*)
        exit 1
        
fi
  
#mkdir /etc/mdadm

#echo "DEVICE partitions" > /etc/mdadm/mdadm.conf

#mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf


touch ./test
