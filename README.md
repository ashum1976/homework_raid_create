# homework_raid_create

                                Второй урок OTUS по созданию RAID массивов
При запуске стенда с подключаемыми виртуальными дисками, в VirtualBox обнаружился неприятный баг, для хостовой машины   
AMD Phenom II X4 965, не создавались виртуальные диски формата vdi, постоянно появлялась ошибка:

                A customization command failed:
                ["createhd", "--filename", "/installs/Study/OTUS/lesson_02/homework_raid_create/diskvm/sata4.vdi", "--size", 1024]                                                                                   
                The following error was experienced:                                                                                                                                                                 
                #<Vagrant::Errors::VBoxManageError: There was an error while executing `VBoxManage`, a CLI used by Vagrant                                                                                           
                for controlling VirtualBox. The command and stderr is shown below.                                                                                                                                   
                Command: ["createhd", "--filename", "/installs/Study/OTUS/lesson_02/homework_raid_create/diskvm/sata4.vdi", "--size", "1024"]                                                                        
                Stderr: 0%...                                                                                                                                                                                        
                Progress state: VBOX_E_FILE_ERROR                                                                                                                                                                    
                VBoxManage: error: Failed to create medium                                                                                                                                                           
                VBoxManage: error: Could not create the medium storage unit '/installs/Study/OTUS/lesson_02/homework_raid_create/diskvm/sata4.vdi'.                                                                  
                VBoxManage: error: VDI: cannot create image '/installs/Study/OTUS/lesson_02/homework_raid_create/diskvm/sata4.vdi' (VERR_ALREADY_EXISTS)  

Решение данной проблемы оказалось включение параметра в VirtualBox Настройка -> Система -> Материнская плата -> Чипсет: ICH9
а также уменьшение числа доступных для создания портов,  в контороллере диска SATA, до 10 Настройка -> Носители -> Контроллер:sata -> Атрибуты:порты:10

#                                   1. Создание и управление програмным рейд-масивом в Linux дистрибутив CentOS/RedHat/Oracle Linux

#           1.1 Подготовка стенда

