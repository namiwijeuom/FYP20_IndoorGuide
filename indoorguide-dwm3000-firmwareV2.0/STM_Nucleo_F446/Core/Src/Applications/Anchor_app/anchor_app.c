/*
 * anchor_app.c
 *
 *  Created on: Dec 23, 2024
 *      Author: kavindu
 */
#include "../../Ranging/Anchor/anchor.h"

void anchor_app(uint8_t anchorID)
{
	anchor_init(anchorID);

	while(1)
	{
		start_ss_ranging_responder();
	}
}


