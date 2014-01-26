all:
	mkdir /home/pi/cooker
	cp cooker/cooker.pl /home/pi/cooker
	sudo cp web/* /var/www
	chgrp www-data /var/www
	chmod 775 /var/www
	sudo cp misc/group /etc/group

clean:
	rm -rf /home/pi/cooker
	sudo rm -f /var/www/*