Для тестового стенда используем вагрант-файл из проект на GitHab https://github.com/ashum1976/homework_raid_create
Для начала работы по теме урока, необходимо создать ещё диски в VAgrant файле проекта,

    :diskv => {
                        :sata1 => {
                                            :dfile => "./hddvm/sata1.vdi",
                                            :size => 1024,
                                            :port => 1,
                                           },
                        :sata2 => {
                                            :dfile => "./hddvm/sata2.vdi",
                                            :size => 1024,
                                            :port => 2,
                                            },
                        :sata3 => {
                                            :dfile => "./hddvm/sata3.vdi",
                                            :size => 1024,
                                            :port => 3,
                                            },
                        :sata4 => {
                                            :dfile => "./hddvm/sata4.vdi",
                                            :size => 1024,
                                            :port => 4
                                            },          
                         :sata5 => {
                                            :dfile => "./hddvm/sata5.vdi",
                                            :size => 1024,
                                            :port => 5
                                            }

Добавили переменные в масив дисков diskv, далее циклом создали сами диски и подключили их к виртуальной машине

             needsController = false
                                boxconfig[:diskv].each do |dname, dconf|
                                            unless File.exist?(dconf[:dfile])
                                            v.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
                                            needsController = true
                                    end
                                end

                                if needsController == true
                                            v.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
                                           boxconfig[:diskv].each do |dname, dconf|
                                            v.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium',dconf[:dfile]]
                                     end     
                                end                   
#           1.2 Работа с рейдом   

Запускаем виртуальную машину, в которой выполняется начальный shell provision для установки необхдимых пакетов (mdadm smarttools и т.д)для работы с программнам рейдом

           box.vm.provision "shell", inline: <<-SHELL
           #          mkdir -p ~root/.ssh
           #          cp ~vagrant/.ssh/auth* ~root/.ssh
                      yum install -y mdadm smartmontools hdparm gdisk
                      /vagrant/bash.sh
                      SHELL
#                                                   1.3 Сборка RAID

Перед сборкой, стоит подготовить наши носители. Затем можно приступать к созданию рейд-массива.

Все дальнейшие  действия  выполняем от root
sudo su -l

Подготовка носителей

Нужно определиться какого уровня RAID будем собирать. Для это посмотрим какие блочные устройства у нас есть:

* lsblk
* lshw
* fdisk -l

            [root@raid-create ~]#  lshw -short | grep disk
            /0/1f.1/0.0.0    /dev/sda   disk        42GB VBOX HARDDISK
            /0/1f.2/0        /dev/sdb   disk        1073MB VBOX HARDDISK
            /0/1f.2/1        /dev/sdc   disk        1073MB VBOX HARDDISK
            /0/1f.2/2        /dev/sdd   disk        1073MB VBOX HARDDISK
            /0/1f.2/3        /dev/sde   disk        1073MB VBOX HARDDISK
            /0/1f.2/0.0.0    /dev/sdf   disk        1073MB VBOX HARDDISK

sda - диск с ситемой созданный при запуске виртуальной машины из образа, остальные диски - добавлены для создания рейда, их и будем использовать. Собирать будем рейд 5-го уровня, из 5 дисков и один диск горячей замены (добавим в процессе работы).

Сначала необходимо занулить суперблоки на дисках, которые мы будем использовать для построения RAID (если диски ранее использовались, их суперблоки могут содержать служебную информацию о других RAID):

            mdadm --zero-superblock --force /dev/sd{b,c,d,e,f,}

* мы зануляем суперблоки для дисков sdc sdb sdd sde sdf

Если мы получили ответ:

            mdadm: Unrecognised md component device - /dev/sdb
            mdadm: Unrecognised md component device - /dev/sdc

... то значит, что диски не использовались ранее для RAID. Просто продолжаем настройку.

Потом удаляем старые метаданные и подпись на дисках:

            wipefs --all --force /dev/sd{b,c,d,e,f}



Создание рейда
Для сборки избыточного массива применяем следующую команду:

            mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}

* где:

/dev/md0 — устройство RAID, которое появится после сборки;
-l 5 — уровень RAID;
-n 5 — количество дисков, из которых собирается массив /dev/sd{b,c,d,e,f}

Система задаст контрольный вопрос, хотим ли мы продолжить и создать RAID — нужно ответить y:

            Continue creating array? y

Мы увидим что-то на подобие:

            mdadm: Defaulting to version 1.2 metadata
            mdadm: array /dev/md0 started.

Проверяем, что рейд собрался нормально команда cat /proc/mdstat:

            [root@raid-create ~]# cat /proc/mdstat
            Personalities : [raid6] [raid5] [raid4]
            md0 : active raid5 sdf[5] sdd[2] sde[3] sdc[1] sdb[0]
                4186112 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/5] [UUUUU]

unused devices: <none>

или с более полным выводом о созданном рейде:

        [root@raid-create ~]# mdadm -D /dev/md0
        /dev/md0:
                Version : 1.2
            Creation Time : Fri Feb  5 23:42:39 2021
                Raid Level : raid5
                Array Size : 4186112 (3.99 GiB 4.29 GB)
            Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
            Raid Devices : 5
            Total Devices : 5
            Persistence : Superblock is persistent

            Update Time : Fri Feb  5 23:42:53 2021
                    State : clean
            Active Devices : 5
            Working Devices : 5
            Failed Devices : 0
            Spare Devices : 0

                    Layout : left-symmetric
                Chunk Size : 512K

            Consistency Policy : resync

                    Name : raid-create:0  (local to host raid-create)
                    UUID : 1a821da7:80ff42fd:806703dd:b69fa23c
                    Events : 18

            Number   Major   Minor   RaidDevice State
            0       8       16        0      active sync   /dev/sdb
            1       8       32        1      active sync   /dev/sdc
            2       8       48        2      active sync   /dev/sdd
            3       8       64        3      active sync   /dev/sde
            5       8       80        4      active sync   /dev/sdf

