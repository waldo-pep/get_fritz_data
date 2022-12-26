# get_fritz_data

read data from frtiz box and write it in a csv file
tested and developed with my fritzbox 7390 with FRITZ!OS: 06.87!

example call: get_fritz_data.sh

--> based on ct script "fritz_docsis_2_influx_lines.sh" by c't <--\
https://www.heise.de/ratgeber/Kabelfritz-Monitor-Die-Leistungsguete-von-Fritzboxen-mit-dem-Raspi-ueberwachen-7240786.html


# work in progress, hopefully more comes ;)

note: To prevent your access data from being accidentally uploaded, 
      use the following command on the command line:\
      git update-index --assume-unchanged my.credentials