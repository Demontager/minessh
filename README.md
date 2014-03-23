minessh
=======

Controls mining servers over SSH

****************************Overview**********************************************************************************
Bash script for controlling mining servers running on BAMT 1.3/1.6 or SMOS Linux It could control any number of mining servers. It is preferably to run it against BAMT 1.6 servers as i already included easy function to quiclly switch over mining software e.g. cgminer/sgminer/vertminer. Also it is possible to add your own custom compiled miner and switch to it within menu. Tested on Lubuntu 13.10 and any Debian based distros works out of box, also it could run on any Linux distro whith small modifications.
**********************************************************************************************************************

List of features:

-Power of secured SSH connection (use only SSH)

-Fully interactive menu

-Unlimited number of mining servers

-Automatically adds non-password authentication

-Custom colors for menus and messages

-Reboot selected miner or all together

-View pool config of selected miner

-Switch over between 4 included mining software in BAMT 1.6 + 2 custom

-Real-time monitoring for all servers in one window

-Cron task to periodically control and reboot dead/sick/idle mining servers



Initial setup


1. Download script to any folder
2. Make script executable chmod +x mine.sh
3. Edit mining servers IP in script body. Also configure pools
4. Launch script ./mine.sh
5. Set up non-password authentication. Press 7 and procceed to further instructions.
6. All done. You may back to menu and choose desired option.
7. (Optional) If you would like to setup cron job then you need to run script with cron parameter. For example to test mining servers every 20 minutes add line to crontab. */20 * * * * /mine.sh cron



Please let me know if you found any bugs or want to suggest something.

Screenshots

Main menu: http://simplest-image-hosting.net/png-0-menu3
Mining servers' status:  http://simplest-image-hosting.net/png-0-status0
Switch over between mining software:  http://simplest-image-hosting.net/png-0-mining-soft
Real-time moniroing:  http://simplest-image-hosting.net/png-0-real-time