* где:

            Version — версия метаданных.
            Creation Time — дата в время создания массива.
            Raid Level — уровень RAID.
            Array Size — объем дискового пространства для RAID.
            Used Dev Size — используемый объем для устройств. Для каждого уровня будет индивидуальный расчет: RAID1 — равен половине общего размера дисков, RAID5 — равен размеру, используемому для контроля четности.
            Raid Devices — количество используемых устройств для RAID.
            Total Devices — количество добавленных в RAID устройств.
            Update Time — дата и время последнего изменения массива.
            State — текущее состояние. clean — все в порядке.
            Active Devices — количество работающих в массиве устройств.
            Working Devices — количество добавленных в массив устройств в рабочем состоянии.
            Failed Devices — количество сбойных устройств.
            Spare Devices — количество запасных устройств.
            Consistency Policy — политика согласованности активного массива (при неожиданном сбое). По умолчанию используется resync — полная ресинхронизация после восстановления. Также могут быть bitmap, journal, ppl.
            Name — имя компьютера.
            UUID — идентификатор для массива.
            Events — количество событий обновления.
            Chunk Size (для RAID5) — размер блока в килобайтах, который пишется на разные диски.

Информация по диску (разделу) входящему в массив:



        mdadm -E /dev/sda1

      /dev/sda1:
                Magic : a92b4efc
              Version : 1.2
          Feature Map : 0x0
           Array UUID : 3a8605c3:bf0bc5b3:823c9212:7b935117
                 Name : localhost.localdomain:0  (local to host localhost.localdomain)
        Creation Time : Tue Jul 26 07:49:50 2011
           Raid Level : raid1
         Raid Devices : 2

       Avail Dev Size : 20969472 (10.00 GiB 10.74 GB)
           Array Size : 20969328 (10.00 GiB 10.74 GB)
        Used Dev Size : 20969328 (10.00 GiB 10.74 GB)
          Data Offset : 2048 sectors
         Super Offset : 8 sectors
                State : active
          Device UUID : 10384215:18a75991:4f09b97b:1960b8cd

          Update Time : Tue Jul 26 07:50:43 2011
             Checksum : ea435554 - correct
               Events : 18




#           1.4 Создание конфигурационного файла mdadm.conf

В файле mdadm.conf находится информация о RAID-массивах и компонентах, которые в них входят. Для его создания выполняем следующие команды:

            mkdir /etc/mdadm

            echo "DEVICE partitions" > /etc/mdadm/mdadm.conf

            mdadm --detail --scan >> /etc/mdadm/mdadm.conf

Пример содержимого:

            DEVICE partitions
            ARRAY /dev/md0 level=raid5 num-devices=5 metadata=1.2 name=raid-create:0 UUID=1a821da7:80ff42fd:806703dd:b69fa23c

Или вот такой командой создадим файл конфигурации:

            mdadm -Db /dev/md0 > /etc/mdadm/mdadm.conf


#           1.5 Восстановление RAID


Эмулируем ситуацию с выходом из строя одного диска

            mdadm /dev/md0 --fail /dev/sdd


В случае выхода из строя одного из дисков массива, команда cat /proc/mdstat покажет следующее:

            [root@raid-create vagrant]# cat /proc/mdstat
            Personalities : [raid6] [raid5] [raid4]
            md0 : active raid5 sdd[2](F) sde[3] sdc[1] sdf[5] sdb[0]
                4186112 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/4] [UU_UU]

* о наличии проблемы нам говорит нижнее подчеркивание вместо U [UU_UU]


