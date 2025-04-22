/*
 * anchor_app.h
 *
 *  Created on: Feb 2, 2025
 *      Author: User
 */

#ifndef ANCHOR_APP_H
#define ANCHOR_APP_H

#include <stdint.h>

#include "../../UWB_tasks/Listener/listener.h"
#include "../../UWB_tasks/ss_twr_resp/ss_twr_resp.h"

#include "../../Common/common_defines.h"





void anchor_application_init(uint16_t anchorAddr, uint16_t *coordinates);

void anchor_application(uint16_t anchorAddr, uint16_t *coordinates);



#endif /* ANCHOR_APP */
