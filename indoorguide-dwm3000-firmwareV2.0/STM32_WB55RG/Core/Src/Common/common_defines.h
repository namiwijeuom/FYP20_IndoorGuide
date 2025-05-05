/*
 * common.h
 *
 *  Created on: Feb 1, 2025
 *      Author: Kavindu
 */

#ifndef COMMON_DEFINES_H
#define COMMON_DEFINES_H

#include <stdint.h>

/* MACRO DEFINITIONS */

/* Merge 2 bytes LSB and MSB to get uint16_t */
#define GET_UINT16(lsb, msb) ((uint16_t)(lsb) | ((uint16_t)(msb) << 8))

#define LSB(x)   ((uint8_t)((x) & 0xFF))
#define MSB(x)   ((uint8_t)(((x) >> 8) & 0xFF))




/* Length of short address and Long address types in bytes */
#define ADDR_SHORT_BYTES 2
#define ADDR_LONG_BYTES  8

/* Cordinates are represented in centimeters - uint16_t - 2 Bytes */
#define CORD_BYTES_LEN 2



typedef struct{
	uint8_t short_addr[ADDR_SHORT_BYTES];
	uint8_t current_tag_addr[ADDR_SHORT_BYTES];
	uint16_t loc_x;
	uint16_t loc_y;
	uint16_t loc_z;


}__attribute__((packed))
anchorinfo_t;



typedef struct{
	uint8_t short_addr[ADDR_SHORT_BYTES];  /* 0-LSB  1-MSB */
	uint16_t loc_x;
	uint16_t loc_y;
	anchorinfo_t current_anchor;
	uint16_t distance;

}__attribute__((packed))
taginfo_t;



typedef struct
{
	uint16_t fetched_addr[7];     // This was 4
	uint8_t  fetched_count;

}__attribute__((packed))
fetchedanchor_t;




#endif /* COMMON_DEFINES_H */