или команда mdadm -D /dev/md0


            [root@raid-create ~]# mdadm -D /dev/md0
                /dev/md0:
                    Version : 1.2
                    Creation Time : Fri Feb  5 23:42:39 2021
                    Raid Level : raid5
                    Array Size : 4186112 (3.99 GiB 4.29 GB)
                Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
                Raid Devices : 5
                Total Devices : 5
                Persistence : Superblock is persistent

            Update Time : Sat Feb  6 00:56:38 2021
                    State : clean, degraded   <- статус "деградирован"
            Active Devices : 4
            Working Devices : 4
            Failed Devices : 1 <- количество проблемных устройств
            Spare Devices : 0

Для восстановления, сначала удалим сбойный диск

            [root@raid-create vagrant]# mdadm /dev/md0 --remove /dev/sdd
            mdadm: hot removed /dev/sdd from /dev/md0


Теперь добавим новый

            [root@raid-create vagrant]# cat /proc/mdstat
              Personalities : [raid6] [raid5] [raid4]
            md0 : active raid5 sdh[6] sde[3] sdc[1] sdf[5] sdb[0]
                4186112 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/4] [UU_UU]
                [===>.................]  recovery = 16.1% (169148/1046528) finish=1.1min speed=13011K/sec


            [root@raid-create vagrant]# mdadm -D /dev/md0
            /dev/md0:
                Version : 1.2
            Creation Time : Sat Feb  6 20:53:47 2021
                Raid Level : raid5
                Array Size : 4186112 (3.99 GiB 4.29 GB)
            Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
            Raid Devices : 5
            Total Devices : 5
            Persistence : Superblock is persistent

            Update Time : Sat Feb  6 21:14:33 2021
                    State : clean, degraded, recovering <-  *  recovering говорит, что RAID восстанавливается; Rebuild Status — текущее состояние
                    ...
                    Rebuild Status : 41% complete
                    ...

#           1.5.1 Проверка целостности



Для проверки целостности вводим:

    echo 'check' > /sys/block/md0/md/sync_action

Результат проверки смотрим командой:

    cat /sys/block/md0/md/mismatch_cnt

* если команда возвращает 0, то с массивом все в порядке.

Остановка проверки:

    echo 'idle' > /sys/block/md0/md/sync_action



#           1.6 Пересборка массива

Если нам нужно вернуть ранее разобранный или развалившийся массив из дисков, которые уже входили в состав RAID, вводим:

    mdadm --assemble --scan

    [root@raid-create vagrant]# mdadm --assemble --scan
    mdadm: Found some drive for an array that is already active: /dev/md0 <- текущее состояние активное, рейд работает пересборка не нужна
    mdadm: giving up.

* данная команда сама найдет необходимую конфигурацию и восстановит RAID.

Также, мы можем указать, из каких дисков пересобрать массив:

    mdadm --assemble /dev/md0 /dev/sdb /dev/sdc и т.д.

#           1.7 Запасной диск (Hot Spare)

Если в массиве будет запасной диск для горячей замены, при выходе из строя одного из основных дисков, его место займет запасной.

Диском Hot Spare станет тот, который просто будет добавлен к массиву:

    mdadm /dev/md0 --add /dev/sdd

Информация о массиве изменится, например:

    mdadm -D /dev/md0

    Number   Major   Minor   RaidDevice State
        0       8       16        0      active sync   /dev/sdb
        1       8       32        1      active sync   /dev/sdc
        6       8       96        2      active sync   /dev/sdg
        3       8       64        3      active sync   /dev/sde
        5       8       80        4      active sync   /dev/sdf

        7       8       48        -      spare   /dev/sdd



Проверить работоспособность резерва можно вручную, симулировав выход из строя одного из дисков:

    mdadm /dev/md0 --fail /dev/sdc

И смотрим состояние:

    mdadm -D /dev/md0

    .......

    Number   Major   Minor   RaidDevice State
        0       8       16        0      active sync   /dev/sdb
        7       8       48        1      spare rebuilding   /dev/sdd
        6       8       96        2      active sync   /dev/sdg
        3       8       64        3      active sync   /dev/sde
        5       8       80        4      active sync   /dev/sdf

    .......


