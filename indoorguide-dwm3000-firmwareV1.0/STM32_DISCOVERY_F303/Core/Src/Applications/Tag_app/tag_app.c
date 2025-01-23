/*
 * tag_app.c
 *
 *  Created on: Dec 23, 2024
 *      Author: kavindu
 */
#include "../../Ranging/Tag/tag.h"
#include <stdio.h>

#define NUM_OF_ANCHORS 3

extern void test_run_info(unsigned char *data);

static double measurements[NUM_OF_ANCHORS];
char buffer[50];

void tag_app(uint8_t tagID)
{
	tag_init(tagID);

	uint8_t current_anchor = 1;

	while (1)
	{
		start_ss_ranging(current_anchor,measurements);
		current_anchor++;

		if (current_anchor > NUM_OF_ANCHORS)
		{
			current_anchor = 1;
			sprintf(buffer, "AN%d: %.2f  AN%d: %.2f  AN%d: %.2f", 1, measurements[0], 2, measurements[1], 3, measurements[2]);
			test_run_info((unsigned char*)buffer);
			HAL_Delay(2000);
		}

	}
}

