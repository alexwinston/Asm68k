# cat > tty1, cat tty2
./m68ksim -I tty 0xFFE000 tty1 tty2 -l hello
