/*
 * Copyright (C) 2014 Red Hat, Inc. All rights reserved.
 *
 * This file is part of LVM2.
 *
 * This copyrighted material is made available to anyone wishing to use,
 * modify, copy, or redistribute it subject to the terms and conditions
 * of the GNU Lesser General Public License v.2.1.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef _LVM_PVMOVE_H
#define _LVM_PVMOVE_H

struct cmd_context;
struct volume_group;
struct logical_volume;
struct dm_list;

#define PVMOVE_FIRST_TIME   0x00000001      /* Called for first time */
#define PVMOVE_EXCLUSIVE    0x00000002      /* Require exclusive LV */

int pvmove_update_metadata(struct cmd_context *cmd, struct volume_group *vg,
		    struct logical_volume *lv_mirr,
		    struct dm_list *lvs_changed, unsigned flags);
int finish_pvmove(struct cmd_context *cmd, struct volume_group *vg,
			  struct logical_volume *lv_mirr,
			  struct dm_list *lvs_changed);

#endif  /* _LVM_PVMOVE_H */