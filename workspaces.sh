#!/bin/bash

declare -A ws=()

ws[1]="\"1: root\""
ws[2]="\"2: net\""
ws[3]="\"3: Media\""
ws[4]="\"4: Files\""
ws[5]="\"5: Work\""
ws[6]="\"6: Docs\""
ws[7]="\"7\""
ws[8]="\"8\""
ws[9]="\"9\""
ws[10]="\"10\""
ws[11]="\"11\""
ws[12]="\"12\""

echo ${ws[$1]}

