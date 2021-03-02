#!/usr/bin/env bash

yum install -y wget
yum install -y ncurses-devel

#mkdir fd_src
#cd fd_src
#wget http://hp.vector.co.jp/authors/VA012337/soft/fd/FD-3.01j.tar.gz
#tar -xvzf FD-3.01j.tar.gz
cd FD-3.01j
make
make install
