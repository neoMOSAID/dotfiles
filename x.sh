#!/bin/bash
echo x
case $BLOCK_BUTTON in
	"3") i3-msg 'kill' ;;
esac

