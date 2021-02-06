# homework_raid_create
<<<<<<< HEAD
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

# Создание и управление програмным рейд-масивом в Linux дистрибутив CentOS/RedHat/Oracle Linux

Для тестового стенда используем вагрант-файл из проект на GitHab 
=======
	Второй урок OTUS по созданию RAID массивов
	Необходимо  создать c помощью vagrant машину, с несколькими дисками
	
	
	
	
>>>>>>> b19d62151180c08cd543c5926fec9f6c239c49d1
