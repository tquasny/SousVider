#!/usr/bin/perl

use strict;
use warnings;
use Device::BCM2835;


#Initialize GPIO
Device::BCM2835::init() || die "Could not init BCM2835 device";
Device::BCM2835::gpio_fsel(&Device::BCM2835::RPI_GPIO_P1_11, 
                            &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);    

Device::BCM2835::gpio_write(&Device::BCM2835::RPI_GPIO_P1_11, 0);
Device::BCM2835::delay(500); # Milliseconds
    
