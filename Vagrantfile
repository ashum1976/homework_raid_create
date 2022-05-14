# Describe VMs
MACHINES = {
  # VM name "raid_create"
 :"raid-create" => {
              # VM box
              :box_name => "centos7_k5_raid_home",
              # VM CPU count
              :cpus => 3,
              # VM RAM size (Mb)
              :memory => 2048,
              # networks
              :net => [],
#              :net => {
 #                      :eth1 => {
  #                                        :ipaddr => '192.168.15.15'
   #                              }
    #                   },

              # forwarded ports
              :forwarded_port => [],
              :sync_path => "./sync_data",
              #:sync_path => ,
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
                                            },
                         :sata6 => {
                                            :dfile => "./hddvm/sata6.vdi",
                                            :size => 1024,
                                            :port => 6
                                            },
                         :sata7 => {
                                            :dfile => "./hddvm/sata7.vdi",
                                            :size => 1024,
                                            :port => 7
                                            }
                                    }
                                }
                            }
Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|   #  - Задание переменных |boxname (raid_create) является массивом переменных и boxconfig (остальные переменные масива, cpu, memory,disk и т.д. ),  из масива MACHINES (можно создавать по шаблону много машин, например:
                                                                                # kernel_updates
                                                                                # raid_create
                                                                                # и т.д)
                                                                                # т.е добавляем ещё одно описание следующей машины и так далее, сколько нужно, дальше они будут создаваться в цикле, для провайдера virtualbox.
    # Disable shared folders
                # config.vm.synced_folder ".", "/vagrant", disabled: true  # - отключаем проброс папок с хостовой системы в гостевую для всех создаваемых машин, но можем включить
                # Apply VM config
                    config.vm.define boxname do |box|
                        # Set VM base box and hostname
                                box.vm.box = boxconfig[:box_name]
                                box.vm.host_name = boxname.to_s
                        # Additional network config if present
                                if boxconfig.key? (:net) # - () это наличие такой переменной (значения) в массиве
                                     boxconfig [:net].each do |etconf, ipconf| # - цикл по значению переменно [:net], т.е :eth1 => { :ipaddr => '192.168.10.15'}
                                    #    box.vm.network "private_network", ip: ipconf
                                    #     "#{ipconf}" - получить строку находящуюся в переменной ipconf (:ipaddr => '192.168.10.15')
                                        box.vm.network :private_network, ip: ipconf[:ipaddr]
                                    end
                                end
                        # Port-forward config if present
                                if boxconfig.key?(:forwarded_port)
                                    boxconfig[:forwarded_port].each do |port|
                                        box.vm.network "forwarded_port", port
                                    end
                                end
                        #Включение директорий для проброса с хостовой машины на гостевую
                              #  if boxconfig.key?(:sync_path)
                              #      boxconfig[:sync_path].each do |path|
                              #          config.vm.synced_folder path
                                          config.vm.synced_folder boxconfig[:sync_path], "/vagrant"
                              #     end

                              #  end

                                # VM resources config
                    box.vm.provider "virtualbox" do |v|
                        # Set VM RAM size and CPU count
                                v.memory = boxconfig[:memory]
                                v.cpus = boxconfig[:cpus]
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
                    end

                    box.vm.provision "shell", inline: <<-SHELL
                    #          mkdir -p ~root/.ssh
                    #          cp ~vagrant/.ssh/auth* ~root/.ssh
                                yum install -y mdadm smartmontools hdparm gdisk
                                /vagrant/bash.sh
                                SHELL


                    end
    end
end
