all:
	mkdir -p /home/pi/cooker
	cp cooker/cooker.pl /home/pi/cooker
	sudo cp web/* /var/www
	sudo chgrp www-data /var/www
	sudo chmod 775 /var/www
	sudo cp misc/group /etc/group
	sudo chown root:root /etc/group
	sudo chmod 644 /etc/group
	sudo cp misc/sudoers /etc/sudoers
	sudo chown root:root /etc/sudoers
	sudo chmod 440 /etc/sudoers

setup:
	sudo cpan -i Device::BCM2835

clean:
	rm -rf /home/pi/cooker
	sudo rm -f /var/www/*