* как видим, начинается ребилд. На замену вышедшему из строя sdc встал hot-spare sdd.

#           1.8 Добавить диск к массиву
В данном примере рассмотрим вариант добавления активного диска к RAID, который будет использоваться для работы, а не в качестве запасного.

Добавляем диск к массиву:

    mdadm /dev/md0 --add /dev/sdc

Новый диск мы увидим в качестве spare:

    Number   Major   Minor   RaidDevice State
        0       8       16        0      active sync   /dev/sdb
        7       8       48        1      active sync   /dev/sdd
        6       8       96        2      active sync   /dev/sdg
        3       8       64        3      active sync   /dev/sde
        5       8       80        4      active sync   /dev/sdf

        8       8       32        -      spare   /dev/sdc

Теперь расширяем RAID:

        mdadm -G /dev/md0 --raid-devices=6

* в данном примере подразумевается, что у нас RAID 5 и мы добавили к нему 6-й диск.


        mdadm -D /dev/md0

 Reshape Status : 0% complete
     Delta Devices : 1, (5->6) <- показывает, что произошло изменение количества дисков

        Name : raid-create:0  (local to host raid-create)
        UUID : 8665b1d3:cefafcf7:e1b24fa2:2900b83d
        Events : 92

Также можно и удалить диск из масива

*   Уменьшаем размер масива

        mdadm -G  /dev/md0 --array-size 4186112
Запускаем процедуру удаления диска из масива, с обязательным созданием бэкап файла  --backup=/tmp/backup

        mdadm -G /dev/md0 --backup=/tmp/backup --raid-devices=5

        ...........
        Consistency Policy : resync

        Reshape Status : 0% complete
        Delta Devices : -1, (6->5) <- уменьшение размера масива на 1 диск
        ...................


#           1.9 Удаление массива
При удалении массива внимателнее смотрите на имена массива и дисков и подставляйте свои значения.

Если нам нужно полностью разобрать RAID, сначала размонтируем и остановим его:

        umount /mnt

* где /mnt — каталог монтирования нашего RAID.

        mdadm -S /dev/md0

* где /dev/md0 — массив, который мы хотим разобрать.
* если мы получим ошибку mdadm: fail to stop array /dev/md0: Device or resource busy, с помощью команды lsof -f -- /dev/md0 смотрим процессы, которые используют раздел и останавливаем их.

Затем очищаем суперблоки на всех дисках, из которых он был собран:

        mdadm --zero-superblock /dev/sdb

        mdadm --zero-superblock /dev/sdc

        mdadm --zero-superblock /dev/sdd
        ......

* где диски /dev/sdb, /dev/sdc, /dev/sdd ..... были частью массива md0.

А также удаляем метаданные и подпись:

        wipefs --all --force /dev/sd{b,c,d,e,f,g,h}

###### Ещё данные в файле - mdadm_dmosk.odt, в папке с документацией


## Полезные команды для работы


##### Собрать raid1 с одним диском

      Иногда при миграции на raid1 бывает нужно.

        mdadm -C --level=1 --raid-devices=2 /dev/sdb1 missing

      Если массив был создан с числом дисков 2 и вторым "missing", второй диск добавляем одной командой:

                mdadm /dev/md0 --add /dev/sda1

      Можно сделать и массив с числом дисков «1»:

        mdadm -C --raid-devices=1 --level=1 --force /dev/md/space1000 /dev/sdc1





## Ошибки при работе с mdadm


##### Массив в режиме auto-read-only

    Если после перезагрузки какой-то массив оказался в режиме read-only, причём /proc/mdstat содержит строки вида:

        md126 : active (auto-read-only) raid1 sdb6[0] sda6[1]
              458209216 blocks [2/2] [UU]
    Это означает, что вы забыли:

- Добавить массив в /etc/mdadm.conf.
- Обновить initrd после создания нового массива.
