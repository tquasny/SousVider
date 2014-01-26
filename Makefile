all:
	mkdir /home/pi/cooker
	cp cooker/cooker.pl /home/pi/cooker
	sudo cp web/* /var/www

clean:
	rm -rf /home/pi/cooker
	sudo rm -f /var/www/*
