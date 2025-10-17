#!/bin/sh

verbose=false
if [ "x$1" = "x-v" ]; then
    verbose=true
    out=/dev/stdout
    err=/dev/stderr
else
    out=/dev/stdout
    err=/dev/stderr
fi

## make & makeopts
if gmake --version > /dev/null 2>&1; then
    make=gmake;
else
    make=make;
fi

makeopts="--quiet --no-print-directory -j"

make_print() {
    echo `$make $makeopts print-$1`
}

echo ">>>>>>>>>> here_make>>>>>>>>>>>"
echo `$make`
echo ">>>>>>>>>> here_make>>>>>>>>>>>"

## command tools
awk='awk'
bc='bc'
date='date'
grep='grep'
rm='rm -f'
sed='sed'

## symbol table
sym_table='obj/kernel.sym'

## gdb & gdbopts
gdb="$(make_print GDB)"
gdbport='1234'
gdb_in="$(make_print GRADE_GDB_IN)"

## qemu & qemuopts
qemu="$(make_print qemu)"
qemu_out="$(make_print GRADE_QEMU_OUT)"

if $qemu -nographic -help | grep -q '^-gdb'; then
    qemugdb="-gdb tcp::$gdbport"
else
    qemugdb="-s -p $gdbport"
fi

## default variables
default_timeout=30
default_pts=5
pts=5
part=0
part_pos=0
total=0
total_pos=0

## 通用函数
update_score() { total=`expr $total + $part`; total_pos=`expr $total_pos + $part_pos`; part=0; part_pos=0; }
get_time() { echo `$date +%s.%N 2> /dev/null`; }
show_part() { echo "Part $1 Score: $part/$part_pos"; echo; update_score; }
show_final() { update_score; echo "Total Score: $total/$total_pos"; if [ $total -lt $total_pos ]; then exit 1; fi; }
show_time() { t1=$(get_time); time=`echo "scale=1; ($t1-$t0)/1" | $sed 's/.N/.0/g' | $bc 2> /dev/null`; echo "(${time}s)"; }
show_build_tag() { echo "$1:" | $awk '{printf "%-24s ", $0}'; }
show_check_tag() { echo "$1:" | $awk '{printf "  -%-40s  ", $0}'; }
show_msg() { echo $1; shift; if [ $# -gt 0 ]; then echo -e "$@" | awk '{printf "   %s\n", $0}'; echo; fi; }
pass() { show_msg OK "$@"; part=`expr $part + $pts`; part_pos=`expr $part_pos + $pts`; }
fail() { show_msg WRONG "$@"; part_pos=`expr $part_pos + $pts`; }

run_qemu() {
    echo "try to run qemu"
    qemuextra=
    if [ "$brkfun" ]; then qemuextra="-S $qemugdb"; fi
    if [ -z "$timeout" ] || [ $timeout -le 0 ]; then timeout=$default_timeout; fi
    t0=$(get_time)
    (
        ulimit -t $timeout
        exec $qemu -nographic $qemuopts -serial file:$qemu_out -monitor null -no-reboot $qemuextra
    ) > $out 2> $err &
    pid=$!
    echo "qemu pid=$pid"
    sleep 1
    if [ -n "$brkfun" ]; then
        brkaddr=`$grep " $brkfun\$" $sym_table | $sed -e's/ .*$//g'`
        brkaddr_phys=`echo $brkaddr | sed "s/^c0/00/g"`
        (
            echo "target remote localhost:$gdbport"
            echo "break *0x$brkaddr"
            if [ "$brkaddr" != "$brkaddr_phys" ]; then echo "break *0x$brkaddr_phys"; fi
            echo "continue"
        ) > $gdb_in
        $gdb -batch -nx -x $gdb_in > /dev/null 2>&1
        kill $pid > /dev/null 2>&1
    fi
}

check_result() {
    show_check_tag "$1"
    shift
    if [ ! -s $qemu_out ]; then
        sleep 4
    fi
    if [ ! -s $qemu_out ]; then
        fail > /dev/null
        echo 'no $qemu_out'
    else
        check=$1
        shift
        $check "$@"
    fi
}

check_regexps() {
    okay=yes
    not=0
    reg=0
    error=
    for i do
        if [ "x$i" = "x!" ]; then
            not=1
        elif [ "x$i" = "x-" ]; then
            reg=1
        else
            if [ $reg -ne 0 ]; then
                $grep '-E' "^$i\$" $qemu_out > /dev/null
            else
                $grep '-F' "$i" $qemu_out > /dev/null
            fi
            found=$(($? == 0))
            if [ $found -eq $not ]; then
                if [ $found -eq 0 ]; then
                    msg="!! error: missing '$i'"
                else
                    msg="!! error: got unexpected line '$i'"
                fi
                okay=no
                if [ -z "$error" ]; then
                    error="$msg"
                else
                    error="$error\n$msg"
                fi
            fi
            not=0
            reg=0
        fi
    done
    if [ "$okay" = "yes" ]; then
        pass
    else
        fail "$error"
        if $verbose; then exit 1; fi
    fi
}

quick_check() {
    tag="$1"
    shift
    check_result "$tag" check_regexps "$@"
}

## kernel image
osimg=$(make_print ucoreimg)
swapimg=$(make_print swapimg)

## ✅ 修正版 QEMU 启动参数
qemuopts="-machine virt -nographic -bios default -kernel $osimg -m 128M"
brkfun=

## =============================== ##
##     测试执行部分放在最末尾      ##
## =============================== ##

echo "<<<<<<<<<<<<<<< here_run_qemu <<<<<<<<<<<<<<<<<<"
run_qemu
echo "<<<<<<<<<<<<<<< here_run_check <<<<<<<<<<<<<<<<<<"


pts=5
quick_check 'check physical_memory_map_information' \
    'memory management: best_fit_pmm_manager' \
    '  memory: 0x0000000008000000, [0x0000000080000000, 0x0000000087ffffff].'

pts=20
quick_check 'check_best_fit' \
    'check_alloc_page() succeeded!' \
    'satp virtual address: 0xffffffffc0204000' \
    'satp physical address: 0x0000000080204000'

show_final
