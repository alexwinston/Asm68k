# https://gist.github.com/FiloSottile/7125822
/usr/local/bin/nasm -f macho64 hello64.asm && ld -macosx_version_min 10.7.0 -lSystem -o hello64 hello64.o && ./hello64
