# get_fritz_data

read data from frtiz box and write it in a csv file
tested and developed with my fritzbox 7390 with FRITZ!OS: 06.87!

example call: get_fritz_data.sh

--> based on ct script "fritz_docsis_2_influx_lines.sh" by c't <--\
https://www.heise.de/ratgeber/Kabelfritz-Monitor-Die-Leistungsguete-von-Fritzboxen-mit-dem-Raspi-ueberwachen-7240786.html

--> great side with fritzbox url's \
https://wiert.me/2018/11/27/fritzbox-lua-links-on-my-research-list/#more-43491


# work in progress, hopefully comes more;)

note: To prevent your access data from being accidentally uploaded, 
      use the following command on the command line:\
&nbsp;git update-index --assume-unchanged my.credentials