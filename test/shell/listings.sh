#!/bin/sh
# Copyright (C) 2008 Red Hat, Inc. All rights reserved.
#
# This copyrighted material is made available to anyone wishing to use,
# modify, copy, or redistribute it subject to the terms and conditions
# of the GNU General Public License v.2.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#
# tests functionality of lvs, pvs, vgs, *display tools
#

. lib/test

aux prepare_devs 5

pvcreate --uuid BADBEE-BAAD-BAAD-BAAD-BAAD-BAAD-BADBEE --norestorefile "$dev1"
pvcreate --metadatacopies 0 "$dev2"
pvcreate --metadatacopies 0 "$dev3"
pvcreate "$dev4"
pvcreate --metadatacopies 0 "$dev5"

#COMM bz195276 -- pvs doesn't show PVs until a VG is created
test $(pvs --noheadings $(cat DEVICES) | wc -l) -eq 5

#COMM pvs with segment attributes works even for orphans
test $(pvs --noheadings -o seg_all,pv_all,lv_all,vg_all $(cat DEVICES) | wc -l) -eq 5

vgcreate $vg $(cat DEVICES)

check pv_field "$dev1" pv_uuid BADBEE-BAAD-BAAD-BAAD-BAAD-BAAD-BADBEE

#COMM pvs and vgs report mda_count, mda_free (bz202886, bz247444)
pvs -o +pv_mda_count,pv_mda_free $(cat DEVICES)
for I in "$dev2" "$dev3" "$dev5"; do
	check pv_field $I pv_mda_count 0
	check pv_field $I pv_mda_free 0
done
vgs -o +vg_mda_count,vg_mda_free $vg
check vg_field $vg vg_mda_count 2

#COMM pvs doesn't display --metadatacopies 0 PVs as orphans (bz409061)
pvdisplay "$dev2"|grep "VG Name.*$vg"
check pv_field "$dev2" vg_name $vg

#COMM lvs displays snapshots (bz171215)
lvcreate -aey -l4 -n $lv1 $vg
lvcreate -l4 -s -n $lv2 $vg/$lv1
test $(lvs --noheadings $vg | wc -l) -eq 2
# should lvs -a display cow && real devices? (it doesn't)
test $(lvs -a --noheadings $vg | wc -l)  -eq 2
dmsetup ls | grep "$PREFIX" | grep -v "LVMTEST.*pv."
lvremove -f $vg/$lv2

#COMM lvs -a displays mirror legs and log
lvcreate -aey -l4 --type mirror -m2 -n $lv3 $vg
test $(lvs --noheadings $vg | wc -l) -eq 2
test $(lvs -a --noheadings $vg | wc -l) -eq 6
dmsetup ls|grep "$PREFIX"|grep -v "LVMTEST.*pv."

#COMM vgs with options from pvs still treats arguments as VGs (bz193543)
vgs -o pv_name,vg_name $vg
# would complain if not

#COMM pvdisplay --maps feature (bz149814)
pvdisplay $(cat DEVICES) >out
pvdisplay --maps $(cat DEVICES) >out2
not diff out out2

aux disable_dev "$dev1"
pvs -o +pv_uuid | grep BADBEE-BAAD-BAAD-BAAD-BAAD-BAAD-BADBEE
aux enable_dev "$dev1"

if aux have_readline; then
# test *scan and *display tools
cat <<EOF | lvm
vgdisplay --units k $vg
lvdisplay --units g $vg
pvdisplay -c "$dev1"
pvdisplay -s "$dev1"
vgdisplay -c $vg
vgdisplay -C $vg
vgdisplay -s $vg
lvdisplay -c $vg
lvdisplay -C $vg
lvdisplay -m $vg
EOF

for i in h b s k m g t p e H B S K M G T P E; do
	echo pvdisplay --units $i "$dev1"
done | lvm
else
pvscan --uuid
vgscan --mknodes
lvscan
lvmdiskscan
vgdisplay --units k $vg
lvdisplay --units g $vg
pvdisplay -c "$dev1"
pvdisplay -s "$dev1"
vgdisplay -c $vg
vgdisplay -C $vg
vgdisplay -s $vg
lvdisplay -c $vg
lvdisplay -C $vg
lvdisplay -m $vg

for i in h b s k m g t p e H B S K M G T P E; do
	pvdisplay --units $i "$dev1"
done
fi

invalid lvdisplay -C -m $vg
invalid lvdisplay -c -v $vg
invalid lvdisplay --aligned $vg
invalid lvdisplay --noheadings $vg
invalid lvdisplay --options lv_name $vg
invalid lvdisplay --separator : $vg
invalid lvdisplay --sort size $vg
invalid lvdisplay --unbuffered $vg


invalid vgdisplay -C -A
invalid vgdisplay -C -c
invalid vgdisplay -C -s
invalid vgdisplay -c -s
invalid vgdisplay -A $vg1

vgremove -ff $vg

#test vgdisplay -A to select only active VGs
# all LVs active - VG considered active
pvcreate "$dev1" "$dev2" "$dev3"

vgcreate $vg1 "$dev1"
lvcreate -l1 $vg1
lvcreate -l1 $vg1

# at least one LV active - VG considered active
vgcreate $vg2 "$dev2"
lvcreate -l1 $vg2
lvcreate -l1 -an -Zn $vg2

# no LVs active - VG considered inactive
vgcreate $vg3 "$dev3"
lvcreate -l1 -an -Zn $vg3
lvcreate -l1 -an -Zn $vg3

vgdisplay -s -A | grep $vg1
vgdisplay -s -A | grep $vg2
vgdisplay -s -A | not grep $vg3

vgremove -f $vg1 $vg2 $vg3
